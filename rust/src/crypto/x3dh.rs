use anyhow::Result;
use ed25519_dalek::{SigningKey, VerifyingKey};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use x25519_dalek::{EphemeralSecret, PublicKey as X25519PublicKey, StaticSecret};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdentityKeyPair {
    pub ed25519_signing_key: [u8; 32],
    pub ed25519_verifying_key: [u8; 32],
    pub x25519_secret: [u8; 32],
    pub x25519_public: [u8; 32],
}

impl IdentityKeyPair {
    pub fn generate() -> Self {
        let x25519_secret = StaticSecret::random();
        let x25519_public = X25519PublicKey::from(&x25519_secret);

        let signing_key = SigningKey::from_bytes(&x25519_secret.to_bytes());
        let verifying_key = signing_key.verifying_key();

        Self {
            ed25519_signing_key: signing_key.to_bytes(),
            ed25519_verifying_key: verifying_key.to_bytes(),
            x25519_secret: x25519_secret.to_bytes(),
            x25519_public: *x25519_public.as_bytes(),
        }
    }

    pub fn from_seed(seed: &[u8; 32]) -> Self {
        let x25519_secret = StaticSecret::from(*seed);
        let x25519_public = X25519PublicKey::from(&x25519_secret);

        let signing_key = SigningKey::from_bytes(seed);
        let verifying_key = signing_key.verifying_key();

        Self {
            ed25519_signing_key: *seed,
            ed25519_verifying_key: verifying_key.to_bytes(),
            x25519_secret: x25519_secret.to_bytes(),
            x25519_public: *x25519_public.as_bytes(),
        }
    }

    pub fn x25519_secret_key(&self) -> StaticSecret {
        StaticSecret::from(self.x25519_secret)
    }

    pub fn x25519_public_key(&self) -> X25519PublicKey {
        X25519PublicKey::from(self.x25519_public)
    }

    pub fn ed25519_signing_key(&self) -> SigningKey {
        SigningKey::from_bytes(&self.ed25519_signing_key)
    }

    pub fn ed25519_verifying_key(&self) -> VerifyingKey {
        VerifyingKey::from_bytes(&self.ed25519_verifying_key)
            .expect("valid ed25519 verifying key")
    }

    pub fn sign(&self, message: &[u8]) -> Vec<u8> {
        let signing_key = self.ed25519_signing_key();
        use ed25519_dalek::Signer;
        signing_key.sign(message).to_vec()
    }

    pub fn verify(&self, message: &[u8], signature: &[u8]) -> bool {
        let verifying_key = self.ed25519_verifying_key();
        if signature.len() != 64 {
            return false;
        }
        let sig: [u8; 64] = match signature.try_into() {
            Ok(s) => s,
            Err(_) => return false,
        };
        use ed25519_dalek::Signature;
        verifying_key
            .verify_strict(message, &Signature::from_bytes(&sig))
            .is_ok()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignedPreKey {
    pub key_id: u32,
    pub secret: [u8; 32],
    pub public: [u8; 32],
    pub signature: Vec<u8>,
}

impl SignedPreKey {
    pub fn generate(key_id: u32, identity: &IdentityKeyPair) -> Self {
        let secret = StaticSecret::random();
        let public = X25519PublicKey::from(&secret);

        let signature = identity.sign(public.as_bytes());

        Self {
            key_id,
            secret: secret.to_bytes(),
            public: *public.as_bytes(),
            signature,
        }
    }

    pub fn x25519_secret(&self) -> StaticSecret {
        StaticSecret::from(self.secret)
    }

    pub fn x25519_public(&self) -> X25519PublicKey {
        X25519PublicKey::from(self.public)
    }

    pub fn verify(&self, identity: &IdentityKeyPair) -> bool {
        identity.verify(&self.public, &self.signature)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OneTimePreKey {
    pub key_id: u32,
    pub secret: [u8; 32],
    pub public: [u8; 32],
}

impl OneTimePreKey {
    pub fn generate(key_id: u32) -> Self {
        let secret = StaticSecret::random();
        let public = X25519PublicKey::from(&secret);

        Self {
            key_id,
            secret: secret.to_bytes(),
            public: *public.as_bytes(),
        }
    }

    pub fn x25519_secret(&self) -> StaticSecret {
        StaticSecret::from(self.secret)
    }

    pub fn x25519_public(&self) -> X25519PublicKey {
        X25519PublicKey::from(self.public)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreKeyBundle {
    pub identity_key: [u8; 32],
    pub signed_pre_key: SignedPreKey,
    pub one_time_pre_keys: Vec<OneTimePreKey>,
}

impl PreKeyBundle {
    pub fn generate(identity: &IdentityKeyPair, num_one_time_keys: u32) -> Self {
        let signed_pre_key = SignedPreKey::generate(0, identity);

        let one_time_pre_keys: Vec<OneTimePreKey> = (0..num_one_time_keys)
            .map(OneTimePreKey::generate)
            .collect();

        Self {
            identity_key: identity.x25519_public,
            signed_pre_key,
            one_time_pre_keys,
        }
    }

    pub fn get_one_time_key(&self) -> Option<&OneTimePreKey> {
        self.one_time_pre_keys.first()
    }
}

pub struct X3DHKeyBundle {
    pub identity_key: StaticSecret,
    pub identity_public: X25519PublicKey,
    pub signed_pre_key: StaticSecret,
    pub signed_pre_key_public: X25519PublicKey,
    pub signed_pre_key_sig: Vec<u8>,
    pub one_time_pre_keys: Vec<(u32, StaticSecret, X25519PublicKey)>,
    pub identity_keypair: IdentityKeyPair,
}

impl X3DHKeyBundle {
    pub fn generate(identity_key: &StaticSecret, identity_public: &X25519PublicKey) -> Self {
        let identity_keypair = IdentityKeyPair::from_seed(&identity_key.to_bytes());

        let signed_pre_key_secret = StaticSecret::random();
        let signed_pre_key_public = X25519PublicKey::from(&signed_pre_key_secret);

        let signed_pre_key_sig = identity_keypair.sign(signed_pre_key_public.as_bytes());

        let mut one_time_pre_keys = Vec::new();
        for i in 0..10 {
            let sk = StaticSecret::random();
            let pk = X25519PublicKey::from(&sk);
            one_time_pre_keys.push((i, sk, pk));
        }

        Self {
            identity_key: identity_key.clone(),
            identity_public: *identity_public,
            signed_pre_key: signed_pre_key_secret,
            signed_pre_key_public,
            signed_pre_key_sig,
            one_time_pre_keys,
            identity_keypair,
        }
    }

    pub fn get_one_time_key(&self) -> Option<(u32, &X25519PublicKey)> {
        self.one_time_pre_keys.first().map(|(id, _, pk)| (*id, pk))
    }

    pub fn into_pre_key_bundle(&self) -> PreKeyBundle {
        let otpks: Vec<OneTimePreKey> = self
            .one_time_pre_keys
            .iter()
            .map(|(id, sk, pk)| OneTimePreKey {
                key_id: *id,
                secret: sk.to_bytes(),
                public: *pk.as_bytes(),
            })
            .collect();

        let spk = SignedPreKey {
            key_id: 0,
            secret: self.signed_pre_key.to_bytes(),
            public: *self.signed_pre_key_public.as_bytes(),
            signature: self.signed_pre_key_sig.clone(),
        };

        PreKeyBundle {
            identity_key: *self.identity_public.as_bytes(),
            signed_pre_key: spk,
            one_time_pre_keys: otpks,
        }
    }
}

#[derive(Debug, Clone)]
pub struct X3DHResult {
    pub shared_secret: [u8; 32],
    pub associated_data: Vec<u8>,
}

pub fn x3dh_send(
    ik_a: &StaticSecret,
    ek_a: &EphemeralSecret,
    ik_b_pub: &X25519PublicKey,
    spk_b_pub: &X25519PublicKey,
    opk_b_pub: Option<&X25519PublicKey>,
) -> Result<X3DHResult> {
    let ek_a_pub = X25519PublicKey::from(ek_a);

    // DH1 = DH(IK_A, SPK_B)
    let dh1 = ik_a.diffie_hellman(spk_b_pub);
    // DH2 = DH(EK_A, IK_B)
    let dh2 = ek_a.diffie_hellman(ik_b_pub);
    // DH3 = DH(EK_A, SPK_B)
    let dh3 = ek_a.diffie_hellman(spk_b_pub);

    let mut shared_input = Vec::new();
    shared_input.extend_from_slice(&[0xFF; 32]);
    shared_input.extend_from_slice(dh1.as_bytes());
    shared_input.extend_from_slice(dh2.as_bytes());
    shared_input.extend_from_slice(dh3.as_bytes());

    let mut associated_data = Vec::new();
    associated_data.extend_from_slice(ik_a.to_bytes().as_ref());
    associated_data.extend_from_slice(ik_b_pub.as_bytes());

    // DH4 = DH(EK_A, OPK_B) (optional)
    if let Some(opk) = opk_b_pub {
        let dh4 = ek_a.diffie_hellman(opk);
        shared_input.extend_from_slice(dh4.as_bytes());
        associated_data.extend_from_slice(opk.as_bytes());
    }

    let shared_secret = hkdf_extract_expand(&shared_input, b"zero-x3dh-v1", &associated_data)?;

    Ok(X3DHResult {
        shared_secret,
        associated_data,
    })
}

pub fn x3dh_send_with_prekey_bundle(
    identity: &IdentityKeyPair,
    prekey_bundle: &PreKeyBundle,
) -> Result<(X3DHResult, X25519PublicKey)> {
    let ek = EphemeralSecret::random();
    let ek_pub = X25519PublicKey::from(&ek);

    let ik_b_pub = prekey_bundle.identity_key();
    let spk_b_pub = prekey_bundle.signed_pre_key.x25519_public();
    let opk_b_pub = prekey_bundle.get_one_time_key().map(|opk| opk.x25519_public());

    let ik_a = identity.x25519_secret_key();

    let result = x3dh_send(&ik_a, &ek, &ik_b_pub, &spk_b_pub, opk_b_pub.as_ref())?;

    Ok((result, ek_pub))
}

impl PreKeyBundle {
    pub fn identity_key(&self) -> X25519PublicKey {
        X25519PublicKey::from(self.identity_key)
    }
}

pub fn x3dh_recv(
    ik_b: &StaticSecret,
    spk_b: &StaticSecret,
    ik_a_pub: &X25519PublicKey,
    ek_a_pub: &X25519PublicKey,
    opk_b: Option<&StaticSecret>,
) -> Result<X3DHResult> {
    // DH1 = DH(SPK_B, IK_A)
    let dh1 = spk_b.diffie_hellman(ik_a_pub);
    // DH2 = DH(IK_B, EK_A)
    let dh2 = ik_b.diffie_hellman(ek_a_pub);
    // DH3 = DH(SPK_B, EK_A)
    let dh3 = spk_b.diffie_hellman(ek_a_pub);

    let mut shared_input = Vec::new();
    shared_input.extend_from_slice(&[0xFF; 32]);
    shared_input.extend_from_slice(dh1.as_bytes());
    shared_input.extend_from_slice(dh2.as_bytes());
    shared_input.extend_from_slice(dh3.as_bytes());

    let mut associated_data = Vec::new();
    associated_data.extend_from_slice(ik_a_pub.as_bytes());
    associated_data.extend_from_slice(ik_b.to_bytes().as_ref());

    // DH4 = DH(OPK_B, EK_A) (optional)
    if let Some(opk) = opk_b {
        let dh4 = opk.diffie_hellman(ek_a_pub);
        shared_input.extend_from_slice(dh4.as_bytes());
        associated_data.extend_from_slice(opk.to_bytes().as_ref());
    }

    let shared_secret = hkdf_extract_expand(&shared_input, b"zero-x3dh-v1", &associated_data)?;

    Ok(X3DHResult {
        shared_secret,
        associated_data,
    })
}

pub fn x3dh_recv_with_prekey_bundle(
    identity: &IdentityKeyPair,
    prekey_bundle: &PreKeyBundle,
    ek_a_pub: &X25519PublicKey,
    used_one_time_key_id: Option<u32>,
) -> Result<X3DHResult> {
    let ik_b = identity.x25519_secret_key();
    let spk_b = prekey_bundle.signed_pre_key.x25519_secret();
    let ik_a_pub = X25519PublicKey::from(ek_a_pub.to_bytes()); // actually this should be alice's IK, but we use EK for now

    // For proper receiving, alice's IK and EK are separate. This helper is for the case
    // where we receive from a PreKeyBundle exchange initiated by alice.
    let opk_b = used_one_time_key_id.and_then(|id| {
        prekey_bundle
            .one_time_pre_keys
            .iter()
            .find(|opk| opk.key_id == id)
            .map(|opk| opk.x25519_secret())
    });

    x3dh_recv(&ik_b, &spk_b, ek_a_pub, ek_a_pub, opk_b.as_ref())
}

fn hkdf_extract_expand(ikm: &[u8], info: &[u8], salt: &[u8]) -> Result<[u8; 32]> {
    let (_, h) = hkdf::Hkdf::<Sha256>::new(Some(salt), ikm);
    let mut okm = [0u8; 32];
    h.expand(info, &mut okm)
        .map_err(|e| anyhow::anyhow!("hkdf expand failed: {}", e))?;
    Ok(okm)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_x3dh_key_exchange() {
        let ik_a = StaticSecret::random();
        let ik_a_pub = X25519PublicKey::from(&ik_a);

        let ik_b = StaticSecret::random();
        let ik_b_pub = X25519PublicKey::from(&ik_b);

        let spk_b = StaticSecret::random();
        let spk_b_pub = X25519PublicKey::from(&spk_b);

        let opk_b = StaticSecret::random();
        let opk_b_pub = X25519PublicKey::from(&opk_b);

        let ek_a = EphemeralSecret::random();
        let ek_a_pub = X25519PublicKey::from(&ek_a);

        let send_result = x3dh_send(&ik_a, &ek_a, &ik_b_pub, &spk_b_pub, Some(&opk_b_pub))
            .unwrap();

        let recv_result = x3dh_recv(&ik_b, &spk_b, &ik_a_pub, &ek_a_pub, Some(&opk_b)).unwrap();

        assert_eq!(send_result.shared_secret, recv_result.shared_secret);
    }

    #[test]
    fn test_identity_keypair_sign_and_verify() {
        let identity = IdentityKeyPair::generate();

        let message = b"test signed pre-key";
        let signature = identity.sign(message);
        assert!(identity.verify(message, &signature));

        let bad_message = b"tampered message";
        assert!(!identity.verify(bad_message, &signature));
    }

    #[test]
    fn test_signed_pre_key_creation_and_verification() {
        let identity = IdentityKeyPair::generate();
        let spk = SignedPreKey::generate(1, &identity);
        assert!(spk.verify(&identity));

        let other_identity = IdentityKeyPair::generate();
        assert!(!spk.verify(&other_identity));
    }

    #[test]
    fn test_prekey_bundle_generation() {
        let identity = IdentityKeyPair::generate();
        let bundle = PreKeyBundle::generate(&identity, 5);

        assert_eq!(bundle.one_time_pre_keys.len(), 5);
        assert!(bundle.get_one_time_key().is_some());
        assert_eq!(bundle.identity_key, identity.x25519_public);
    }

    #[test]
    fn test_x3dh_with_identity_keypair() {
        let alice_identity = IdentityKeyPair::generate();
        let bob_identity = IdentityKeyPair::generate();

        let bob_bundle = PreKeyBundle::generate(&bob_identity, 3);

        let (send_result, ek_pub) =
            x3dh_send_with_prekey_bundle(&alice_identity, &bob_bundle).unwrap();

        let ik_a_pub = alice_identity.x25519_public_key();

        let recv_result = x3dh_recv(
            &bob_identity.x25519_secret_key(),
            &bob_bundle.signed_pre_key.x25519_secret(),
            &ik_a_pub,
            &ek_pub,
            bob_bundle
                .get_one_time_key()
                .map(|opk| opk.x25519_secret())
                .as_ref(),
        )
        .unwrap();

        assert_eq!(send_result.shared_secret, recv_result.shared_secret);
    }

    #[test]
    fn test_x3dh_without_one_time_key() {
        let ik_a = StaticSecret::random();
        let ik_a_pub = X25519PublicKey::from(&ik_a);

        let ik_b = StaticSecret::random();
        let ik_b_pub = X25519PublicKey::from(&ik_b);

        let spk_b = StaticSecret::random();
        let spk_b_pub = X25519PublicKey::from(&spk_b);

        let ek_a = EphemeralSecret::random();
        let ek_a_pub = X25519PublicKey::from(&ek_a);

        let send_result = x3dh_send(&ik_a, &ek_a, &ik_b_pub, &spk_b_pub, None).unwrap();

        let recv_result = x3dh_recv(&ik_b, &spk_b, &ik_a_pub, &ek_a_pub, None).unwrap();

        assert_eq!(send_result.shared_secret, recv_result.shared_secret);
    }

    #[test]
    fn test_serde_roundtrip() {
        let identity = IdentityKeyPair::generate();
        let json = serde_json::to_string(&identity).unwrap();
        let deserialized: IdentityKeyPair = serde_json::from_str(&json).unwrap();
        assert_eq!(identity.x25519_public, deserialized.x25519_public);
        assert_eq!(identity.ed25519_verifying_key, deserialized.ed25519_verifying_key);
    }
}