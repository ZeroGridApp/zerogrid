use anyhow::Result;
use bitcoin::bip32::{DerivationPath, Xpriv};
use bitcoin::Network;
use sha2::Sha256;
use hkdf::Hkdf;

pub fn derive_btc_address(seed: &[u8], path: &str) -> Result<String> {
    let hkdf = Hkdf::<Sha256>::new(Some(b"bitcoin-seed"), seed);
    let mut derived = vec![0u8; 64];
    hkdf.expand(b"zero-wallet-v1", &mut derived)
        .map_err(|e| anyhow::anyhow!("hkdf expand failed: {}", e))?;

    let xpriv = Xpriv::new_master(Network::Bitcoin, &derived[..32])
        .map_err(|e| anyhow::anyhow!("master key derivation failed: {}", e))?;

    let derivation_path: DerivationPath = path.parse()
        .map_err(|e| anyhow::anyhow!("invalid derivation path: {}", e))?;

    let derived_key = xpriv.derive_priv(&bitcoin::secp256k1::Secp256k1::new(), &derivation_path)
        .map_err(|e| anyhow::anyhow!("key derivation failed: {}", e))?;

    let pubkey = bitcoin::PublicKey::new(derived_key.private_key.public_key(&bitcoin::secp256k1::Secp256k1::new()));
    let address = bitcoin::Address::p2pkh(&pubkey, Network::Bitcoin);

    Ok(address.to_string())
}