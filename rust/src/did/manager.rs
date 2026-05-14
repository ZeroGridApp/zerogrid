use anyhow::Result;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DIDDocument {
    pub id: String,
    pub controller: Vec<String>,
    pub verification_method: Vec<VerificationMethod>,
    pub authentication: Vec<String>,
    pub assertion_method: Vec<String>,
    pub service: Vec<ServiceEndpoint>,
    pub created: String,
    pub updated: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationMethod {
    pub id: String,
    pub controller: String,
    pub key_type: String,
    pub public_key_multibase: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceEndpoint {
    pub id: String,
    pub service_type: String,
    pub endpoint: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerifiableCredential {
    pub context: Vec<String>,
    pub credential_type: Vec<String>,
    pub issuer: String,
    pub issuance_date: String,
    pub credential_subject: CredentialSubject,
    pub proof: Proof,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CredentialSubject {
    pub id: String,
    pub claims: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Proof {
    pub proof_type: String,
    pub created: String,
    pub verification_method: String,
    pub proof_value: String,
}

pub struct DIDManager {
    did: String,
    document: DIDDocument,
}

impl DIDManager {
    pub fn from_zero_id(zero_id: &str, public_key_hex: &str) -> Result<Self> {
        let did = format!("did:zero:{}", zero_id.to_lowercase());

        let vm_id = format!("{}#keys-1", did);
        let verification_method = VerificationMethod {
            id: vm_id.clone(),
            controller: did.clone(),
            key_type: "Ed25519VerificationKey2020".to_string(),
            public_key_multibase: format!("z{}", public_key_hex),
        };

        let now = chrono_now();

        let document = DIDDocument {
            id: did.clone(),
            controller: vec![did.clone()],
            verification_method: vec![verification_method],
            authentication: vec![vm_id.clone()],
            assertion_method: vec![vm_id],
            service: vec![
                ServiceEndpoint {
                    id: format!("{}#zero-chat", did),
                    service_type: "ZeroChatService".to_string(),
                    endpoint: format!("zero://{}", zero_id),
                },
                ServiceEndpoint {
                    id: format!("{}#zero-pay", did),
                    service_type: "ZeroPayService".to_string(),
                    endpoint: format!("zero://{}/wallet", zero_id),
                },
            ],
            created: now.clone(),
            updated: now,
        };

        Ok(Self { did, document })
    }

    pub fn did(&self) -> &str {
        &self.did
    }

    pub fn document(&self) -> &DIDDocument {
        &self.document
    }

    pub fn resolve(&self) -> String {
        serde_json::to_string_pretty(&self.document).unwrap_or_default()
    }

    pub fn issue_credential(&self, subject_id: &str, claims: serde_json::Value) -> VerifiableCredential {
        VerifiableCredential {
            context: vec![
                "https://www.w3.org/2018/credentials/v1".to_string(),
                "https://zero.im/credentials/v1".to_string(),
            ],
            credential_type: vec!["VerifiableCredential".to_string(), "ZeroIdentityCredential".to_string()],
            issuer: self.did.clone(),
            issuance_date: chrono_now(),
            credential_subject: CredentialSubject {
                id: subject_id.to_string(),
                claims,
            },
            proof: Proof {
                proof_type: "Ed25519Signature2020".to_string(),
                created: chrono_now(),
                verification_method: format!("{}#keys-1", self.did),
                proof_value: "signed_by_zero_identity".to_string(),
            },
        }
    }
}

fn chrono_now() -> String {
    "2025-01-01T00:00:00Z".to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_did_generation() {
        let manager = DIDManager::from_zero_id(
            "Z8P2K5W1RT",
            "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
        ).unwrap();

        assert_eq!(manager.did(), "did:zero:z8p2k5w1rt");
        assert_eq!(manager.document().verification_method.len(), 1);
        assert_eq!(manager.document().service.len(), 2);
    }

    #[test]
    fn test_credential_issuance() {
        let manager = DIDManager::from_zero_id(
            "Z8P2K5W1RT",
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        ).unwrap();

        let credential = manager.issue_credential(
            "did:zero:z3k7m2n8xp",
            serde_json::json!({"membership": "verified", "level": 3}),
        );

        assert_eq!(credential.issuer, "did:zero:z8p2k5w1rt");
    }
}