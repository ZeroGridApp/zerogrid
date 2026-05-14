use anyhow::Result;
use sha2::{Digest, Sha256};
use hkdf::Hkdf;
use bs58;

pub fn derive_trx_address(seed: &[u8], path: &str) -> Result<String> {
    let hkdf = Hkdf::<Sha256>::new(Some(b"tron-seed"), seed);
    let mut derived = vec![0u8; 32];
    hkdf.expand(path.as_bytes(), &mut derived)
        .map_err(|e| anyhow::anyhow!("hkdf expand failed: {}", e))?;

    let mut hasher = Sha256::new();
    hasher.update(b"zero-trx-wallet-v1");
    hasher.update(&derived);
    let hash = hasher.finalize();

    let prefix = [0x41u8];
    let mut addr_bytes = Vec::with_capacity(21);
    addr_bytes.extend_from_slice(&prefix);
    addr_bytes.extend_from_slice(&hash[..20]);

    let mut hasher2 = Sha256::new();
    hasher2.update(&addr_bytes);
    let h1 = hasher2.finalize();
    let mut hasher3 = Sha256::new();
    hasher3.update(&h1);
    let h2 = hasher3.finalize();

    let mut full = Vec::with_capacity(25);
    full.extend_from_slice(&addr_bytes);
    full.extend_from_slice(&h2[..4]);

    let address = bs58::encode(&full).into_string();

    Ok(address)
}