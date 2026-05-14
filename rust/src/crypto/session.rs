use anyhow::Result;
use std::collections::HashMap;
use x25519_dalek::{PublicKey as X25519PublicKey, StaticSecret};

use super::double_ratchet::{
    deserialize_ratchet_message, ratchet_decrypt, ratchet_encrypt, serialize_ratchet_message,
    CipherSuite, RatchetState,
};
use super::x3dh::{x3dh_recv, x3dh_send, X3DHKeyBundle};

pub struct E2EESessionManager {
    identity_key: StaticSecret,
    identity_public: X25519PublicKey,
    key_bundle: X3DHKeyBundle,
    sessions: HashMap<String, RatchetState>,
    pending_pre_keys: HashMap<u32, StaticSecret>,
    cipher_suite: CipherSuite,
}

pub struct SessionInitiation {
    pub ephemeral_public: X25519PublicKey,
    pub one_time_pre_key_id: Option<u32>,
}

pub struct SessionMessage {
    pub ciphertext: Vec<u8>,
    pub message_id: String,
}

impl E2EESessionManager {
    pub fn new(seed: &[u8; 32]) -> Self {
        let identity_key = StaticSecret::from(*seed);
        let identity_public = X25519PublicKey::from(&identity_key);
        let key_bundle = X3DHKeyBundle::generate(&identity_key, &identity_public);

        let mut pending_pre_keys = HashMap::new();
        for (id, sk, _) in &key_bundle.one_time_pre_keys {
            pending_pre_keys.insert(*id, sk.clone());
        }

        Self {
            identity_key,
            identity_public,
            key_bundle,
            sessions: HashMap::new(),
            pending_pre_keys,
            cipher_suite: CipherSuite::default(),
        }
    }

    pub fn with_cipher_suite(mut self, cipher_suite: CipherSuite) -> Self {
        self.cipher_suite = cipher_suite;
        self
    }

    pub fn initiate_session(
        &mut self,
        peer_id: &str,
        peer_ik_pub: &X25519PublicKey,
        peer_spk_pub: &X25519PublicKey,
        peer_opk_pub: Option<&X25519PublicKey>,
    ) -> Result<(SessionInitiation, [u8; 32])> {
        let ek = x25519_dalek::EphemeralSecret::random();
        let ek_pub = X25519PublicKey::from(&ek);

        let result = x3dh_send(
            &self.identity_key,
            &ek,
            peer_ik_pub,
            peer_spk_pub,
            peer_opk_pub,
        )?;

        let bob_dh = StaticSecret::random();
        let bob_dh_pub = X25519PublicKey::from(&bob_dh);
        let state = RatchetState::alice_initial(
            result.shared_secret,
            bob_dh_pub,
            self.cipher_suite.clone(),
        );

        self.sessions.insert(peer_id.to_string(), state);

        Ok((
            SessionInitiation {
                ephemeral_public: ek_pub,
                one_time_pre_key_id: None,
            },
            result.shared_secret,
        ))
    }

    pub fn accept_session(
        &mut self,
        peer_id: &str,
        init: &SessionInitiation,
        peer_ik_pub: &X25519PublicKey,
    ) -> Result<[u8; 32]> {
        let opk = init
            .one_time_pre_key_id
            .and_then(|id| self.pending_pre_keys.remove(&id));

        let result = x3dh_recv(
            &self.identity_key,
            &self.key_bundle.signed_pre_key,
            peer_ik_pub,
            &init.ephemeral_public,
            opk.as_ref(),
        )?;

        let bob_dh = StaticSecret::random();
        let state = RatchetState::bob_initial(
            result.shared_secret,
            bob_dh,
            init.ephemeral_public,
            self.cipher_suite.clone(),
        );

        self.sessions.insert(peer_id.to_string(), state);

        Ok(result.shared_secret)
    }

    pub fn encrypt_message(&mut self, peer_id: &str, plaintext: &[u8]) -> Result<SessionMessage> {
        let state = self
            .sessions
            .get_mut(peer_id)
            .ok_or_else(|| anyhow::anyhow!("no session for peer: {}", peer_id))?;

        let msg = ratchet_encrypt(state, plaintext);
        let serialized = serialize_ratchet_message(&msg);

        let message_id = format!(
            "{:x}",
            sha2::Sha256::digest(&serialized)
                .iter()
                .take(8)
                .fold(0u64, |acc, &b| (acc << 8) | b as u64)
        );

        Ok(SessionMessage {
            ciphertext: serialized,
            message_id,
        })
    }

    pub fn decrypt_message(&mut self, peer_id: &str, data: &[u8]) -> Result<Vec<u8>> {
        let state = self
            .sessions
            .get_mut(peer_id)
            .ok_or_else(|| anyhow::anyhow!("no session for peer: {}", peer_id))?;

        let msg = super::double_ratchet::deserialize_ratchet_message(data)
            .ok_or_else(|| anyhow::anyhow!("invalid message format"))?;

        ratchet_decrypt(state, &msg)
            .ok_or_else(|| anyhow::anyhow!("decryption failed"))
    }

    pub fn identity_public(&self) -> &X25519PublicKey {
        &self.identity_public
    }

    pub fn bundle_signed_pre_key(&self) -> &X25519PublicKey {
        &self.key_bundle.signed_pre_key_public
    }

    pub fn bundle_one_time_key(&self) -> Option<(u32, &X25519PublicKey)> {
        self.key_bundle.get_one_time_key()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_full_e2ee_session() {
        let seed_a = [0xAAu8; 32];
        let seed_b = [0xBBu8; 32];

        let mut alice = E2EESessionManager::new(&seed_a);
        let mut bob = E2EESessionManager::new(&seed_b);

        let bob_ik = *bob.identity_public();
        let bob_spk = *bob.bundle_signed_pre_key();
        let bob_opk = bob.bundle_one_time_key();

        let (init, _) = alice
            .initiate_session("bob", &bob_ik, &bob_spk, bob_opk.map(|(_, pk)| pk))
            .unwrap();

        let alice_ik = *alice.identity_public();
        bob.accept_session("alice", &init, &alice_ik).unwrap();

        let msg = alice.encrypt_message("bob", b"Hello from Alice!").unwrap();
        let decrypted = bob.decrypt_message("alice", &msg.ciphertext).unwrap();
        assert_eq!(b"Hello from Alice!", decrypted.as_slice());

        let reply = bob.encrypt_message("alice", b"Hey Alice, got it!").unwrap();
        let decrypted_reply = alice.decrypt_message("bob", &reply.ciphertext).unwrap();
        assert_eq!(b"Hey Alice, got it!", decrypted_reply.as_slice());

        for i in 0..20 {
            let text = format!("msg {}", i);
            let m = alice.encrypt_message("bob", text.as_bytes()).unwrap();
            let d = bob.decrypt_message("alice", &m.ciphertext).unwrap();
            assert_eq!(text.as_bytes(), d.as_slice());
        }
    }
}