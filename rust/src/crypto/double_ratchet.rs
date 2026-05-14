use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Nonce as AesNonce,
};
use chacha20poly1305::{
    aead::{Aead as ChaChaAead, KeyInit as ChaChaKeyInit},
    ChaCha20Poly1305, Nonce as ChaChaNonce,
};
use hkdf::Hkdf;
use serde::{Deserialize, Serialize};
use sha2::Sha256;
use x25519_dalek::{PublicKey as X25519PublicKey, StaticSecret};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RootKey {
    pub key: [u8; 32],
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SendingChainKey {
    pub key: [u8; 32],
    pub index: u32,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReceivingChainKey {
    pub key: [u8; 32],
    pub index: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageKey {
    pub key: [u8; 32],
    pub nonce: [u8; 12],
    pub message_number: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CipherSuite {
    Aes256Gcm,
    ChaCha20Poly1305,
}

impl Default for CipherSuite {
    fn default() -> Self {
        CipherSuite::Aes256Gcm
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RatchetHeader {
    pub dh_pub: [u8; 32],
    pub previous_chain_length: u32,
    pub message_number: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RatchetMessage {
    pub header: RatchetHeader,
    pub ciphertext: Vec<u8>,
    pub cipher_suite: CipherSuite,
}

#[derive(Debug, Clone)]
pub struct RatchetState {
    pub dh_pair: (StaticSecret, X25519PublicKey),
    pub root_key: RootKey,
    pub send_chain_key: Option<SendingChainKey>,
    pub recv_chain_key: Option<ReceivingChainKey>,
    pub send_message_number: u32,
    pub recv_message_number: u32,
    pub previous_send_chain_length: u32,
    pub remote_dh_public: Option<X25519PublicKey>,
    pub cipher_suite: CipherSuite,
    pub skipped_message_keys: std::collections::HashMap<(X25519PublicKey, u32), MessageKey>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RatchetStateSnapshot {
    pub root_key: [u8; 32],
    pub dh_public: [u8; 32],
    pub dh_secret: [u8; 32],
    pub send_chain_key: Option<[u8; 32]>,
    pub recv_chain_key: Option<[u8; 32]>,
    pub send_message_number: u32,
    pub recv_message_number: u32,
    pub previous_send_chain_length: u32,
    pub remote_dh_public: Option<[u8; 32]>,
    pub cipher_suite: CipherSuite,
}

impl RatchetState {
    pub fn snapshot(&self) -> RatchetStateSnapshot {
        RatchetStateSnapshot {
            root_key: self.root_key.key,
            dh_public: *self.dh_pair.1.as_bytes(),
            dh_secret: self.dh_pair.0.to_bytes(),
            send_chain_key: self.send_chain_key.as_ref().map(|k| k.key),
            recv_chain_key: self.recv_chain_key.as_ref().map(|k| k.key),
            send_message_number: self.send_message_number,
            recv_message_number: self.recv_message_number,
            previous_send_chain_length: self.previous_send_chain_length,
            remote_dh_public: self.remote_dh_public.map(|k| *k.as_bytes()),
            cipher_suite: self.cipher_suite.clone(),
        }
    }
}

impl RatchetState {
    pub fn alice_initial(
        shared_secret: [u8; 32],
        bob_dh_pub: X25519PublicKey,
        cipher_suite: CipherSuite,
    ) -> Self {
        let dh_secret = StaticSecret::random();
        let our_dh_pub = X25519PublicKey::from(&dh_secret);

        let dh_output = dh_secret.diffie_hellman(&bob_dh_pub);
        let root_key = kdf_rk(&RootKey { key: shared_secret }, dh_output.as_bytes());

        Self {
            dh_pair: (dh_secret, our_dh_pub),
            root_key,
            send_chain_key: None,
            recv_chain_key: None,
            send_message_number: 0,
            recv_message_number: 0,
            previous_send_chain_length: 0,
            remote_dh_public: Some(bob_dh_pub),
            cipher_suite,
            skipped_message_keys: std::collections::HashMap::new(),
        }
    }

    pub fn bob_initial(
        shared_secret: [u8; 32],
        bob_dh: StaticSecret,
        alice_dh_pub: X25519PublicKey,
        cipher_suite: CipherSuite,
    ) -> Self {
        let bob_dh_pub = X25519PublicKey::from(&bob_dh);

        let dh_output = bob_dh.diffie_hellman(&alice_dh_pub);
        let root_key = kdf_rk(&RootKey { key: shared_secret }, dh_output.as_bytes());

        Self {
            dh_pair: (bob_dh, bob_dh_pub),
            root_key,
            send_chain_key: None,
            recv_chain_key: None,
            send_message_number: 0,
            recv_message_number: 0,
            previous_send_chain_length: 0,
            remote_dh_public: Some(alice_dh_pub),
            cipher_suite,
            skipped_message_keys: std::collections::HashMap::new(),
        }
    }
}

pub fn ratchet_encrypt(state: &mut RatchetState, plaintext: &[u8]) -> RatchetMessage {
    if state.send_chain_key.is_none() || state.send_message_number >= 100 {
        dh_ratchet_send(state);
    }

    let chain_key = state.send_chain_key.as_ref().unwrap();
    let (msg_key, new_chain_key) = kdf_ck(&chain_key.key);

    state.send_chain_key = Some(SendingChainKey {
        key: new_chain_key,
        index: state.send_message_number + 1,
    });

    let message_number = state.send_message_number;
    state.send_message_number += 1;

    let ciphertext = match &state.cipher_suite {
        CipherSuite::Aes256Gcm => {
            let nonce = AesNonce::from_slice(&msg_key.nonce);
            let cipher = Aes256Gcm::new_from_slice(&msg_key.key).expect("valid key");
            cipher
                .encrypt(nonce, plaintext)
                .expect("encryption succeeded")
        }
        CipherSuite::ChaCha20Poly1305 => {
            let nonce = ChaChaNonce::from_slice(&msg_key.nonce);
            let cipher = ChaCha20Poly1305::new_from_slice(&msg_key.key).expect("valid key");
            cipher
                .encrypt(nonce, plaintext)
                .expect("encryption succeeded")
        }
    };

    let header = RatchetHeader {
        dh_pub: *state.dh_pair.1.as_bytes(),
        previous_chain_length: state.previous_send_chain_length,
        message_number,
    };

    RatchetMessage {
        header,
        ciphertext,
        cipher_suite: state.cipher_suite.clone(),
    }
}

pub fn ratchet_decrypt(state: &mut RatchetState, message: &RatchetMessage) -> Option<Vec<u8>> {
    let msg_dh_pub = X25519PublicKey::from(message.header.dh_pub);

    if let Some(remote_dh) = &state.remote_dh_public {
        if msg_dh_pub != *remote_dh {
            dh_ratchet_recv(state, &message.header);
        }
    } else {
        dh_ratchet_recv(state, &message.header);
    }

    if state.recv_chain_key.is_none() {
        return None;
    }

    if state.recv_message_number > message.header.message_number {
        return try_skipped_message_keys(state, &message.header, &message.ciphertext, &message.cipher_suite);
    }

    while state.recv_message_number < message.header.message_number {
        let chain_key = state.recv_chain_key.as_ref().unwrap();
        let (_, new_ck) = kdf_ck(&chain_key.key);
        state.recv_chain_key = Some(ReceivingChainKey {
            key: new_ck,
            index: state.recv_message_number,
        });
        state.recv_message_number += 1;
    }

    let chain_key = state.recv_chain_key.as_ref().unwrap();
    let (msg_key, new_ck) = kdf_ck(&chain_key.key);
    state.recv_chain_key = Some(ReceivingChainKey {
        key: new_ck,
        index: state.recv_message_number,
    });
    state.recv_message_number += 1;

    decrypt_with_key(&msg_key, &message.ciphertext, &message.cipher_suite)
}

fn dh_ratchet_send(state: &mut RatchetState) {
    state.previous_send_chain_length = state.send_message_number;
    state.send_message_number = 0;

    let new_dh = StaticSecret::random();
    let new_dh_pub = X25519PublicKey::from(&new_dh);

    if let Some(remote_pub) = &state.remote_dh_public {
        let dh_output = new_dh.diffie_hellman(remote_pub);
        state.root_key = kdf_rk(&state.root_key, dh_output.as_bytes());
    }

    let (send_key, _recv_key) = derive_initial_chain_keys(&state.root_key.key);
    state.send_chain_key = Some(SendingChainKey { key: send_key, index: 0 });

    state.dh_pair = (new_dh, new_dh_pub);
}

fn dh_ratchet_recv(state: &mut RatchetState, header: &RatchetHeader) {
    state.previous_send_chain_length = 0;
    state.send_message_number = 0;
    state.recv_message_number = 0;

    let their_dh_pub = X25519PublicKey::from(header.dh_pub);

    let dh1 = state.dh_pair.0.diffie_hellman(&their_dh_pub);
    state.root_key = kdf_rk(&state.root_key, dh1.as_bytes());

    let new_dh = StaticSecret::random();
    let new_dh_pub = X25519PublicKey::from(&new_dh);

    let dh2 = new_dh.diffie_hellman(&their_dh_pub);
    state.root_key = kdf_rk(&state.root_key, dh2.as_bytes());

    let (send_key, recv_key) = derive_initial_chain_keys(&state.root_key.key);
    state.send_chain_key = Some(SendingChainKey { key: send_key, index: 0 });
    state.recv_chain_key = Some(ReceivingChainKey { key: recv_key, index: 0 });

    state.dh_pair = (new_dh, new_dh_pub);
    state.remote_dh_public = Some(their_dh_pub);
}

fn kdf_rk(rk: &RootKey, dh_output: &[u8; 32]) -> RootKey {
    let hkdf = Hkdf::<Sha256>::new(Some(&rk.key), dh_output);
    let mut okm = [0u8; 32];
    hkdf
        .expand(b"zero-ratchet-root-v1", &mut okm)
        .expect("hkdf expand");
    RootKey { key: okm }
}

fn kdf_ck(ck: &[u8; 32]) -> (MessageKey, [u8; 32]) {
    let hkdf = Hkdf::<Sha256>::new(None, ck);
    let mut okm = [0u8; 80];
    hkdf
        .expand(b"zero-chain-key-v1", &mut okm)
        .expect("hkdf expand");

    let mut mk_bytes = [0u8; 32];
    let mut nonce_bytes = [0u8; 12];
    let mut new_ck = [0u8; 32];

    mk_bytes.copy_from_slice(&okm[..32]);
    nonce_bytes.copy_from_slice(&okm[32..44]);
    new_ck.copy_from_slice(&okm[44..76]);

    (
        MessageKey {
            key: mk_bytes,
            nonce: nonce_bytes,
            message_number: 0,
        },
        new_ck,
    )
}

fn derive_initial_chain_keys(root_key: &[u8; 32]) -> ([u8; 32], [u8; 32]) {
    let hkdf = Hkdf::<Sha256>::new(None, root_key);
    let mut okm = [0u8; 64];
    hkdf
        .expand(b"zero-initial-chain-v1", &mut okm)
        .expect("hkdf expand");

    let mut send_key = [0u8; 32];
    let mut recv_key = [0u8; 32];
    send_key.copy_from_slice(&okm[..32]);
    recv_key.copy_from_slice(&okm[32..]);
    (send_key, recv_key)
}

fn decrypt_with_key(
    msg_key: &MessageKey,
    ciphertext: &[u8],
    cipher_suite: &CipherSuite,
) -> Option<Vec<u8>> {
    match cipher_suite {
        CipherSuite::Aes256Gcm => {
            let nonce = AesNonce::from_slice(&msg_key.nonce);
            let cipher = Aes256Gcm::new_from_slice(&msg_key.key).expect("valid key");
            cipher.decrypt(nonce, ciphertext).ok()
        }
        CipherSuite::ChaCha20Poly1305 => {
            let nonce = ChaChaNonce::from_slice(&msg_key.nonce);
            let cipher = ChaCha20Poly1305::new_from_slice(&msg_key.key).expect("valid key");
            cipher.decrypt(nonce, ciphertext).ok()
        }
    }
}

fn try_skipped_message_keys(
    state: &mut RatchetState,
    header: &RatchetHeader,
    ciphertext: &[u8],
    cipher_suite: &CipherSuite,
) -> Option<Vec<u8>> {
    let dh_pub = X25519PublicKey::from(header.dh_pub);
    let key_ref = (dh_pub, header.message_number);
    if let Some(msg_key) = state.skipped_message_keys.remove(&key_ref) {
        return decrypt_with_key(&msg_key, ciphertext, cipher_suite);
    }

    let start = state.recv_message_number;
    while state.recv_message_number < header.message_number {
        let chain_key = state.recv_chain_key.as_ref().unwrap();
        let (mk, new_ck) = kdf_ck(&chain_key.key);

        let pk = state.remote_dh_public.unwrap();
        let mut mk_stored = mk.clone();
        mk_stored.message_number = state.recv_message_number;
        state
            .skipped_message_keys
            .insert((pk, state.recv_message_number), mk_stored);

        state.recv_chain_key = Some(ReceivingChainKey {
            key: new_ck,
            index: state.recv_message_number,
        });
        state.recv_message_number += 1;
    }

    let chain_key = state.recv_chain_key.as_ref().unwrap();
    let (msg_key, new_ck) = kdf_ck(&chain_key.key);
    state.recv_chain_key = Some(ReceivingChainKey {
        key: new_ck,
        index: state.recv_message_number,
    });
    state.recv_message_number += 1;

    decrypt_with_key(&msg_key, ciphertext, cipher_suite)
}

pub fn serialize_ratchet_message(msg: &RatchetMessage) -> Vec<u8> {
    let mut data = Vec::new();

    data.extend_from_slice(&msg.header.dh_pub);
    data.extend_from_slice(&msg.header.previous_chain_length.to_be_bytes());
    data.extend_from_slice(&msg.header.message_number.to_be_bytes());

    let suite_byte: u8 = match msg.cipher_suite {
        CipherSuite::Aes256Gcm => 0x00,
        CipherSuite::ChaCha20Poly1305 => 0x01,
    };
    data.push(suite_byte);

    let ciphertext_len = msg.ciphertext.len() as u32;
    data.extend_from_slice(&ciphertext_len.to_be_bytes());
    data.extend_from_slice(&msg.ciphertext);

    data
}

pub fn deserialize_ratchet_message(data: &[u8]) -> Option<RatchetMessage> {
    if data.len() < 41 {
        return None;
    }

    let dh_pub: [u8; 32] = data[..32].try_into().ok()?;

    let pn = u32::from_be_bytes(data[32..36].try_into().ok()?);
    let n = u32::from_be_bytes(data[36..40].try_into().ok()?);

    let cipher_suite = match data[40] {
        0x00 => CipherSuite::Aes256Gcm,
        0x01 => CipherSuite::ChaCha20Poly1305,
        _ => return None,
    };

    let ciphertext_len = u32::from_be_bytes(data[41..45].try_into().ok()?) as usize;
    if data.len() < 45 + ciphertext_len {
        return None;
    }

    let ciphertext = data[45..45 + ciphertext_len].to_vec();

    Some(RatchetMessage {
        header: RatchetHeader {
            dh_pub,
            previous_chain_length: pn,
            message_number: n,
        },
        ciphertext,
        cipher_suite,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_shared_secret() -> [u8; 32] {
        let mut s = [0u8; 32];
        s[0] = 0x42;
        s
    }

    #[test]
    fn test_double_ratchet_full_cycle() {
        let shared_secret = create_test_shared_secret();

        let bob_dh = StaticSecret::random();
        let bob_dh_pub = X25519PublicKey::from(&bob_dh);

        let mut alice =
            RatchetState::alice_initial(shared_secret, bob_dh_pub, CipherSuite::Aes256Gcm);
        let mut bob = RatchetState::bob_initial(
            shared_secret,
            bob_dh,
            *alice.dh_pair.1.as_bytes().into(),
            CipherSuite::Aes256Gcm,
        );

        for i in 0..5 {
            let plaintext = format!("message {}", i);
            let msg = ratchet_encrypt(&mut alice, plaintext.as_bytes());
            assert_eq!(msg.cipher_suite, CipherSuite::Aes256Gcm);
            let decrypted = ratchet_decrypt(&mut bob, &msg).unwrap();
            assert_eq!(plaintext.as_bytes(), &decrypted);
        }

        for i in 5..10 {
            let plaintext = format!("reply {}", i);
            let msg = ratchet_encrypt(&mut bob, plaintext.as_bytes());
            let decrypted = ratchet_decrypt(&mut alice, &msg).unwrap();
            assert_eq!(plaintext.as_bytes(), &decrypted);
        }
    }

    #[test]
    fn test_double_ratchet_with_chacha() {
        let shared_secret = create_test_shared_secret();

        let bob_dh = StaticSecret::random();
        let bob_dh_pub = X25519PublicKey::from(&bob_dh);

        let mut alice = RatchetState::alice_initial(
            shared_secret,
            bob_dh_pub,
            CipherSuite::ChaCha20Poly1305,
        );
        let mut bob = RatchetState::bob_initial(
            shared_secret,
            bob_dh,
            *alice.dh_pair.1.as_bytes().into(),
            CipherSuite::ChaCha20Poly1305,
        );

        let plaintext = b"chacha test message";
        let msg = ratchet_encrypt(&mut alice, plaintext);
        assert_eq!(msg.cipher_suite, CipherSuite::ChaCha20Poly1305);
        let decrypted = ratchet_decrypt(&mut bob, &msg).unwrap();
        assert_eq!(plaintext.to_vec(), decrypted);
    }

    #[test]
    fn test_serialization_roundtrip() {
        let shared_secret = create_test_shared_secret();
        let bob_dh = StaticSecret::random();
        let bob_dh_pub = X25519PublicKey::from(&bob_dh);

        let mut alice =
            RatchetState::alice_initial(shared_secret, bob_dh_pub, CipherSuite::Aes256Gcm);
        let msg = ratchet_encrypt(&mut alice, b"serializable");

        let serialized = serialize_ratchet_message(&msg);
        let deserialized = deserialize_ratchet_message(&serialized).unwrap();

        assert_eq!(msg.header.dh_pub, deserialized.header.dh_pub);
        assert_eq!(
            msg.header.previous_chain_length,
            deserialized.header.previous_chain_length
        );
        assert_eq!(msg.header.message_number, deserialized.header.message_number);
        assert_eq!(msg.ciphertext, deserialized.ciphertext);
        assert_eq!(msg.cipher_suite, deserialized.cipher_suite);
    }

    #[test]
    fn test_ratchet_state_snapshot() {
        let shared_secret = create_test_shared_secret();
        let bob_dh = StaticSecret::random();
        let bob_dh_pub = X25519PublicKey::from(&bob_dh);

        let alice = RatchetState::alice_initial(shared_secret, bob_dh_pub, CipherSuite::Aes256Gcm);
        let snapshot = alice.snapshot();

        assert_eq!(snapshot.root_key, alice.root_key.key);
        assert_eq!(snapshot.dh_public, *alice.dh_pair.1.as_bytes());
        assert_eq!(snapshot.send_message_number, alice.send_message_number);
        assert_eq!(snapshot.cipher_suite, alice.cipher_suite);
    }

    #[test]
    fn test_out_of_order_messages() {
        let shared_secret = create_test_shared_secret();

        let bob_dh = StaticSecret::random();
        let bob_dh_pub = X25519PublicKey::from(&bob_dh);

        let mut alice =
            RatchetState::alice_initial(shared_secret, bob_dh_pub, CipherSuite::Aes256Gcm);
        let mut bob = RatchetState::bob_initial(
            shared_secret,
            bob_dh,
            *alice.dh_pair.1.as_bytes().into(),
            CipherSuite::Aes256Gcm,
        );

        let msgs: Vec<_> = (0..5)
            .map(|i| ratchet_encrypt(&mut alice, format!("msg{}", i).as_bytes()))
            .collect();

        for msg in msgs.iter().rev() {
            let decrypted = ratchet_decrypt(&mut bob, msg).unwrap();
            assert!(!decrypted.is_empty());
        }
    }
}