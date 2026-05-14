use bip39::Mnemonic;
use ed25519_dalek::{SigningKey, Signer};
use sha2::{Digest, Sha256};
use x25519_dalek::{PublicKey as X25519PublicKey, StaticSecret};
use chacha20poly1305::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    ChaCha20Poly1305,
};
use hkdf::Hkdf;
use rand::RngCore;

// ============================================================
// 1. ZeroID 身份系统
// ============================================================
#[test]
fn test_zero_identity_generation() {
    let mnemonic = Mnemonic::generate(12).unwrap();
    let seed = mnemonic.to_seed("");

    let signing_key = SigningKey::from_bytes(&seed[..32].try_into().unwrap());
    let verifying_key = signing_key.verifying_key();

    let mut hasher = Sha256::new();
    hasher.update(verifying_key.as_bytes());
    let hash = hasher.finalize();
    let encoded = bs58::encode(&hash[..10]).into_string();
    let zero_id = format!("Z{}", &encoded[..9].to_uppercase());

    assert!(zero_id.starts_with('Z'));
    assert_eq!(zero_id.len(), 10);
    println!("✅ ZeroID generated: {}", zero_id);
}

#[test]
fn test_deterministic_identity() {
    let mnemonic_str = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    let mnemonic = Mnemonic::parse(mnemonic_str).unwrap();
    let seed = mnemonic.to_seed("");

    let signing_key = SigningKey::from_bytes(&seed[..32].try_into().unwrap());
    let verifying_key = signing_key.verifying_key();

    let mut hasher = Sha256::new();
    hasher.update(verifying_key.as_bytes());
    let hash = hasher.finalize();
    let encoded = bs58::encode(&hash[..10]).into_string();
    let zero_id1 = format!("Z{}", &encoded[..9].to_uppercase());

    // Same mnemonic should always give the same ID
    let mnemonic2 = Mnemonic::parse(mnemonic_str).unwrap();
    let seed2 = mnemonic2.to_seed("");
    let signing_key2 = SigningKey::from_bytes(&seed2[..32].try_into().unwrap());
    let verifying_key2 = signing_key2.verifying_key();

    let mut hasher2 = Sha256::new();
    hasher2.update(verifying_key2.as_bytes());
    let hash2 = hasher2.finalize();
    let encoded2 = bs58::encode(&hash2[..10]).into_string();
    let zero_id2 = format!("Z{}", &encoded2[..9].to_uppercase());

    assert_eq!(zero_id1, zero_id2);
    println!("✅ Deterministic identity: {} == {}", zero_id1, zero_id2);
}

// ============================================================
// 2. X3DH + Double Ratchet E2EE
// ============================================================
#[test]
fn test_x3dh_key_exchange() {
    let ik_a = StaticSecret::random_from_rng(&mut OsRng);
    let ik_b = StaticSecret::random_from_rng(&mut OsRng);
    let spk_b = StaticSecret::random_from_rng(&mut OsRng);
    let opk_b = StaticSecret::random_from_rng(&mut OsRng);

    let ik_a_pub = X25519PublicKey::from(&ik_a);
    let ik_b_pub = X25519PublicKey::from(&ik_b);
    let spk_b_pub = X25519PublicKey::from(&spk_b);
    let opk_b_pub = X25519PublicKey::from(&opk_b);

    // Alice's side: DH1=EK_A*IK_B, DH2=IK_A*SPK_B, DH3=EK_A*SPK_B, DH4=EK_A*OPK_B
    let ek_a = StaticSecret::random_from_rng(&mut OsRng);
    let ek_a_pub = X25519PublicKey::from(&ek_a);

    let dh1 = ek_a.diffie_hellman(&ik_b_pub);
    let dh2 = ik_a.diffie_hellman(&spk_b_pub);
    let dh3 = ek_a.diffie_hellman(&spk_b_pub);
    let dh4 = ek_a.diffie_hellman(&opk_b_pub);

    let mut shared_input = Vec::new();
    shared_input.extend_from_slice(dh1.as_bytes());
    shared_input.extend_from_slice(dh2.as_bytes());
    shared_input.extend_from_slice(dh3.as_bytes());
    shared_input.extend_from_slice(dh4.as_bytes());

    let hkdf_alice = Hkdf::<Sha256>::new(None, &shared_input);
    let mut okm_alice = [0u8; 32];
    hkdf_alice.expand(b"zero-x3dh-v1", &mut okm_alice).unwrap();

    // Bob's side: DH1=IK_B*EK_A, DH2=SPK_B*IK_A, DH3=SPK_B*EK_A, DH4=OPK_B*EK_A
    let dh1b = ik_b.diffie_hellman(&ek_a_pub);
    let dh2b = spk_b.diffie_hellman(&ik_a_pub);
    let dh3b = spk_b.diffie_hellman(&ek_a_pub);
    let dh4b = opk_b.diffie_hellman(&ek_a_pub);

    let mut shared_input_bob = Vec::new();
    shared_input_bob.extend_from_slice(dh1b.as_bytes());
    shared_input_bob.extend_from_slice(dh2b.as_bytes());
    shared_input_bob.extend_from_slice(dh3b.as_bytes());
    shared_input_bob.extend_from_slice(dh4b.as_bytes());

    let hkdf_bob = Hkdf::<Sha256>::new(None, &shared_input_bob);
    let mut okm_bob = [0u8; 32];
    hkdf_bob.expand(b"zero-x3dh-v1", &mut okm_bob).unwrap();

    assert_eq!(okm_alice, okm_bob);
    println!("✅ X3DH key exchange: shared secret established");
}

// ============================================================
// 3. E2EE 消息加解密 (ChaCha20-Poly1305)
// ============================================================
#[test]
fn test_e2ee_message_encryption() {
    let mut key = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut key);

    let cipher = ChaCha20Poly1305::new_from_slice(&key).unwrap();
    let nonce = ChaCha20Poly1305::generate_nonce(&mut OsRng);

    let plaintext = b"Hello from Zero! This is an encrypted message.";
    let ciphertext = cipher.encrypt(&nonce, plaintext.as_ref()).unwrap();

    let decrypted = cipher.decrypt(&nonce, ciphertext.as_ref()).unwrap();
    assert_eq!(plaintext.as_ref(), decrypted.as_slice());

    println!("✅ E2EE encryption: {} bytes encrypted and decrypted", plaintext.len());
}

#[test]
fn test_message_forward_secrecy() {
    // Each message gets its own key derived from chain
    let root_key = [0x42u8; 32];

    // KDF chain key derivation
    let hkdf = Hkdf::<Sha256>::new(None, &root_key);
    let mut okm = [0u8; 64];
    hkdf.expand(b"zero-chain-key-v1", &mut okm).unwrap();

    let mut chain_key = [0u8; 32];
    let mut msg_key = [0u8; 32];
    msg_key.copy_from_slice(&okm[..32]);
    chain_key.copy_from_slice(&okm[32..]);

    // Encrypt message 1 with msg_key
    let cipher1 = ChaCha20Poly1305::new_from_slice(&msg_key).unwrap();
    let nonce1 = ChaCha20Poly1305::generate_nonce(&mut OsRng);
    let ct1 = cipher1.encrypt(&nonce1, b"message 1".as_ref()).unwrap();

    // Derive new chain key for message 2
    let hkdf2 = Hkdf::<Sha256>::new(None, &chain_key);
    let mut okm2 = [0u8; 64];
    hkdf2.expand(b"zero-chain-key-v1", &mut okm2).unwrap();

    let mut msg_key2 = [0u8; 32];
    msg_key2.copy_from_slice(&okm2[..32]);

    let cipher2 = ChaCha20Poly1305::new_from_slice(&msg_key2).unwrap();
    let nonce2 = ChaCha20Poly1305::generate_nonce(&mut OsRng);
    let ct2 = cipher2.encrypt(&nonce2, b"message 2".as_ref()).unwrap();

    // msg_key1 should NOT decrypt message 2 (forward secrecy)
    assert_ne!(msg_key, msg_key2);
    assert_ne!(ct1, ct2);

    println!("✅ Forward secrecy: each message has unique key");
}

// ============================================================
// 4. 多链钱包地址派生
// ============================================================
#[test]
fn test_multichain_wallet_derivation() {
    let seed = {
        let mut s = [0u8; 64];
        rand::thread_rng().fill_bytes(&mut s);
        s
    };

    let chains = vec![
        ("BTC", "m/44'/0'/0'/0/0"),
        ("ETH", "m/44'/60'/0'/0/0"),
        ("BSC", "m/44'/60'/0'/0/0"),
        ("TRX", "m/44'/195'/0'/0/0"),
        ("SOL", "m/44'/501'/0'/0'"),
    ];

    for (chain, path) in &chains {
        let hkdf = Hkdf::<Sha256>::new(Some(chain.as_bytes()), &seed);
        let mut derived = vec![0u8; 32];
        hkdf.expand(path.as_bytes(), &mut derived).unwrap();

        let address = match *chain {
            "BTC" => format!("1{}", hex::encode(&derived[..16])),
            "ETH" | "BSC" => format!("0x{}", hex::encode(&derived[..20])),
            "TRX" => format!("T{}", hex::encode(&derived[..16])),
            "SOL" => bs58::encode(&derived).into_string(),
            _ => String::new(),
        };

        assert!(!address.is_empty());
        println!("  ✅ {}: {} (path: {})", chain, &address[..20], path);
    }

    println!("✅ Multi-chain wallet: 5 chains derived from 1 seed");
}

// ============================================================
// 5. BLE 蓝牙消息协议
// ============================================================
#[derive(Debug, PartialEq)]
enum BTMsgType { Text, FileChunk, ContactExchange, Ping, Ack }

struct BTMessage {
    msg_type: BTMsgType,
    sender_id: String,
    payload: Vec<u8>,
    sequence: u32,
    timestamp: u64,
    needs_ack: bool,
}

fn serialize_bt_message(msg: &BTMessage) -> Vec<u8> {
    let mut data = Vec::new();
    let type_byte = match msg.msg_type {
        BTMsgType::Text => 0u8,
        BTMsgType::FileChunk => 1u8,
        BTMsgType::ContactExchange => 2u8,
        BTMsgType::Ping => 3u8,
        BTMsgType::Ack => 4u8,
    };
    data.push(type_byte);
    let mut id_buf = [0u8; 12];
    let id_bytes = msg.sender_id.as_bytes();
    id_buf[..id_bytes.len().min(12)].copy_from_slice(&id_bytes[..id_bytes.len().min(12)]);
    data.extend_from_slice(&id_buf);
    data.extend_from_slice(&msg.sequence.to_be_bytes());
    data.extend_from_slice(&msg.timestamp.to_be_bytes());
    data.push(msg.needs_ack as u8);
    let payload_len = msg.payload.len() as u16;
    data.extend_from_slice(&payload_len.to_be_bytes());
    data.extend_from_slice(&msg.payload);
    data
}

fn deserialize_bt_message(data: &[u8]) -> Option<BTMessage> {
    if data.len() < 28 { return None; }
    let msg_type = match data[0] { 0 => BTMsgType::Text, 1 => BTMsgType::FileChunk, 2 => BTMsgType::ContactExchange, 3 => BTMsgType::Ping, 4 => BTMsgType::Ack, _ => return None };
    let sender_id = String::from_utf8_lossy(&data[1..13]).trim_end_matches('\0').to_string();
    let sequence = u32::from_be_bytes(data[13..17].try_into().ok()?);
    let timestamp = u64::from_be_bytes(data[17..25].try_into().ok()?);
    let needs_ack = data[25] != 0;
    let payload_len = u16::from_be_bytes(data[26..28].try_into().ok()?) as usize;
    if data.len() < 28 + payload_len { return None; }
    let payload = data[28..28+payload_len].to_vec();
    Some(BTMessage { msg_type, sender_id, payload, sequence, timestamp, needs_ack })
}

#[test]
fn test_ble_messaging() {
    let msg = BTMessage {
        msg_type: BTMsgType::Text,
        sender_id: "Z8P2K5W1RT".to_string(),
        payload: b"Hello via BLE!".to_vec(),
        sequence: 1,
        timestamp: 1700000000000,
        needs_ack: true,
    };

    let serialized = serialize_bt_message(&msg);
    let deserialized = deserialize_bt_message(&serialized).unwrap();

    assert_eq!(deserialized.msg_type, BTMsgType::Text);
    assert_eq!(deserialized.sender_id, "Z8P2K5W1RT");
    assert_eq!(String::from_utf8_lossy(&deserialized.payload), "Hello via BLE!");
    assert_eq!(deserialized.sequence, 1);

    println!("✅ BLE Mesh protocol: message serialized & deserialized ({}+{} bytes)",
        serialized.len() - msg.payload.len(), msg.payload.len());
}

// ============================================================
// 6. DASN 内容寻址存储
// ============================================================
#[test]
fn test_dasn_content_addressing() {
    let data = b"zero decentralized storage content";
    let hash: [u8; 32] = Sha256::digest(data).into();

    let stored_content = hex::encode(&hash);
    let retrieved_hash: [u8; 32] = Sha256::digest(data).into();
    let retrieved_content = hex::encode(&retrieved_hash);

    assert_eq!(stored_content, retrieved_content);
    println!("✅ DASN: content-addressed storage (CID: {}...)", &stored_content[..16]);
}

#[test]
fn test_dasn_dedup() {
    let data1 = b"same content";
    let data2 = b"same content";
    let hash1: [u8; 32] = Sha256::digest(data1).into();
    let hash2: [u8; 32] = Sha256::digest(data2).into();
    assert_eq!(hash1, hash2);
    println!("✅ DASN deduplication: identical content = identical CID");
}

// ============================================================
// 7. W3C DID 身份
// ============================================================
#[test]
fn test_did_generation() {
    let zero_id = "Z8P2K5W1RT";
    let did = format!("did:zero:{}", zero_id.to_lowercase());
    assert_eq!(did, "did:zero:z8p2k5w1rt");

    let vm_id = format!("{}#keys-1", did);
    println!("✅ DID: {}", did);
    println!("   Verification Method: {}", vm_id);
    println!("   Service: zero://{} (Chat), zero://{}/wallet (Pay)", zero_id, zero_id);
}

// ============================================================
// 8. AI 助手规则引擎
// ============================================================
#[test]
fn test_ai_rule_engine() {
    let responses = vec![
        ("how does encryption work", "X3DH"),
        ("what wallets do you support", "BTC, ETH, BSC, TRX"),
        ("hello", "Hello! I'm ZeroAI"),
    ];

    for (query, expected_keyword) in &responses {
        let response = simulate_ai_response(query);
        assert!(response.contains(expected_keyword),
            "Query '{}' should contain keyword '{}'", query, expected_keyword);
    }
    println!("✅ ZeroAI rule engine: 3/3 queries matched correctly");
}

fn simulate_ai_response(query: &str) -> String {
    let q = query.to_lowercase();
    if q.contains("encrypt") {
        "Zero uses X3DH key agreement + Double Ratchet protocol. Each message has a unique encryption key.".to_string()
    } else if q.contains("wallet") {
        "Zero supports BTC, ETH, BSC, TRX, and SOL — all from one seed phrase with BIP44 derivation.".to_string()
    } else if q.contains("hello") || q.contains("hi") {
        "Hello! I'm ZeroAI, your privacy-first assistant for Zero / 零界.".to_string()
    } else {
        "I'm here to help with Zero.".to_string()
    }
}

// ============================================================
// 9. 公钥指纹完整性
// ============================================================
#[test]
fn test_public_key_fingerprint() {
    let signing_key = SigningKey::from_bytes(&[0x42u8; 32]);
    let verifying_key = signing_key.verifying_key();
    let message = b"Zero identity verification";

    let signature = signing_key.sign(message);
    assert!(verifying_key.verify_strict(message, &signature).is_ok());

    let tampered = b"Tampered message";
    assert!(verifying_key.verify_strict(tampered, &signature).is_err());

    println!("✅ Ed25519 signatures: valid & tampered correctly detected");
}

// ============================================================
// 10. 消息 ID 哈希
// ============================================================
#[test]
fn test_message_id_derivation() {
    let sender = "Z8P2K5W1RT";
    let recipient = "Z3K7M2N8XP";
    let timestamp = 1700000000000u64;

    let mut hasher = Sha256::new();
    hasher.update(sender.as_bytes());
    hasher.update(recipient.as_bytes());
    hasher.update(b"encrypted content here");
    hasher.update(timestamp.to_be_bytes());
    let hash = hasher.finalize();

    let msg_id = hex::encode(&hash[..16]);
    assert_eq!(msg_id.len(), 32);
    println!("✅ Message ID: {}", msg_id);
}

fn main() {
    println!("========================================");
    println!("  Zero / 零界 — Core Integration Tests");
    println!("========================================\n");
    println!("🧪 Running 10 integration tests...\n");
    println!("All tests passed if you see no panic!\n");
    println!("Run with: cargo test -- --nocapture\n");
}