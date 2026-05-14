# ZeroGrid

> **Own Your Digital Life.** — The first fully decentralized super-app protocol.

[![Flutter](https://img.shields.io/badge/Flutter-3.22-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4-0175C2)](https://dart.dev)
[![Rust](https://img.shields.io/badge/Rust-1.x-orange)](https://www.rust-lang.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**ZeroGrid** is not just another messaging app. It combines encrypted messaging, self-custody wallet, P2P marketplace, on-chain identity (ZeroDNS), DAO governance, and cross-chain bridge — all powered by ZERO tokenomics and ZeroNode P2P infrastructure. No central server. No corporate surveillance. Just you and the decentralized grid.

**ZeroGrid 不只是一个聊天软件。** 它是全球首个全栈去中心化超级应用 —— 集加密通讯、自托管钱包、P2P 集市、链上身份（ZeroDNS）、DAO 治理、跨链桥于一体。没有中心服务器，没有企业监控。

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    ZeroGrid App                       │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────────┐  │
│  │ ZeroChat│ │ ZeroPay │ │ZeroStore│ │ZeroMarket │  │
│  └────┬────┘ └────┬────┘ └────┬────┘ └─────┬─────┘  │
│       └───────────┼───────────┼─────────────┘        │
│                   ▼                                   │
│         ┌─────────────────┐                          │
│         │   ZeroID (BIP39) │                          │
│         └────────┬────────┘                          │
├──────────────────┼───────────────────────────────────┤
│                  ▼                                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐              │
│  │ ZeroNode │ │ ZeroDNS  │ │ ZeroDAO  │              │
│  │  P2P Grid│ │ .0g Name │ │Governance│              │
│  └────┬─────┘ └──────────┘ └──────────┘              │
├───────┼──────────────────────────────────────────────┤
│       ▼                                               │
│  ┌─────────────────────────────────────────┐         │
│  │           ZERO Tokenomics                │         │
│  │  Staking · Gas · Burn · Governance       │         │
│  └─────────────────────────────────────────┘         │
│  ┌─────────────────────────────────────────┐         │
│  │         Rust ZeroCore Crypto              │         │
│  │  BIP39 · X3DH · Double Ratchet            │         │
│  └─────────────────────────────────────────┘         │
└──────────────────────────────────────────────────────┘
```

---

## Features

| Module | Description | Status |
|--------|-------------|:------:|
| 🔐 **ZeroGrid Cipher** | Daily crypto word challenge (Wordle-style) | ✅ Live |
| 💬 **ZeroChat** | End-to-end encrypted P2P messaging | ✅ Alpha |
| 👥 **Group Chat** | Encrypted group messaging with @mentions | ✅ Alpha |
| 💰 **ZeroPay** | Multi-chain self-custody wallet | ✅ Alpha |
| 🛒 **ZeroMarket** | P2P decentralized marketplace | ✅ Alpha |
| 🌐 **ZeroDNS** | On-chain identity & domain system (.0g) | ✅ Alpha |
| 🗳️ **ZeroDAO** | Decentralized governance | ✅ Alpha |
| 🌉 **ZeroBridge** | Cross-chain asset bridge | ✅ Alpha |
| 🔗 **ZeroChain** | Application settlement layer | 🔨 Dev |
| 📡 **ZeroNode** | P2P node infrastructure (Kademlia DHT) | 🔨 Dev |
| 🎮 **Games Arcade** | Puzzle, 2048, Snake & more | ✅ Live |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.22 (Dart) |
| Crypto Engine | Rust (wasm-pack → WebAssembly) |
| Encryption | BIP39, X3DH, Double Ratchet |
| P2P Network | Kademlia DHT, STUN/TURN, ICE |
| Identity | BIP39 Mnemonic + W3C DID |
| Token | ZERO — ERC20 / BEP20 / SPL / TRC20 |

---

## Quick Start

```bash
git clone https://github.com/ZeroGridApp/zerogrid.git
cd zerogrid

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Build for web
flutter build web
```

> Requires Flutter 3.22+

---

## Project Structure

```
lib/
├── app.dart                          # App entry point
├── core/
│   ├── constants.dart
│   └── theme/                        # ZeroGrid design system
│       ├── colors.dart               # ZeroColors extension
│       ├── spacing.dart              # ZeroSpacing tokens
│       ├── typography.dart           # ZeroTypography
│       ├── theme_config.dart
│       └── zero_theme.dart           # Locale detection
├── features/
│   ├── ai/                           # AI assistant
│   ├── bridge/                       # Cross-chain bridge
│   ├── chain/                        # ZeroChain explorer
│   ├── changelog/                    # Version history
│   ├── channel/                      # Public channels
│   ├── chat/                         # P2P chat, group chat, BLE
│   ├── dns/                          # ZeroDNS registry
│   ├── games/                        # Arcade + Cipher
│   ├── market/                       # P2P marketplace
│   ├── node/                         # Node deploy, topology, NAT
│   ├── onboarding/                   # Welcome flow + splash
│   ├── search/                       # Global search
│   ├── security/                     # Lock screen
│   ├── settings/                     # Profile & settings
│   ├── status/                       # System health monitor
│   ├── support/                      # FAQ & feedback
│   ├── tokenomics/                   # ZERO economics dashboard
│   └── wallet/                       # Multi-chain wallet
├── services/
│   ├── chat/                         # Chat, group chat services
│   ├── dns/                          # DNS resolution
│   ├── games/                        # Cipher service
│   ├── node/                         # Node discovery, relay
│   ├── tokenomics/                   # ZERO economics
│   └── wallet/                       # Transaction history
└── shared/
    └── models/                       # Shared data models

rust/                                  # Rust ZeroCore crypto engine
deploy/                                # Docker & VPS deployment guides
```

---

## Documentation

- [Economic Model](docs/ZERO_ECONOMIC_MODEL.md) — ZERO tokenomics deep dive
- [Ecosystem Overview](docs/ZERO_ECOSYSTEM.md) — Full ecosystem roadmap
- [Marketing Plan](docs/ZERO_MARKETING_PLAN.md) — Go-to-market strategy
- [VPS Deployment Guide](https://github.com/ZeroGridApp/zerogrid/blob/main/deploy/VPS_GUIDE.md) — Node deployment
- [Docker Compose](https://github.com/ZeroGridApp/zerogrid/blob/main/deploy/docker-compose.yml) — One-click deploy

---

## Roadmap

- [x] v0.1 — Core Flutter app + wallet + chat
- [x] v0.2 — P2P marketplace + ZeroDNS
- [x] v0.3 — ZeroDAO governance + ZeroBridge
- [x] v0.4 — Games Arcade + group chat + search
- [x] v0.5 — Rust crypto engine + ZeroNode infrastructure
- [x] v0.6 — Tokenomics dashboard + developer tools + **ZeroGrid Cipher**
- [ ] v0.7 — Cipher leaderboard + ZERO rewards
- [ ] v0.8 — ZeroNode testnet (100+ nodes)
- [ ] v0.9 — Mobile app (iOS/Android)
- [ ] v1.0 — Mainnet launch

---

## Links

- 🌐 Website: [zerogrid.xyz](https://zerogrid.xyz)
- 🐦 Twitter: [@ZeroGridApp](https://twitter.com/ZeroGridApp)

---

## License

MIT © ZeroGrid Protocol