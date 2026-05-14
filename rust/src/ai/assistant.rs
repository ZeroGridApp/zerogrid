use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AIRequest {
    pub messages: Vec<ChatMessage>,
    pub max_tokens: u32,
    pub temperature: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AIResponse {
    pub content: String,
    pub tokens_used: u32,
    pub model: String,
}

#[derive(Debug, Clone)]
pub struct KnowledgeEntry {
    pub title: String,
    pub content: String,
    pub embedding: Vec<f32>,
    pub source: String,
}

pub struct ZeroAIAssistant {
    system_prompt: String,
    knowledge_base: Vec<KnowledgeEntry>,
    conversation_history: Vec<ChatMessage>,
    max_history: usize,
}

impl ZeroAIAssistant {
    pub fn new() -> Self {
        Self {
            system_prompt: Self::default_system_prompt(),
            knowledge_base: Vec::new(),
            conversation_history: Vec::new(),
            max_history: 20,
        }
    }

    fn default_system_prompt() -> String {
        vec![
            "You are ZeroAI, the native AI assistant for Zero / 零界 decentralized social network.",
            "",
            "Core principles:",
            "- Zero is a fully decentralized, E2EE social network with no central servers",
            "- Identity is derived from BIP39 mnemonic seeds (ZeroID format: Z + 9 alphanumeric)",
            "- All messages use X3DH + Double Ratchet encryption (Signal Protocol level)",
            "- P2P network runs on libp2p with Gossipsub + Kademlia DHT",
            "- Multi-chain wallet supports BTC, ETH, BSC, TRX, SOL",
            "- ZeroNode super-nodes provide relay and DASN distributed storage",
            "",
            "You help users with:",
            "- Understanding Zero's privacy and security features",
            "- Troubleshooting P2P network connectivity",
            "- Explaining E2EE encryption concepts",
            "- Wallet and transaction guidance",
            "- Zero ecosystem navigation",
            "",
            "Always be concise, accurate, and pro-privacy.",
        ].join("\n")
    }

    pub fn add_knowledge(&mut self, entry: KnowledgeEntry) {
        self.knowledge_base.push(entry);
    }

    pub fn add_to_history(&mut self, role: &str, content: &str) {
        self.conversation_history.push(ChatMessage {
            role: role.to_string(),
            content: content.to_string(),
        });

        if self.conversation_history.len() > self.max_history {
            self.conversation_history.remove(0);
        }
    }

    pub fn chat(&mut self, user_message: &str) -> AIResponse {
        self.add_to_history("user", user_message);

        let context = self.build_context(user_message);
        let response = self.generate_response(user_message, &context);

        self.add_to_history("assistant", &response);

        AIResponse {
            content: response,
            tokens_used: 0,
            model: "zero-ai-v1".to_string(),
        }
    }

    fn build_context(&self, query: &str) -> String {
        let mut context = String::new();

        let query_lower = query.to_lowercase();

        if query_lower.contains("encrypt") || query_lower.contains("e2ee") || query_lower.contains("encryption") || query_lower.contains("加密") {
            context.push_str("E2EE: Zero uses X3DH key agreement + Double Ratchet (Signal Protocol). Each message has a unique key. Forward secrecy and post-compromise security are guaranteed.\n\n");
        }

        if query_lower.contains("wallet") || query_lower.contains("btc") || query_lower.contains("钱包") || query_lower.contains("转账") {
            context.push_str("Wallet: Zero supports BTC (P2PKH), ETH/BSC (EVM), TRX (TRC-20), SOL (SPL). All derived from a single BIP39/BIP44 seed. Zero-fee P2P transfers between Zero IDs.\n\n");
        }

        if query_lower.contains("p2p") || query_lower.contains("network") || query_lower.contains("网络") || query_lower.contains("node") {
            context.push_str("P2P: libp2p stack with Kademlia DHT for peer discovery, Gossipsub for content distribution, AutoNAT for NAT traversal, and relay service for firewalled peers.\n\n");
        }

        if query_lower.contains("identity") || query_lower.contains("zero id") || query_lower.contains("身份") || query_lower.contains("助记词") {
            context.push_str("Identity: BIP39 12-word mnemonic → Ed25519 keypair → ZeroID (Z prefix + 9 chars). No phone, no email. Fully anonymous.\n\n");
        }

        if query_lower.contains("privacy") || query_lower.contains("隐私") || query_lower.contains("anonymous") || query_lower.contains("匿名") {
            context.push_str("Privacy: Zero collects NO data. No phone/email required. All messages E2EE. P2P network has no central server. IP addresses not logged.\n\n");
        }

        for entry in &self.knowledge_base {
            if entry.title.to_lowercase().contains(&query_lower)
                || query_lower.contains(&entry.title.to_lowercase())
            {
                context.push_str(&format!("{}: {}\n\n", entry.title, entry.content));
            }
        }

        context
    }

    fn generate_response(&self, query: &str, context: &str) -> String {
        let query_lower = query.to_lowercase();

        if query_lower.contains("hello") || query_lower.contains("hi") || query_lower.contains("你好") {
            return "Hello! I'm ZeroAI, your privacy-focused assistant for Zero / 零界. How can I help you navigate the decentralized world today?".to_string();
        }

        if query_lower.contains("what is zero") || query_lower.contains("零界是什么") {
            return "Zero / 零界 is a fully decentralized social network with end-to-end encryption, P2P communication, and a built-in multi-chain crypto wallet. It requires no phone number or email — your identity is a cryptographic key. Think of it as Signal + Mastodon + MetaMask, but fully P2P.".to_string();
        }

        if query_lower.contains("encrypt") || query_lower.contains("e2ee") || query_lower.contains("加密") {
            return format!(
                "Zero's encryption is military-grade:\n\n\
                1. **X3DH Key Agreement** — Establishes a shared secret without any server\n\
                2. **Double Ratchet** — Each message gets a unique encryption key\n\
                3. **Forward Secrecy** — Compromising one key never reveals past messages\n\
                4. **Post-Compromise Security** — Future messages become secure again automatically\n\n\
                This is the same protocol used by Signal.\n\n\
                Context: {}", context
            );
        }

        if query_lower.contains("wallet") || query_lower.contains("钱包") {
            return format!(
                "ZeroPay is your built-in multi-chain wallet:\n\n\
                | Chain | Path |\n\
                |-------|------|\n\
                | BTC | m/44'/0'/0'/0/0 |\n\
                | ETH | m/44'/60'/0'/0/0 |\n\
                | BSC | m/44'/60'/0'/0/0 |\n\
                | TRX | m/44'/195'/0'/0/0 |\n\
                | SOL | m/44'/501'/0'/0' |\n\n\
                All from ONE seed phrase. Zero-fee transfers between Zero IDs.\n\n\
                Context: {}", context
            );
        }

        if !context.is_empty() {
            return format!(
                "Based on Zero's knowledge base:\n\n{}\n\nIs there anything specific you'd like to dive deeper into?",
                context.trim()
            );
        }

        format!(
            "I'm ZeroAI, here to help with Zero / 零界. I can assist with:\n\n\
            - 🔐 **Encryption & Privacy** — How E2EE works in Zero\n\
            - 🌐 **P2P Networking** — How the decentralized network functions\n\
            - 💰 **Multi-chain Wallet** — BTC/ETH/BSC/TRX/SOL management\n\
            - 🆔 **ZeroID & Identity** — Anonymous identity system\n\
            - 🗄️ **DASN Storage** — Decentralized file storage\n\n\
            What would you like to know about?"
        );
    }

    pub fn clear_history(&mut self) {
        self.conversation_history.clear();
    }
}

impl Default for ZeroAIAssistant {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ai_chat_basic() {
        let mut ai = ZeroAIAssistant::new();
        let response = ai.chat("What is Zero?");
        assert!(!response.content.is_empty());
        assert!(response.content.contains("decentralized"));
    }

    #[test]
    fn test_ai_e2ee_question() {
        let mut ai = ZeroAIAssistant::new();
        let response = ai.chat("How does encryption work?");
        assert!(response.content.contains("X3DH"));
        assert!(response.content.contains("Double Ratchet"));
    }

    #[test]
    fn test_ai_wallet_question() {
        let mut ai = ZeroAIAssistant::new();
        let response = ai.chat("What wallets do you support?");
        assert!(response.content.contains("BTC"));
        assert!(response.content.contains("SOL"));
    }

    #[test]
    fn test_ai_history_management() {
        let mut ai = ZeroAIAssistant::new();
        ai.chat("hello");
        ai.chat("what is zero?");
        ai.clear_history();
        ai.chat("hi again");
    }
}