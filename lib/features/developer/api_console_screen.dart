import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_card.dart';

class _ApiParam {
  final String name;
  final String type;
  final bool required;
  final String descEn;
  final String descZh;

  const _ApiParam({
    required this.name,
    required this.type,
    required this.required,
    required this.descEn,
    required this.descZh,
  });

  String desc(bool isZh) => isZh ? descZh : descEn;
}

enum _HttpMethod { get, post, ws }

extension _HttpMethodX on _HttpMethod {
  String get label {
    switch (this) {
      case _HttpMethod.get:
        return 'GET';
      case _HttpMethod.post:
        return 'POST';
      case _HttpMethod.ws:
        return 'WS';
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case _HttpMethod.get:
        return context.zSuccess;
      case _HttpMethod.post:
        return context.zAccent;
      case _HttpMethod.ws:
        return const Color(0xFF9B7BC0);
    }
  }
}

class _ApiEndpoint {
  final _HttpMethod method;
  final String path;
  final String descEn;
  final String descZh;
  final bool requiresAuth;
  final List<_ApiParam> params;
  final String exampleRequest;
  final String exampleResponse;
  final String Function(Map<String, String>? bodyParams)? mockResponseBuilder;

  const _ApiEndpoint({
    required this.method,
    required this.path,
    required this.descEn,
    required this.descZh,
    required this.requiresAuth,
    this.params = const [],
    required this.exampleRequest,
    required this.exampleResponse,
    this.mockResponseBuilder,
  });

  String desc(bool isZh) => isZh ? descZh : descEn;
}

class _ApiCategory {
  final String nameEn;
  final String nameZh;
  final IconData icon;
  final List<_ApiEndpoint> endpoints;

  const _ApiCategory({
    required this.nameEn,
    required this.nameZh,
    required this.icon,
    required this.endpoints,
  });

  String name(bool isZh) => isZh ? nameZh : nameEn;
}

final List<_ApiCategory> _categories = [
  _ApiCategory(
    nameEn: 'Identity',
    nameZh: '身份',
    icon: Icons.fingerprint,
    endpoints: [
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/identity/{did}',
        descEn: 'Retrieve a ZeroID profile by its decentralized identifier. Returns the public profile including nickname, avatar CID, and verified social links.',
        descZh: '通过去中心化标识符获取 ZeroID 个人资料。返回公开资料，包括昵称、头像 CID 和已验证的社交链接。',
        requiresAuth: false,
        params: [
          _ApiParam(name: 'did', type: 'string', required: true, descEn: 'Decentralized Identifier (e.g. did:zero:0x...)', descZh: '去中心化标识符（例如 did:zero:0x...）'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/identity/did:zero:0x7a3b...c91f\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "did": "did:zero:0x7a3b...c91f",\n'
            '  "nickname": "alice.zero",\n'
            '  "avatar": "bafkreia...x3q",\n'
            '  "bio": "Zero Protocol contributor",\n'
            '  "verified_socials": [\n'
            '    { "platform": "twitter", "handle": "@alice_zero" },\n'
            '    { "platform": "github", "handle": "alice-dev" }\n'
            '  ],\n'
            '  "created_at": "2025-01-15T08:30:00Z",\n'
            '  "updated_at": "2026-05-10T14:22:00Z"\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'did': 'did:zero:0x7a3b8e2d1c6f4a9b8d2e1c6f4a9b8d2e1c6f4a9b',
          'nickname': 'alice.zero',
          'avatar': 'bafkreia4x3q2l7n5m8p9k1j6h4f3d2s1a0z9x8c7v6b5n',
          'bio': 'Zero Protocol builder & privacy advocate',
          'verified_socials': [
            {'platform': 'twitter', 'handle': '@alice_zero'},
            {'platform': 'github', 'handle': 'alice-dev'},
          ],
          'created_at': '2025-01-15T08:30:00Z',
          'updated_at': '2026-05-10T14:22:00Z',
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.post,
        path: '/api/v1/identity/verify',
        descEn: 'Verify a cryptographic signature made by a ZeroID holder. Used to authenticate users without revealing private keys.',
        descZh: '验证 ZeroID 持有者的加密签名。用于在无需泄露私钥的情况下认证用户。',
        requiresAuth: false,
        params: [
          _ApiParam(name: 'did', type: 'string', required: true, descEn: 'ZeroID to verify against', descZh: '要验证的 ZeroID'),
          _ApiParam(name: 'message', type: 'string', required: true, descEn: 'Original message that was signed', descZh: '被签名的原始消息'),
          _ApiParam(name: 'signature', type: 'string', required: true, descEn: 'Ed25519 signature (hex-encoded)', descZh: 'Ed25519 签名（十六进制编码）'),
        ],
        exampleRequest:
            "curl -X POST \"https://api.zero.network/api/v1/identity/verify\" \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\n    \"did\": \"did:zero:0x7a3b...c91f\",\n    \"message\": \"Login to ZeroApp at 2026-05-15T10:00:00Z\",\n    \"signature\": \"0xf8a2b4...e3d1\"\n  }'",
        exampleResponse:
            '{\n'
            '  "valid": true,\n'
            '  "did": "did:zero:0x7a3b...c91f",\n'
            '  "verified_at": "2026-05-15T10:00:01Z"\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'valid': true,
          'did': bodyParams?['did'] ?? 'did:zero:0x7a3b8e2d1c6f4a9b',
          'verified_at': '2026-05-15T10:00:01Z',
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/identity/{did}/contacts',
        descEn: 'List contacts associated with a ZeroID. Each contact is identified by their DID and includes a trust level indicator.',
        descZh: '列出与 ZeroID 关联的联系人。每个联系人通过其 DID 标识，并包含信任级别指示器。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'did', type: 'string', required: true, descEn: 'ZeroID to query contacts for', descZh: '要查询联系人的 ZeroID'),
          _ApiParam(name: 'page', type: 'integer', required: false, descEn: 'Page number (default: 1)', descZh: '页码（默认：1）'),
          _ApiParam(name: 'limit', type: 'integer', required: false, descEn: 'Results per page (default: 20)', descZh: '每页结果数（默认：20）'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/identity/did:zero:0x7a3b...c91f/contacts?limit=5\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "contacts": [\n'
            '    { "did": "did:zero:0xb2c4...d8e1", "nickname": "bob.zero", "trust_level": "verified" },\n'
            '    { "did": "did:zero:0xc5d7...f2a3", "nickname": "carol.zero", "trust_level": "mutual" },\n'
            '    { "did": "did:zero:0xd8e9...g4b5", "nickname": "dave.zero", "trust_level": "pending" }\n'
            '  ],\n'
            '  "total": 42,\n'
            '  "page": 1,\n'
            '  "limit": 5\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'contacts': [
            {'did': 'did:zero:0xb2c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2', 'nickname': 'bob.zero', 'trust_level': 'verified'},
            {'did': 'did:zero:0xc5d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5', 'nickname': 'carol.zero', 'trust_level': 'mutual'},
            {'did': 'did:zero:0xd8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7', 'nickname': 'dave.zero', 'trust_level': 'pending'},
            {'did': 'did:zero:0xe0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9', 'nickname': 'eve.zero', 'trust_level': 'verified'},
            {'did': 'did:zero:0xf1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0', 'nickname': 'frank.zero', 'trust_level': 'mutual'},
          ],
          'total': 42,
          'page': 1,
          'limit': 5,
        }),
      ),
    ],
  ),
  _ApiCategory(
    nameEn: 'Messaging',
    nameZh: '消息',
    icon: Icons.chat_bubble_outline,
    endpoints: [
      _ApiEndpoint(
        method: _HttpMethod.post,
        path: '/api/v1/messages/send',
        descEn: 'Send an end-to-end encrypted message to a recipient. The message body is encrypted with the Double Ratchet algorithm before transmission.',
        descZh: '向接收者发送端到端加密消息。消息体在传输前使用双棘轮算法加密。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'sender_did', type: 'string', required: true, descEn: 'Sender ZeroID', descZh: '发送者 ZeroID'),
          _ApiParam(name: 'recipient_did', type: 'string', required: true, descEn: 'Recipient ZeroID', descZh: '接收者 ZeroID'),
          _ApiParam(name: 'ciphertext', type: 'string', required: true, descEn: 'Encrypted message (base64)', descZh: '加密消息（base64）'),
          _ApiParam(name: 'thread_id', type: 'string', required: false, descEn: 'Existing thread ID for replies', descZh: '回复用的现有会话 ID'),
        ],
        exampleRequest:
            "curl -X POST \"https://api.zero.network/api/v1/messages/send\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\n    \"sender_did\": \"did:zero:0x7a3b...c91f\",\n    \"recipient_did\": \"did:zero:0xb2c4...d8e1\",\n    \"ciphertext\": \"dGhpcyBpcyBhbiBlbmNyeXB0ZWQgbWVzc2FnZQ==\"\n  }'",
        exampleResponse:
            '{\n'
            '  "message_id": "msg_4f8a2b1c3d4e5f6a7b8c9d0e1f2a3b4c",\n'
            '  "thread_id": "thr_9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d",\n'
            '  "timestamp": "2026-05-15T10:30:00Z",\n'
            '  "status": "queued"\n'
            '}',
        mockResponseBuilder: (bodyParams) {
          final msgId = 'msg_${_randomHex(32)}';
          final threadId = bodyParams?['thread_id'] ?? 'thr_${_randomHex(32)}';
          return _prettyPrint({
            'message_id': msgId,
            'thread_id': threadId,
            'timestamp': '2026-05-15T10:30:00Z',
            'status': 'queued',
          });
        },
      ),
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/messages/{threadId}',
        descEn: 'Retrieve all messages in a conversation thread. Messages are returned in chronological order with decryption metadata.',
        descZh: '获取对话线程中的所有消息。消息按时间顺序返回，附带解密元数据。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'threadId', type: 'string', required: true, descEn: 'Thread identifier', descZh: '会话标识符'),
          _ApiParam(name: 'before', type: 'string', required: false, descEn: 'Cursor for pagination (ISO timestamp)', descZh: '分页游标（ISO 时间戳）'),
          _ApiParam(name: 'limit', type: 'integer', required: false, descEn: 'Max messages to return (default: 50)', descZh: '最大返回消息数（默认：50）'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/messages/thr_9a8b...c4d?limit=10\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "thread_id": "thr_9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d",\n'
            '  "participants": ["did:zero:0x7a3b...c91f", "did:zero:0xb2c4...d8e1"],\n'
            '  "messages": [\n'
            '    { "id": "msg_001", "sender": "did:zero:0xb2c4...d8e1", "ciphertext": "...", "timestamp": "2026-05-15T10:28:00Z" },\n'
            '    { "id": "msg_002", "sender": "did:zero:0x7a3b...c91f", "ciphertext": "...", "timestamp": "2026-05-15T10:29:00Z" }\n'
            '  ],\n'
            '  "has_more": true\n'
            '}',
      ),
      _ApiEndpoint(
        method: _HttpMethod.ws,
        path: '/api/v1/messages/stream',
        descEn: 'Open a WebSocket connection to receive real-time messages. Supports multiplexed streams for multiple conversations.',
        descZh: '打开 WebSocket 连接以接收实时消息。支持多路复用流以处理多个对话。',
        requiresAuth: true,
        params: [],
        exampleRequest:
            "wscat -c \"wss://api.zero.network/api/v1/messages/stream\" \\\n  -H \"Authorization: Bearer <token>\"\n\n# Incoming frames:\n# > { \"type\": \"message\", \"thread_id\": \"...\", \"sender\": \"...\", \"ciphertext\": \"...\" }\n# > { \"type\": \"typing\", \"thread_id\": \"...\", \"sender\": \"...\" }\n# > { \"type\": \"receipt\", \"message_id\": \"...\", \"status\": \"delivered\" }",
        exampleResponse:
            '// WebSocket frames (text)\n'
            '{ "type": "message", "thread_id": "thr_9a8b7c...c4d", "sender": "did:zero:0xb2c4...d8e1", "ciphertext": "...", "timestamp": "2026-05-15T10:30:00Z" }\n'
            '{ "type": "receipt", "message_id": "msg_4f8a...b4c", "status": "delivered" }',
      ),
    ],
  ),
  _ApiCategory(
    nameEn: 'Wallet',
    nameZh: '钱包',
    icon: Icons.account_balance_wallet_outlined,
    endpoints: [
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/wallet/balance/{address}',
        descEn: 'Get multi-chain wallet balance for a given address. Returns balances across BTC, ETH, BSC, TRX, and SOL chains.',
        descZh: '获取给定地址的多链钱包余额。返回 BTC、ETH、BSC、TRX 和 SOL 链上的余额。',
        requiresAuth: false,
        params: [
          _ApiParam(name: 'address', type: 'string', required: true, descEn: 'Wallet address (any supported chain)', descZh: '钱包地址（任意支持的链）'),
          _ApiParam(name: 'chains', type: 'string', required: false, descEn: 'Comma-separated chain list (default: all)', descZh: '逗号分隔的链列表（默认：全部）'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/wallet/balance/0x7a3b8e2d1c6f4a9b?chains=BTC,ETH\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "address": "0x7a3b8e2d1c6f4a9b",\n'
            '  "balances": {\n'
            '    "BTC": { "amount": "0.12500000", "usd_value": "8125.00" },\n'
            '    "ETH": { "amount": "3.45000000", "usd_value": "11385.00" },\n'
            '    "BSC": { "amount": "12.50000000", "usd_value": "3787.50" },\n'
            '    "TRX": { "amount": "15000.000000", "usd_value": "1650.00" },\n'
            '    "SOL": { "amount": "85.20000000", "usd_value": "12780.00" }\n'
            '  },\n'
            '  "total_usd_value": "37727.50"\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'address': bodyParams?['address'] ?? '0x7a3b8e2d1c6f4a9b',
          'balances': {
            'BTC': {'amount': '0.12500000', 'usd_value': '8125.00'},
            'ETH': {'amount': '3.45000000', 'usd_value': '11385.00'},
            'BSC': {'amount': '12.50000000', 'usd_value': '3787.50'},
            'TRX': {'amount': '15000.000000', 'usd_value': '1650.00'},
            'SOL': {'amount': '85.20000000', 'usd_value': '12780.00'},
          },
          'total_usd_value': '37727.50',
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.post,
        path: '/api/v1/wallet/transfer',
        descEn: 'Initiate a token transfer on any supported chain. Requires wallet signature for authorization.',
        descZh: '在任意支持的链上发起代币转账。需要钱包签名进行授权。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'from', type: 'string', required: true, descEn: 'Sender address', descZh: '发送者地址'),
          _ApiParam(name: 'to', type: 'string', required: true, descEn: 'Recipient address', descZh: '接收者地址'),
          _ApiParam(name: 'amount', type: 'string', required: true, descEn: 'Amount in token units', descZh: '代币数量'),
          _ApiParam(name: 'chain', type: 'string', required: true, descEn: 'Chain ID (BTC/ETH/BSC/TRX/SOL)', descZh: '链 ID（BTC/ETH/BSC/TRX/SOL）'),
          _ApiParam(name: 'token', type: 'string', required: false, descEn: 'Token contract address (native if omitted)', descZh: '代币合约地址（省略则为原生币）'),
        ],
        exampleRequest:
            "curl -X POST \"https://api.zero.network/api/v1/wallet/transfer\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\n    \"from\": \"0x7a3b8e2d1c6f4a9b\",\n    \"to\": \"0xb2c4d5e6f7a8b9c0\",\n    \"amount\": \"0.5\",\n    \"chain\": \"ETH\"\n  }'",
        exampleResponse:
            '{\n'
            '  "tx_hash": "0x9f8a2b1c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0",\n'
            '  "from": "0x7a3b8e2d1c6f4a9b",\n'
            '  "to": "0xb2c4d5e6f7a8b9c0",\n'
            '  "amount": "0.5",\n'
            '  "chain": "ETH",\n'
            '  "status": "pending",\n'
            '  "estimated_fee": "0.0021",\n'
            '  "created_at": "2026-05-15T10:35:00Z"\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'tx_hash': '0x${_randomHex(64)}',
          'from': bodyParams?['from'] ?? '0x7a3b8e2d1c6f4a9b',
          'to': bodyParams?['to'] ?? '0xb2c4d5e6f7a8b9c0',
          'amount': bodyParams?['amount'] ?? '0.5',
          'chain': bodyParams?['chain'] ?? 'ETH',
          'status': 'pending',
          'estimated_fee': '0.0021',
          'created_at': '2026-05-15T10:35:00Z',
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/wallet/transactions',
        descEn: 'Retrieve transaction history for a wallet address. Supports filtering by chain, date range, and transaction type.',
        descZh: '获取钱包地址的交易历史。支持按链、日期范围和交易类型过滤。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'address', type: 'string', required: true, descEn: 'Wallet address', descZh: '钱包地址'),
          _ApiParam(name: 'chain', type: 'string', required: false, descEn: 'Filter by chain', descZh: '按链过滤'),
          _ApiParam(name: 'type', type: 'string', required: false, descEn: 'Transaction type (send/receive/swap)', descZh: '交易类型（send/receive/swap）'),
          _ApiParam(name: 'page', type: 'integer', required: false, descEn: 'Page number', descZh: '页码'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/wallet/transactions?address=0x7a3b...a9b&chain=ETH&limit=3\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "transactions": [\n'
            '    { "tx_hash": "0x9f8a...9f0", "type": "send", "amount": "0.5", "chain": "ETH", "timestamp": "2026-05-15T10:35:00Z", "status": "confirmed" },\n'
            '    { "tx_hash": "0x8e7b...8e0", "type": "receive", "amount": "2.0", "chain": "ETH", "timestamp": "2026-05-14T18:20:00Z", "status": "confirmed" },\n'
            '    { "tx_hash": "0x7d6a...7d0", "type": "swap", "amount": "1.0", "chain": "ETH", "timestamp": "2026-05-13T09:15:00Z", "status": "confirmed" }\n'
            '  ],\n'
            '  "total": 156,\n'
            '  "page": 1\n'
            '}',
      ),
    ],
  ),
  _ApiCategory(
    nameEn: 'Storage',
    nameZh: '存储',
    icon: Icons.cloud_outlined,
    endpoints: [
      _ApiEndpoint(
        method: _HttpMethod.post,
        path: '/api/v1/storage/upload',
        descEn: 'Upload a file encrypted with AES-256-GCM to the DASN (Decentralized Anonymous Storage Network). Returns a content identifier (CID).',
        descZh: '将通过 AES-256-GCM 加密的文件上传到 DASN（去中心化匿名存储网络）。返回内容标识符（CID）。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'file', type: 'binary', required: true, descEn: 'Encrypted file data (multipart/form-data)', descZh: '加密文件数据（multipart/form-data）'),
          _ApiParam(name: 'encryption_key_fingerprint', type: 'string', required: true, descEn: 'SHA-256 fingerprint of the encryption key', descZh: '加密密钥的 SHA-256 指纹'),
          _ApiParam(name: 'ttl_days', type: 'integer', required: false, descEn: 'Time-to-live in days (default: 90)', descZh: '存活天数（默认：90）'),
        ],
        exampleRequest:
            "curl -X POST \"https://api.zero.network/api/v1/storage/upload\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -F \"file=@document.enc\" \\\n  -F \"encryption_key_fingerprint=sha256:a1b2c3...\" \\\n  -F \"ttl_days=30\"",
        exampleResponse:
            '{\n'
            '  "cid": "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",\n'
            '  "size_bytes": 1048576,\n'
            '  "mime_type": "application/octet-stream",\n'
            '  "created_at": "2026-05-15T10:40:00Z",\n'
            '  "expires_at": "2026-06-14T10:40:00Z",\n'
            '  "replication_count": 7\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'cid': 'bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi',
          'size_bytes': 1048576,
          'mime_type': 'application/octet-stream',
          'created_at': '2026-05-15T10:40:00Z',
          'expires_at': '2026-06-14T10:40:00Z',
          'replication_count': 7,
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/storage/{cid}',
        descEn: 'Retrieve an encrypted file from DASN by its content identifier. The file must be decrypted client-side with the corresponding key.',
        descZh: '通过内容标识符从 DASN 获取加密文件。文件必须在客户端使用相应密钥解密。',
        requiresAuth: false,
        params: [
          _ApiParam(name: 'cid', type: 'string', required: true, descEn: 'Content Identifier (CIDv1)', descZh: '内容标识符（CIDv1）'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/storage/bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi\" \\\n  -o retrieved.enc \\\n  -H \"Accept: application/octet-stream\"",
        exampleResponse:
            '// Binary response: encrypted file content\n'
            '// Content-Type: application/octet-stream\n'
            '// X-CID: bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi\n'
            '// X-Encryption-Fingerprint: sha256:a1b2c3...\n'
            '// X-Expires-At: 2026-06-14T10:40:00Z\n'
            '// (binary data)',
      ),
      _ApiEndpoint(
        method: _HttpMethod.post,
        path: '/api/v1/storage/share',
        descEn: 'Generate a time-limited share link for an encrypted file. The link includes an ephemeral decryption key and expires after the specified duration.',
        descZh: '为加密文件生成限时分享链接。链接包含临时解密密钥，在指定时长后过期。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'cid', type: 'string', required: true, descEn: 'Content Identifier to share', descZh: '要分享的内容标识符'),
          _ApiParam(name: 'expires_in_hours', type: 'integer', required: true, descEn: 'Link validity in hours (max: 168)', descZh: '链接有效期（小时，最大：168）'),
          _ApiParam(name: 'max_downloads', type: 'integer', required: false, descEn: 'Maximum download count', descZh: '最大下载次数'),
        ],
        exampleRequest:
            "curl -X POST \"https://api.zero.network/api/v1/storage/share\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\n    \"cid\": \"bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi\",\n    \"expires_in_hours\": 24,\n    \"max_downloads\": 5\n  }'",
        exampleResponse:
            '{\n'
            '  "share_url": "https://zero.link/s/bafybeig-j8k2l9m3n4o5p6q7r8s9t0u1v2w3x4y5z6",\n'
            '  "cid": "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",\n'
            '  "expires_at": "2026-05-16T10:40:00Z",\n'
            '  "max_downloads": 5,\n'
            '  "downloads_remaining": 5\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'share_url': 'https://zero.link/s/bafybeig-j8k2l9m3n4o5p6q7r8s9t0u1v2w3x4y5z6',
          'cid': bodyParams?['cid'] ?? 'bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi',
          'expires_at': '2026-05-16T10:40:00Z',
          'max_downloads': bodyParams?['max_downloads'] != null ? int.tryParse(bodyParams!['max_downloads']!) : 5,
          'downloads_remaining': bodyParams?['max_downloads'] != null ? int.tryParse(bodyParams!['max_downloads']!) : 5,
        }),
      ),
    ],
  ),
  _ApiCategory(
    nameEn: 'ZeroDNS',
    nameZh: 'ZeroDNS',
    icon: Icons.dns_outlined,
    endpoints: [
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/dns/resolve/{name}.zero',
        descEn: 'Resolve a .zero domain to its associated ZeroID, wallet addresses, and DASN content records.',
        descZh: '将 .zero 域名解析为其关联的 ZeroID、钱包地址和 DASN 内容记录。',
        requiresAuth: false,
        params: [
          _ApiParam(name: 'name', type: 'string', required: true, descEn: 'Domain name without .zero suffix', descZh: '域名（不含 .zero 后缀）'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/dns/resolve/alice.zero\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "name": "alice.zero",\n'
            '  "owner_did": "did:zero:0x7a3b8e2d1c6f4a9b",\n'
            '  "records": {\n'
            '    "BTC": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",\n'
            '    "ETH": "0x7a3b8e2d1c6f4a9b",\n'
            '    "SOL": "7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV"\n'
            '  },\n'
            '  "content_cid": "bafkreia...x3q",\n'
            '  "registered_at": "2025-03-01T00:00:00Z",\n'
            '  "expires_at": "2027-03-01T00:00:00Z"\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'name': 'alice.zero',
          'owner_did': 'did:zero:0x7a3b8e2d1c6f4a9b',
          'records': {
            'BTC': '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
            'ETH': '0x7a3b8e2d1c6f4a9b',
            'SOL': '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
          },
          'content_cid': 'bafkreia4x3q2l7n5m8p9k1j6h4f3d2s1a0z9x8c7v6b5n',
          'registered_at': '2025-03-01T00:00:00Z',
          'expires_at': '2027-03-01T00:00:00Z',
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.post,
        path: '/api/v1/dns/register',
        descEn: 'Register a new .zero domain. Domains are allocated via a Vickrey auction mechanism. The registration fee is burned to reduce ZERO token supply.',
        descZh: '注册新的 .zero 域名。域名通过维克里拍卖机制分配。注册费将被销毁以减少 ZERO 代币供应量。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'name', type: 'string', required: true, descEn: 'Desired domain name (alphanumeric, 3-63 chars)', descZh: '想要的域名（字母数字，3-63 个字符）'),
          _ApiParam(name: 'owner_did', type: 'string', required: true, descEn: 'Owner ZeroID', descZh: '所有者 ZeroID'),
          _ApiParam(name: 'bid_amount', type: 'string', required: true, descEn: 'Bid amount in ZERO tokens', descZh: '出价金额（ZERO 代币）'),
          _ApiParam(name: 'duration_years', type: 'integer', required: true, descEn: 'Registration duration (1-10 years)', descZh: '注册年限（1-10 年）'),
        ],
        exampleRequest:
            "curl -X POST \"https://api.zero.network/api/v1/dns/register\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\n    \"name\": \"myproject\",\n    \"owner_did\": \"did:zero:0x7a3b...c91f\",\n    \"bid_amount\": \"100\",\n    \"duration_years\": 2\n  }'",
        exampleResponse:
            '{\n'
            '  "name": "myproject.zero",\n'
            '  "status": "auction_pending",\n'
            '  "auction_id": "auc_8f7e6d5c4b3a2918",\n'
            '  "bid_amount": "100",\n'
            '  "auction_end": "2026-05-22T10:40:00Z"\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'name': '${bodyParams?['name'] ?? 'myproject'}.zero',
          'status': 'auction_pending',
          'auction_id': 'auc_${_randomHex(16)}',
          'bid_amount': bodyParams?['bid_amount'] ?? '100',
          'auction_end': '2026-05-22T10:40:00Z',
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/dns/auctions',
        descEn: 'List all active .zero domain auctions. Each auction includes the current highest bid, bidder DID, and time remaining.',
        descZh: '列出所有活跃的 .zero 域名拍卖。每个拍卖包含当前最高出价、出价者 DID 和剩余时间。',
        requiresAuth: false,
        params: [
          _ApiParam(name: 'status', type: 'string', required: false, descEn: 'Filter: active/ending/closing (default: active)', descZh: '过滤：active/ending/closing（默认：active）'),
          _ApiParam(name: 'sort', type: 'string', required: false, descEn: 'Sort: name/bid/ending (default: ending)', descZh: '排序：name/bid/ending（默认：ending）'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/dns/auctions?status=active&sort=ending\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "auctions": [\n'
            '    { "name": "defi.zero", "highest_bid": "500", "bidder_did": "did:zero:0x...", "ends_at": "2026-05-16T12:00:00Z" },\n'
            '    { "name": "nft.zero", "highest_bid": "1200", "bidder_did": "did:zero:0x...", "ends_at": "2026-05-17T08:30:00Z" },\n'
            '    { "name": "dao.zero", "highest_bid": "850", "bidder_did": "did:zero:0x...", "ends_at": "2026-05-18T20:15:00Z" }\n'
            '  ],\n'
            '  "total": 47\n'
            '}',
      ),
    ],
  ),
  _ApiCategory(
    nameEn: 'DAO',
    nameZh: 'DAO',
    icon: Icons.how_to_vote_outlined,
    endpoints: [
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/dao/proposals',
        descEn: 'List governance proposals for the Zero Protocol DAO. Proposals include parameter changes, treasury allocations, and protocol upgrades.',
        descZh: '列出 Zero Protocol DAO 的治理提案。提案包括参数变更、资金分配和协议升级。',
        requiresAuth: false,
        params: [
          _ApiParam(name: 'status', type: 'string', required: false, descEn: 'Filter: active/passed/rejected/executed', descZh: '过滤：active/passed/rejected/executed'),
          _ApiParam(name: 'category', type: 'string', required: false, descEn: 'Category: parameter/treasury/upgrade', descZh: '类别：parameter/treasury/upgrade'),
          _ApiParam(name: 'page', type: 'integer', required: false, descEn: 'Page number', descZh: '页码'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/dao/proposals?status=active&category=treasury\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "proposals": [\n'
            '    { "id": "prop_042", "title": "ZIP-42: Increase validator rewards", "category": "parameter", "status": "active", "votes_for": "1.2M", "votes_against": "340K", "ends_at": "2026-05-20T00:00:00Z" },\n'
            '    { "id": "prop_043", "title": "ZIP-43: Community grant program", "category": "treasury", "status": "active", "votes_for": "890K", "votes_against": "120K", "ends_at": "2026-05-25T00:00:00Z" }\n'
            '  ],\n'
            '  "total": 43\n'
            '}',
      ),
      _ApiEndpoint(
        method: _HttpMethod.post,
        path: '/api/v1/dao/vote',
        descEn: 'Cast a vote on a DAO proposal. Voting power is proportional to staked ZERO tokens and delegation assignments.',
        descZh: '对 DAO 提案进行投票。投票权与质押的 ZERO 代币数量和委托分配成正比。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'proposal_id', type: 'string', required: true, descEn: 'Proposal identifier', descZh: '提案标识符'),
          _ApiParam(name: 'voter_did', type: 'string', required: true, descEn: 'Voter ZeroID', descZh: '投票者 ZeroID'),
          _ApiParam(name: 'choice', type: 'string', required: true, descEn: 'Vote choice: for/against/abstain', descZh: '投票选择：for/against/abstain'),
          _ApiParam(name: 'voting_power', type: 'string', required: false, descEn: 'Override voting power (auto-calculated if omitted)', descZh: '覆盖投票权重（省略则自动计算）'),
        ],
        exampleRequest:
            "curl -X POST \"https://api.zero.network/api/v1/dao/vote\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\n    \"proposal_id\": \"prop_042\",\n    \"voter_did\": \"did:zero:0x7a3b...c91f\",\n    \"choice\": \"for\"\n  }'",
        exampleResponse:
            '{\n'
            '  "vote_id": "vote_a1b2c3d4e5f6a7b8",\n'
            '  "proposal_id": "prop_042",\n'
            '  "voter_did": "did:zero:0x7a3b...c91f",\n'
            '  "choice": "for",\n'
            '  "voting_power": "25000",\n'
            '  "timestamp": "2026-05-15T11:00:00Z"\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'vote_id': 'vote_${_randomHex(16)}',
          'proposal_id': bodyParams?['proposal_id'] ?? 'prop_042',
          'voter_did': bodyParams?['voter_did'] ?? 'did:zero:0x7a3b8e2d1c6f4a9b',
          'choice': bodyParams?['choice'] ?? 'for',
          'voting_power': '25000',
          'timestamp': '2026-05-15T11:00:00Z',
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/dao/treasury',
        descEn: 'Get the current state of the DAO treasury, including multi-chain asset holdings, staking rewards pool, and grant allocations.',
        descZh: '获取 DAO 财库的当前状态，包括多链资产持有量、质押奖励池和拨款分配。',
        requiresAuth: false,
        params: [],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/dao/treasury\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "total_usd_value": "12,450,000",\n'
            '  "assets": {\n'
            '    "ZERO": { "amount": "5,000,000", "usd_value": "2,500,000" },\n'
            '    "ETH": { "amount": "850", "usd_value": "2,805,000" },\n'
            '    "USDC": { "amount": "3,200,000", "usd_value": "3,200,000" },\n'
            '    "BTC": { "amount": "42.5", "usd_value": "2,762,500" }\n'
            '  },\n'
            '  "staking_rewards_pool": "1,200,000 ZERO",\n'
            '  "grant_budget_remaining": "500,000 USDC",\n'
            '  "monthly_burn_amount": "25,000 ZERO"\n'
            '}',
      ),
    ],
  ),
  _ApiCategory(
    nameEn: 'Bridge',
    nameZh: '跨链桥',
    icon: Icons.swap_horiz,
    endpoints: [
      _ApiEndpoint(
        method: _HttpMethod.post,
        path: '/api/v1/bridge/lock',
        descEn: 'Lock tokens on the source chain to initiate a cross-chain bridge transfer. Tokens are locked in the bridge contract and minted on the destination chain.',
        descZh: '在源链上锁定代币以发起跨链桥转账。代币在桥合约中锁定，并在目标链上铸造。',
        requiresAuth: true,
        params: [
          _ApiParam(name: 'from_chain', type: 'string', required: true, descEn: 'Source chain ID', descZh: '源链 ID'),
          _ApiParam(name: 'to_chain', type: 'string', required: true, descEn: 'Destination chain ID', descZh: '目标链 ID'),
          _ApiParam(name: 'token', type: 'string', required: true, descEn: 'Token address (or native)', descZh: '代币地址（或原生币）'),
          _ApiParam(name: 'amount', type: 'string', required: true, descEn: 'Amount to bridge', descZh: '跨链金额'),
          _ApiParam(name: 'recipient', type: 'string', required: true, descEn: 'Recipient address on destination chain', descZh: '目标链上的接收地址'),
        ],
        exampleRequest:
            "curl -X POST \"https://api.zero.network/api/v1/bridge/lock\" \\\n  -H \"Authorization: Bearer <token>\" \\\n  -H \"Content-Type: application/json\" \\\n  -d '{\n    \"from_chain\": \"ETH\",\n    \"to_chain\": \"BSC\",\n    \"token\": \"native\",\n    \"amount\": \"1.5\",\n    \"recipient\": \"0xb2c4d5e6f7a8b9c0\"\n  }'",
        exampleResponse:
            '{\n'
            '  "bridge_tx_hash": "0x${_randomHex(64)}",\n'
            '  "from_chain": "ETH",\n'
            '  "to_chain": "BSC",\n'
            '  "token": "native",\n'
            '  "amount": "1.5",\n'
            '  "status": "locking",\n'
            '  "estimated_completion": "2026-05-15T11:05:00Z"\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'bridge_tx_hash': '0x${_randomHex(64)}',
          'from_chain': bodyParams?['from_chain'] ?? 'ETH',
          'to_chain': bodyParams?['to_chain'] ?? 'BSC',
          'token': bodyParams?['token'] ?? 'native',
          'amount': bodyParams?['amount'] ?? '1.5',
          'status': 'locking',
          'estimated_completion': '2026-05-15T11:05:00Z',
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/bridge/status/{txHash}',
        descEn: 'Check the status of a cross-chain bridge transaction. Tracks the lifecycle from locking through confirmation to minting.',
        descZh: '查询跨链桥交易的状态。追踪从锁定到确认再到铸造的整个生命周期。',
        requiresAuth: false,
        params: [
          _ApiParam(name: 'txHash', type: 'string', required: true, descEn: 'Bridge transaction hash', descZh: '桥交易哈希'),
        ],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/bridge/status/0x9f8a...9f0\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "tx_hash": "0x9f8a2b1c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0",\n'
            '  "status": "completed",\n'
            '  "steps": [\n'
            '    { "step": "lock_confirmed", "chain": "ETH", "confirmations": 12, "timestamp": "2026-05-15T10:35:00Z" },\n'
            '    { "step": "relay_validated", "timestamp": "2026-05-15T10:36:00Z" },\n'
            '    { "step": "mint_confirmed", "chain": "BSC", "confirmations": 8, "timestamp": "2026-05-15T10:38:00Z" }\n'
            '  ]\n'
            '}',
        mockResponseBuilder: (bodyParams) => _prettyPrint({
          'tx_hash': bodyParams?['txHash'] ?? '0x${_randomHex(64)}',
          'status': 'completed',
          'steps': [
            {'step': 'lock_confirmed', 'chain': 'ETH', 'confirmations': 12, 'timestamp': '2026-05-15T10:35:00Z'},
            {'step': 'relay_validated', 'timestamp': '2026-05-15T10:36:00Z'},
            {'step': 'mint_confirmed', 'chain': 'BSC', 'confirmations': 8, 'timestamp': '2026-05-15T10:38:00Z'},
          ],
        }),
      ),
      _ApiEndpoint(
        method: _HttpMethod.get,
        path: '/api/v1/bridge/supported-chains',
        descEn: 'Get the list of all supported blockchain networks for the Zero Bridge, including chain IDs, native tokens, and bridge contract addresses.',
        descZh: '获取 Zero Bridge 支持的所有区块链网络列表，包括链 ID、原生代币和桥合约地址。',
        requiresAuth: false,
        params: [],
        exampleRequest:
            "curl -X GET \"https://api.zero.network/api/v1/bridge/supported-chains\" \\\n  -H \"Accept: application/json\"",
        exampleResponse:
            '{\n'
            '  "chains": [\n'
            '    { "id": "BTC", "name": "Bitcoin", "native_token": "BTC", "bridge_contract": "1Zero...Bridge" },\n'
            '    { "id": "ETH", "name": "Ethereum", "native_token": "ETH", "bridge_contract": "0xZero...Bridge" },\n'
            '    { "id": "BSC", "name": "BNB Smart Chain", "native_token": "BNB", "bridge_contract": "0xZero...Bridge" },\n'
            '    { "id": "TRX", "name": "TRON", "native_token": "TRX", "bridge_contract": "TZero...Bridge" },\n'
            '    { "id": "SOL", "name": "Solana", "native_token": "SOL", "bridge_contract": "Zero...Bridge" }\n'
            '  ]\n'
            '}',
      ),
    ],
  ),
];

String _prettyPrint(Map<String, dynamic> json) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(json);
}

String _randomHex(int length) {
  const chars = '0123456789abcdef';
  final rng = Random();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

class ApiConsoleScreen extends StatefulWidget {
  const ApiConsoleScreen({super.key});

  @override
  State<ApiConsoleScreen> createState() => _ApiConsoleScreenState();
}

class _ApiConsoleScreenState extends State<ApiConsoleScreen> {
  int _selectedCategoryIndex = 0;
  int? _selectedEndpointIndex;

  final Map<String, TextEditingController> _bodyControllers = {};
  final Map<String, bool> _isSending = {};
  final Map<String, String?> _simulatedResponses = {};
  final Map<String, int> _simulatedStatusCodes = {};

  final ScrollController _scrollController = ScrollController();

  _ApiCategory get _currentCategory => _categories[_selectedCategoryIndex];
  _ApiEndpoint? get _currentEndpoint =>
      _selectedEndpointIndex != null ? _currentCategory.endpoints[_selectedEndpointIndex!] : null;

  @override
  void dispose() {
    for (final c in _bodyControllers.values) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _selectEndpoint(int categoryIndex, int endpointIndex) {
    setState(() {
      _selectedCategoryIndex = categoryIndex;
      _selectedEndpointIndex = endpointIndex;
    });
  }

  String _bodyKey(_ApiEndpoint ep) => '${_currentCategory.nameEn}_${ep.path}';

  Future<void> _sendRequest(_ApiEndpoint endpoint) async {
    final key = _bodyKey(endpoint);
    setState(() {
      _isSending[key] = true;
      _simulatedResponses[key] = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Map<String, String>? bodyParams;
    if (endpoint.method == _HttpMethod.post && _bodyControllers.containsKey(key)) {
      try {
        final decoded = json.decode(_bodyControllers[key]!.text) as Map<String, dynamic>;
        bodyParams = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        setState(() {
          _isSending[key] = false;
          _simulatedResponses[key] = '{"error": "Invalid JSON body", "code": 400}';
          _simulatedStatusCodes[key] = 400;
        });
        return;
      }
    }

    final response = endpoint.mockResponseBuilder != null
        ? endpoint.mockResponseBuilder!(bodyParams)
        : endpoint.exampleResponse;

    setState(() {
      _isSending[key] = false;
      _simulatedResponses[key] = response;
      _simulatedStatusCodes[key] = 200;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isZh ? 'API 控制台' : 'API Console'),
            Text(
              'Zero Protocol v1.0.0',
              style: ZeroTypography.caption(context),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildCategoryTabs(isZh),
        ),
      ),
      body: _selectedEndpointIndex == null ? _buildEmptyState(isZh) : _buildEndpointDetail(isZh),
    );
  }

  Widget _buildCategoryTabs(bool isZh) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: ZeroSpacing.sm),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final selected = index == _selectedCategoryIndex;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, size: 16, color: selected ? context.zAccent : context.zTextSecondary),
                const SizedBox(width: ZeroSpacing.xs),
                Text(cat.name(isZh)),
              ],
            ),
            selected: selected,
            onSelected: (val) {
              if (val) {
                setState(() {
                  _selectedCategoryIndex = index;
                  _selectedEndpointIndex = null;
                });
              }
            },
            selectedColor: context.zAccent.withOpacity(0.12),
            backgroundColor: context.zSurface,
            side: BorderSide(
              color: selected ? context.zAccent.withOpacity(0.4) : context.zDivider,
              width: selected ? 1.0 : 0.5,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius)),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? context.zAccent : context.zTextSecondary,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isZh) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.api,
            size: 64,
            color: context.zTextDisabled,
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '选择一个 API 分类' : 'Select an API Category',
            style: ZeroTypography.headline(context).copyWith(color: context.zTextTertiary),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? '从上方标签中选择一个 API 分类，然后点击端点查看详情' : 'Choose an API category from the tabs above, then tap an endpoint to view details',
            style: ZeroTypography.body(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointDetail(bool isZh) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(ZeroSpacing.md),
            children: [
              _buildEndpointList(isZh),
              if (_currentEndpoint != null) ...[
                const SizedBox(height: ZeroSpacing.lg),
                _buildEndpointInfo(isZh, _currentEndpoint!),
              ],
            ],
          ),
        ),
        if (_currentEndpoint != null) _buildTryItBar(isZh, _currentEndpoint!),
      ],
    );
  }

  Widget _buildEndpointList(bool isZh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentCategory.name(isZh),
          style: ZeroTypography.title(context),
        ),
        const SizedBox(height: ZeroSpacing.xs),
        Text(
          isZh ? '${_currentCategory.endpoints.length} 个端点可用' : '${_currentCategory.endpoints.length} endpoints available',
          style: ZeroTypography.caption(context),
        ),
        const SizedBox(height: ZeroSpacing.md),
        ...List.generate(_currentCategory.endpoints.length, (i) {
          final ep = _currentCategory.endpoints[i];
          final selected = i == _selectedEndpointIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: ZeroSpacing.xs),
            child: ZeroCard(
              borderRadius: ZeroSpacing.cardRadiusSm,
              padding: const EdgeInsets.all(ZeroSpacing.md),
              onTap: () => _selectEndpoint(_selectedCategoryIndex, i),
              child: Row(
                children: [
                  _MethodBadge(method: ep.method),
                  const SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ep.path,
                          style: ZeroTypography.mono(context).copyWith(
                            color: selected ? context.zAccent : context.zTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ep.desc(isZh),
                          style: ZeroTypography.caption(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, size: 20, color: context.zAccent)
                  else
                    Icon(Icons.chevron_right, size: 20, color: context.zTextDisabled),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEndpointInfo(bool isZh, _ApiEndpoint ep) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ZeroSpacing.md),
          decoration: BoxDecoration(
            color: context.zSurface,
            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
            border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MethodBadge(method: ep.method),
                  const SizedBox(width: ZeroSpacing.sm),
                  if (ep.requiresAuth)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.zWarning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.zWarning.withOpacity(0.4), width: 0.5),
                      ),
                      child: Text(
                        isZh ? '需要认证' : 'Auth Required',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.zWarning),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ZeroSpacing.sm),
              Text(
                ep.path,
                style: ZeroTypography.mono(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.zTextPrimary,
                ),
              ),
              const SizedBox(height: ZeroSpacing.sm),
              Text(ep.desc(isZh), style: ZeroTypography.body(context)),
            ],
          ),
        ),
        if (ep.params.isNotEmpty) ...[
          const SizedBox(height: ZeroSpacing.lg),
          _buildSectionTitle(isZh ? '请求参数' : 'Request Parameters', Icons.table_chart_outlined),
          const SizedBox(height: ZeroSpacing.sm),
          _buildParamsTable(ep),
        ],
        const SizedBox(height: ZeroSpacing.lg),
        _buildSectionTitle(isZh ? '示例请求' : 'Example Request', Icons.terminal),
        const SizedBox(height: ZeroSpacing.sm),
        _buildCodeBlock(ep.exampleRequest, context),
        const SizedBox(height: ZeroSpacing.lg),
        _buildSectionTitle(isZh ? '示例响应' : 'Example Response', Icons.code),
        const SizedBox(height: ZeroSpacing.sm),
        _buildCodeBlock(ep.exampleResponse, context),
        const SizedBox(height: ZeroSpacing.lg),
        _buildSectionTitle(isZh ? '在线调试' : 'Try It', Icons.play_arrow),
        const SizedBox(height: ZeroSpacing.sm),
        _buildTryItBody(isZh, ep),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.zAccent),
        const SizedBox(width: ZeroSpacing.sm),
        Text(title, style: ZeroTypography.title(context).copyWith(fontSize: 15)),
      ],
    );
  }

  Widget _buildParamsTable(_ApiEndpoint ep) {
    return ZeroCard(
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(4),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: context.zDivider, width: 0.5),
        ),
        children: [
          TableRow(
            children: [
              _paramHeaderCell('Name', context),
              _paramHeaderCell('Type', context),
              _paramHeaderCell('Required', context),
              _paramHeaderCell('Description', context),
            ],
          ),
          ...ep.params.map((p) {
            final isZh = ZeroTheme.isZh(context);
            return TableRow(
              children: [
                _paramCell(p.name, context, bold: true, mono: true),
                _paramCell(p.type, context, mono: true),
                _paramCell(
                  p.required ? (isZh ? '是' : 'Yes') : (isZh ? '否' : 'No'),
                  context,
                  color: p.required ? context.zError : context.zTextTertiary,
                ),
                _paramCell(p.desc(isZh), context),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _paramHeaderCell(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.sm, horizontal: ZeroSpacing.xs),
      child: Text(text, style: ZeroTypography.caption(context).copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _paramCell(String text, BuildContext context, {bool bold = false, Color? color, bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.sm, horizontal: ZeroSpacing.xs),
      child: Text(
        text,
        style: ZeroTypography.caption(context).copyWith(
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color ?? context.zTextSecondary,
          fontFamily: mono ? 'JetBrainsMono' : null,
        ),
      ),
    );
  }

  Widget _buildCodeBlock(String code, BuildContext context) {
    final lines = code.split('\n');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ZeroSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0E14),
        borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
        border: Border.all(color: context.zDivider, width: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) {
            return _buildCodeLine(line, context);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCodeLine(String line, BuildContext context) {
    final spans = <TextSpan>[];
    final isComment = line.trimLeft().startsWith('//') || line.trimLeft().startsWith('#');

    if (isComment) {
      spans.add(TextSpan(
        text: '$line\n',
        style: TextStyle(
          fontFamily: 'JetBrainsMono, monospace',
          fontSize: 12,
          height: 1.6,
          color: const Color(0xFF6BAF7B),
        ),
      ));
    } else {
      final methodRegex = RegExp(r'^(curl|wscat)\s');
      if (methodRegex.hasMatch(line.trimLeft())) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            fontFamily: 'JetBrainsMono, monospace',
            fontSize: 12,
            height: 1.6,
            color: context.zAccent,
          ),
        ));
      } else if (line.contains('"')) {
        final parts = line.split('"');
        for (var i = 0; i < parts.length; i++) {
          if (i % 2 == 1) {
            spans.add(TextSpan(
              text: '"${parts[i]}"',
              style: TextStyle(
                fontFamily: 'JetBrainsMono, monospace',
                fontSize: 12,
                height: 1.6,
                color: const Color(0xFFC2A050),
              ),
            ));
          } else {
            spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(
                fontFamily: 'JetBrainsMono, monospace',
                fontSize: 12,
                height: 1.6,
                color: const Color(0xFFB0B8C8),
              ),
            ));
          }
        }
        spans.add(const TextSpan(text: '\n'));
      } else if (line.trimLeft().startsWith('-')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            fontFamily: 'JetBrainsMono, monospace',
            fontSize: 12,
            height: 1.6,
            color: const Color(0xFF7B8FC0),
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            fontFamily: 'JetBrainsMono, monospace',
            fontSize: 12,
            height: 1.6,
            color: const Color(0xFFB0B8C8),
          ),
        ));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTryItBody(bool isZh, _ApiEndpoint ep) {
    final key = _bodyKey(ep);
    final isSending = _isSending[key] ?? false;
    final response = _simulatedResponses[key];
    final statusCode = _simulatedStatusCodes[key];

    return ZeroCard(
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ep.method == _HttpMethod.post) ...[
            Text(isZh ? '请求体 (JSON)' : 'Request Body (JSON)', style: ZeroTypography.bodyBold(context)),
            const SizedBox(height: ZeroSpacing.sm),
            SizedBox(
              height: 140,
              child: TextField(
                controller: _getBodyController(key),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono, monospace',
                  fontSize: 12,
                  height: 1.5,
                  color: context.zTextPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0D0E14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.zDivider, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.zDivider, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.zAccent, width: 1),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: ZeroSpacing.md),
          ],
          _buildTryItButton(isZh, isSending, ep, key),
          if (response != null) ...[
            const SizedBox(height: ZeroSpacing.md),
            _buildResponseStatus(isZh, statusCode),
            const SizedBox(height: ZeroSpacing.sm),
            _buildCodeBlock(response, context),
          ],
        ],
      ),
    );
  }

  Widget _buildTryItBar(bool isZh, _ApiEndpoint ep) {
    final key = _bodyKey(ep);
    final isSending = _isSending[key] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
      decoration: BoxDecoration(
        color: context.zSurface,
        border: Border(top: BorderSide(color: context.zDivider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: _buildTryItButton(isZh, isSending, ep, key),
      ),
    );
  }

  Widget _buildTryItButton(bool isZh, bool isSending, _ApiEndpoint ep, String key) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: isSending ? null : () => _sendRequest(ep),
        icon: isSending
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send, size: 18),
        label: Text(
          isSending
              ? (isZh ? '发送中...' : 'Sending...')
              : (isZh ? '发送请求' : 'Send Request'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.zAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildResponseStatus(bool isZh, int? statusCode) {
    final ok = statusCode != null && statusCode >= 200 && statusCode < 300;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ok ? context.zSuccess.withOpacity(0.15) : context.zError.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$statusCode ${ok ? 'OK' : 'Error'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrainsMono, monospace',
              color: ok ? context.zSuccess : context.zError,
            ),
          ),
        ),
        const SizedBox(width: ZeroSpacing.sm),
        Text(
          ok ? (isZh ? '请求成功' : 'Request successful') : (isZh ? '请求失败' : 'Request failed'),
          style: ZeroTypography.caption(context),
        ),
      ],
    );
  }

  TextEditingController _getBodyController(String key) {
    if (!_bodyControllers.containsKey(key)) {
      _bodyControllers[key] = TextEditingController(text: '{}');
    }
    return _bodyControllers[key]!;
  }
}

class _MethodBadge extends StatelessWidget {
  final _HttpMethod method;

  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: method.color(context).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'JetBrainsMono, monospace',
          letterSpacing: 0.5,
          color: method.color(context),
        ),
      ),
    );
  }
}