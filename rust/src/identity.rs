use anyhow::Result;
use bip39::Mnemonic;
use ed25519_dalek::{SigningKey, VerifyingKey};
use rand::rngs::OsRng;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use hmac::{Hmac, Mac};
use sha2::Sha512;

type HmacSha512 = Hmac<Sha512>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZeroIdentity {
    pub zero_id: String,
    pub mnemonic_phrase: String,
    pub signing_key_bytes: [u8; 32],
    pub verifying_key_bytes: [u8; 32],
    pub seed: [u8; 64],
    pub derivation_path: String,
}

#[derive(Debug, thiserror::Error)]
pub enum IdentityError {
    #[error("invalid mnemonic: {0}")]
    InvalidMnemonic(String),
    #[error("mnemonic generation failed: {0}")]
    MnemonicGenerationFailed(String),
    #[error("key derivation failed: {0}")]
    KeyDerivationFailed(String),
    #[error("invalid derivation path: {0}")]
    InvalidDerivationPath(String),
    #[error("invalid seed length: expected 64, got {0}")]
    InvalidSeedLength(usize),
}

pub fn generate_mnemonic() -> Result<(Mnemonic, String)> {
    let mut rng = OsRng;
    let mnemonic =
        Mnemonic::generate_with_count(&mut rng, 12).map_err(|e| anyhow::anyhow!("{}", e))?;
    let phrase = mnemonic.to_string();
    Ok((mnemonic, phrase))
}

pub fn generate_mnemonic_phrase() -> Result<String> {
    let (_, phrase) = generate_mnemonic()?;
    Ok(phrase)
}

pub fn mnemonic_to_seed(mnemonic: &Mnemonic, passphrase: &str) -> [u8; 64] {
    mnemonic.to_seed(passphrase)
}

pub fn mnemonic_validate(phrase: &str) -> bool {
    Mnemonic::parse(phrase).is_ok()
}

pub fn parse_mnemonic(phrase: &str) -> Result<Mnemonic> {
    Mnemonic::parse(phrase).map_err(|e| anyhow::anyhow!("{}", e))
}

#[derive(Debug, Clone)]
pub struct DerivedKeypair {
    pub signing_key: SigningKey,
    pub verifying_key: VerifyingKey,
    pub chain_code: [u8; 32],
}

pub fn derive_keypair(seed: &[u8; 64], path: &str) -> Result<DerivedKeypair> {
    if path != "m/44'/0'/0'/0/0" && path != "m" {
        let indices = parse_derivation_path(path)?;
        return derive_keypair_from_indices(seed, &indices);
    }

    let (master_sk, master_cc) = derive_master_key(seed);

    if path == "m" {
        let signing_key = SigningKey::from_bytes(&master_sk);
        let verifying_key = signing_key.verifying_key();
        return Ok(DerivedKeypair {
            signing_key,
            verifying_key,
            chain_code: master_cc,
        });
    }

    let indices: Vec<u32> = vec![
        44 + 0x80000000,
        0 + 0x80000000,
        0 + 0x80000000,
        0,
        0,
    ];

    derive_keypair_from_indices(seed, &indices)
}

fn derive_keypair_from_indices(seed: &[u8; 64], indices: &[u32]) -> Result<DerivedKeypair> {
    let (mut sk, mut cc) = derive_master_key(seed);

    for &index in indices {
        let child = derive_child_key(&sk, &cc, index)?;
        sk = child.0;
        cc = child.1;
    }

    let signing_key = SigningKey::from_bytes(&sk);
    let verifying_key = signing_key.verifying_key();

    Ok(DerivedKeypair {
        signing_key,
        verifying_key,
        chain_code: cc,
    })
}

fn parse_derivation_path(path: &str) -> Result<Vec<u32>> {
    if !path.starts_with("m/") {
        return Err(anyhow::anyhow!("path must start with 'm/'"));
    }

    let parts: Vec<&str> = path[2..].split('/').collect();
    let mut indices = Vec::new();

    for part in parts {
        let hardened = part.ends_with('\'');
        let num_str = if hardened { &part[..part.len() - 1] } else { part };
        let num: u32 = num_str
            .parse()
            .map_err(|_| anyhow::anyhow!("invalid index in path: {}", part))?;

        if hardened {
            if num >= 0x80000000 {
                return Err(anyhow::anyhow!("hardened index overflow: {}", part));
            }
            indices.push(num + 0x80000000);
        } else {
            indices.push(num);
        }
    }

    Ok(indices)
}

fn derive_master_key(seed: &[u8; 64]) -> ([u8; 32], [u8; 32]) {
    let mut mac =
        HmacSha512::new_from_slice(b"ed25519 seed").expect("HMAC can take key of any size");
    mac.update(seed);
    let result = mac.finalize().into_bytes();

    let mut il = [0u8; 32];
    let mut ir = [0u8; 32];
    il.copy_from_slice(&result[..32]);
    ir.copy_from_slice(&result[32..]);
    (il, ir)
}

fn derive_child_key(
    parent_sk: &[u8; 32],
    parent_cc: &[u8; 32],
    index: u32,
) -> Result<([u8; 32], [u8; 32])> {
    let mut mac = HmacSha512::new_from_slice(parent_cc).expect("HMAC can take key of any size");

    mac.update(&[0x00]);
    mac.update(parent_sk);
    mac.update(&index.to_be_bytes());

    let result = mac.finalize().into_bytes();

    let mut il = [0u8; 32];
    let mut ir = [0u8; 32];
    il.copy_from_slice(&result[..32]);
    ir.copy_from_slice(&result[32..]);
    Ok((il, ir))
}

impl ZeroIdentity {
    pub fn generate() -> Result<Self> {
        let (mnemonic, phrase) = generate_mnemonic()?;
        Self::from_mnemonic_and_passphrase(&mnemonic, &phrase, "")
    }

    pub fn generate_with_passphrase(passphrase: &str) -> Result<Self> {
        let (mnemonic, phrase) = generate_mnemonic()?;
        Self::from_mnemonic_and_passphrase(&mnemonic, &phrase, passphrase)
    }

    pub fn from_mnemonic(mnemonic: Mnemonic) -> Result<Self> {
        let phrase = mnemonic.to_string();
        Self::from_mnemonic_and_passphrase(&mnemonic, &phrase, "")
    }

    pub fn from_mnemonic_phrase(phrase: &str) -> Result<Self> {
        let mnemonic = parse_mnemonic(phrase)?;
        Self::from_mnemonic_and_passphrase(&mnemonic, phrase, "")
    }

    pub fn from_mnemonic_phrase_with_passphrase(phrase: &str, passphrase: &str) -> Result<Self> {
        let mnemonic = parse_mnemonic(phrase)?;
        Self::from_mnemonic_and_passphrase(&mnemonic, phrase, passphrase)
    }

    fn from_mnemonic_and_passphrase(
        mnemonic: &Mnemonic,
        phrase: &str,
        passphrase: &str,
    ) -> Result<Self> {
        let seed = mnemonic_to_seed(mnemonic, passphrase);

        let path = "m/44'/0'/0'/0/0";
        let derived = derive_keypair(&seed, path)?;

        let signing_key_bytes = derived.signing_key.to_bytes();
        let verifying_key_bytes = derived.verifying_key.to_bytes();

        let zero_id = Self::derive_zero_id(&derived.verifying_key);

        Ok(Self {
            zero_id,
            mnemonic_phrase: phrase.to_string(),
            signing_key_bytes,
            verifying_key_bytes,
            seed,
            derivation_path: path.to_string(),
        })
    }

    fn derive_zero_id(verifying_key: &VerifyingKey) -> String {
        let mut hasher = Sha256::new();
        hasher.update(b"zero-id-v1");
        hasher.update(verifying_key.as_bytes());
        let hash = hasher.finalize();

        let mut id_bytes = Vec::with_capacity(21);
        id_bytes.extend_from_slice(b"zid1");
        id_bytes.extend_from_slice(&hash[..17]);
        bs58::encode(&id_bytes).into_string()
    }

    pub fn zero_id(&self) -> &str {
        &self.zero_id
    }

    pub fn mnemonic_phrase_str(&self) -> &str {
        &self.mnemonic_phrase
    }

    pub fn public_key_hex(&self) -> String {
        hex::encode(&self.verifying_key_bytes)
    }

    pub fn signing_key(&self) -> SigningKey {
        SigningKey::from_bytes(&self.signing_key_bytes)
    }

    pub fn verifying_key(&self) -> VerifyingKey {
        VerifyingKey::from_bytes(&self.verifying_key_bytes)
            .expect("valid verifying key bytes")
    }

    pub fn seed(&self) -> &[u8; 64] {
        &self.seed
    }

    pub fn derivation_path(&self) -> &str {
        &self.derivation_path
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_mnemonic() {
        let phrase = generate_mnemonic_phrase().unwrap();
        let words: Vec<&str> = phrase.split_whitespace().collect();
        assert_eq!(words.len(), 12);
        assert!(mnemonic_validate(&phrase));
    }

    #[test]
    fn test_mnemonic_validate() {
        let valid = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        assert!(mnemonic_validate(valid));

        let invalid = "hello world foo bar baz qux quux quuz corge grault garply waldo xyzzy";
        assert!(!mnemonic_validate(invalid));
    }

    #[test]
    fn test_mnemonic_to_seed() {
        let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let mnemonic = parse_mnemonic(phrase).unwrap();
        let seed = mnemonic_to_seed(&mnemonic, "");
        assert_eq!(seed.len(), 64);

        let seed_with_passphrase = mnemonic_to_seed(&mnemonic, "TREZOR");
        assert_ne!(seed, seed_with_passphrase);
    }

    #[test]
    fn test_derive_keypair() {
        let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let mnemonic = parse_mnemonic(phrase).unwrap();
        let seed = mnemonic_to_seed(&mnemonic, "");

        let derived = derive_keypair(&seed, "m/44'/0'/0'/0/0").unwrap();
        let pk_hex = hex::encode(derived.verifying_key.as_bytes());
        assert_eq!(pk_hex.len(), 64);

        let derived_master = derive_keypair(&seed, "m").unwrap();
        let master_pk_hex = hex::encode(derived_master.verifying_key.as_bytes());
        assert_eq!(master_pk_hex.len(), 64);

        assert_ne!(pk_hex, master_pk_hex);
    }

    #[test]
    fn test_generate_identity() {
        let identity = ZeroIdentity::generate().unwrap();
        assert!(identity.zero_id().starts_with('z'));
        assert_eq!(identity.zero_id().len() > 20, true);
        assert!(!identity.mnemonic_phrase_str().is_empty());
    }

    #[test]
    fn test_deterministic_identity() {
        let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let identity = ZeroIdentity::from_mnemonic_phrase(phrase).unwrap();
        assert!(!identity.zero_id().is_empty());
        assert_eq!(identity.mnemonic_phrase_str(), phrase);
    }

    #[test]
    fn test_identity_from_phrase_with_passphrase() {
        let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let id1 = ZeroIdentity::from_mnemonic_phrase_with_passphrase(phrase, "").unwrap();
        let id2 = ZeroIdentity::from_mnemonic_phrase_with_passphrase(phrase, "secret").unwrap();

        assert_ne!(id1.zero_id(), id2.zero_id());
        assert_ne!(id1.verifying_key_bytes, id2.verifying_key_bytes);
    }

    #[test]
    fn test_identity_deterministic_same_input() {
        let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let id1 = ZeroIdentity::from_mnemonic_phrase_with_passphrase(phrase, "pass123").unwrap();
        let id2 = ZeroIdentity::from_mnemonic_phrase_with_passphrase(phrase, "pass123").unwrap();

        assert_eq!(id1.zero_id(), id2.zero_id());
        assert_eq!(id1.verifying_key_bytes, id2.verifying_key_bytes);
    }

    #[test]
    fn test_serde_roundtrip() {
        let identity = ZeroIdentity::generate().unwrap();
        let json = serde_json::to_string(&identity).unwrap();
        let deserialized: ZeroIdentity = serde_json::from_str(&json).unwrap();

        assert_eq!(identity.zero_id, deserialized.zero_id);
        assert_eq!(identity.mnemonic_phrase, deserialized.mnemonic_phrase);
        assert_eq!(identity.verifying_key_bytes, deserialized.verifying_key_bytes);
        assert_eq!(identity.derivation_path, deserialized.derivation_path);
    }

    #[test]
    fn test_derivation_path_parsing() {
        let indices = parse_derivation_path("m/44'/0'/0'/0/0").unwrap();
        assert_eq!(indices.len(), 5);
        assert_eq!(indices[0], 44 + 0x80000000);
        assert_eq!(indices[1], 0x80000000);
        assert_eq!(indices[2], 0x80000000);
        assert_eq!(indices[3], 0);
        assert_eq!(indices[4], 0);
    }

    #[test]
    fn test_invalid_derivation_path() {
        assert!(parse_derivation_path("invalid").is_err());
        assert!(parse_derivation_path("m/abc'").is_err());
    }
}