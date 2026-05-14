use crate::identity::ZeroIdentity;

pub mod btc;
pub mod evm;
pub mod sol;
pub mod trx;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub enum Chain {
    Bitcoin,
    Ethereum,
    Bsc,
    Tron,
    Solana,
}

impl Chain {
    pub fn bip44_path(&self) -> &str {
        match self {
            Chain::Bitcoin => "m/44'/0'/0'/0/0",
            Chain::Ethereum => "m/44'/60'/0'/0/0",
            Chain::Bsc => "m/44'/60'/0'/0/0",
            Chain::Tron => "m/44'/195'/0'/0/0",
            Chain::Solana => "m/44'/501'/0'/0'",
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct WalletAddress {
    pub chain: Chain,
    pub address: String,
    pub path: String,
}

pub struct MultiChainWallet {
    identity: ZeroIdentity,
}

impl MultiChainWallet {
    pub fn new(identity: ZeroIdentity) -> Self {
        Self { identity }
    }

    pub fn derive_addresses(&self) -> anyhow::Result<Vec<WalletAddress>> {
        let chains = vec![
            Chain::Bitcoin,
            Chain::Ethereum,
            Chain::Bsc,
            Chain::Tron,
            Chain::Solana,
        ];

        let mut addresses = Vec::new();
        let seed = *self.identity.seed();

        for chain in chains {
            let path = chain.bip44_path().to_string();
            let address = match chain {
                Chain::Bitcoin => btc::derive_btc_address(&seed, &path)?,
                Chain::Ethereum => evm::derive_evm_address(&seed, &path)?,
                Chain::Bsc => evm::derive_evm_address(&seed, &path)?,
                Chain::Tron => trx::derive_trx_address(&seed, &path)?,
                Chain::Solana => sol::derive_sol_address(&seed, &path)?,
            };

            addresses.push(WalletAddress {
                chain,
                address,
                path,
            });
        }

        Ok(addresses)
    }
}