import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:zero/services/crypto/bip39_wordlist.dart';
import 'package:zero/services/crypto/cid_utils.dart';
import 'package:zero/services/crypto/did_service.dart';
import 'package:zero/services/crypto/zero_crypto.dart';

void main() {
  setUpAll(() {
    print('');
    print('╔══════════════════════════════════════════════════╗');
    print('║        Zero Crypto - Full Encryption Stack        ║');
    print('║              Verification Test Suite              ║');
    print('╚══════════════════════════════════════════════════╝');
    print('');
  });

  final crypto = ZeroCrypto();

  // ═══════════════════════════════════════════════════════════════
  // 1. BIP39 Mnemonic Generation
  // ═══════════════════════════════════════════════════════════════

  group('BIP39 Mnemonic Generation', () {
    test('generate 12-word mnemonic, verify all words in wordlist', () {
      final mnemonic = crypto.generateMnemonic(strength: 128);
      final words = mnemonic.split(' ');

      expect(words.length, 12,
          reason: '12-word mnemonic should have exactly 12 words');

      for (final word in words) {
        expect(Bip39Wordlist.isValid(word), isTrue,
            reason: 'Word "$word" should be in the BIP39 wordlist');
      }
    });

    test('generate 24-word mnemonic, verify all words in wordlist', () {
      final mnemonic = crypto.generateMnemonic(strength: 256);
      final words = mnemonic.split(' ');

      expect(words.length, 24,
          reason: '24-word mnemonic should have exactly 24 words');

      for (final word in words) {
        expect(Bip39Wordlist.isValid(word), isTrue,
            reason: 'Word "$word" should be in the BIP39 wordlist');
      }
    });

    test('validate known good mnemonic passes checksum', () {
      const goodMnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about';

      expect(crypto.validateMnemonic(goodMnemonic), isTrue,
          reason: 'Known valid BIP39 mnemonic should pass validation');
    });

    test('validate bad mnemonic with random words fails', () {
      const badMnemonic =
          'hello world foo bar baz qux quux corge grault garply waldo fred';

      expect(crypto.validateMnemonic(badMnemonic), isFalse,
          reason: 'Mnemonic with random non-BIP39 words should fail validation');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 2. BIP39 Seed Derivation
  // ═══════════════════════════════════════════════════════════════

  group('BIP39 Seed Derivation', () {
    test('known test vector from BIP39 spec (passphrase "TREZOR")', () {
      const mnemonic =
          'legal winner thank year wave sausage worth useful '
          'legal winner thank yellow';
      const passphrase = 'TREZOR';

      expect(crypto.validateMnemonic(mnemonic), isTrue,
          reason: 'Test vector mnemonic should be valid');

      final seed = crypto.mnemonicToSeed(mnemonic, passphrase: passphrase);

      expect(seed.length, 64, reason: 'Seed should be 64 bytes (512 bits)');

      const expectedFirstBytes = [
        0x2e, 0x89, 0x05, 0x81, 0x9b, 0x87, 0x23, 0xfe,
      ];

      for (var i = 0; i < expectedFirstBytes.length; i++) {
        expect(seed[i], expectedFirstBytes[i],
            reason:
                'Seed byte $i should match BIP39 test vector (passphrase "TREZOR")');
      }
    });

    test('generate mnemonic, derive seed, verify seed is 64 bytes', () {
      final mnemonic = crypto.generateMnemonic(strength: 128);
      final seed = crypto.mnemonicToSeed(mnemonic);

      expect(seed.length, 64,
          reason: 'Derived seed should always be 64 bytes');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 3. ECDSA P-256 Sign / Verify
  // ═══════════════════════════════════════════════════════════════

  group('ECDSA P-256 Sign/Verify', () {
    late IdentityKeyPair aliceKeys;
    late Uint8List message;

    setUp(() {
      final mnemonic = crypto.generateMnemonic();
      final seed = crypto.mnemonicToSeed(mnemonic);
      aliceKeys = crypto.generateIdentityKeys(seed);
      message = Uint8List.fromList(utf8.encode('Hello, Zero!'));
    });

    test('sign a message and verify succeeds', () {
      final signature = crypto.sign(aliceKeys.privateKey, message);
      final isValid = crypto.verify(aliceKeys.publicKey, message, signature);

      expect(isValid, isTrue,
          reason: 'Valid signature should verify successfully');
    });

    test('verify with tampered message should fail', () {
      final signature = crypto.sign(aliceKeys.privateKey, message);
      final tampered = Uint8List.fromList(utf8.encode('Hello, Evil!'));
      final isValid = crypto.verify(aliceKeys.publicKey, tampered, signature);

      expect(isValid, isFalse,
          reason: 'Signature should not verify with tampered message');
    });

    test('verify with wrong public key should fail', () {
      final signature = crypto.sign(aliceKeys.privateKey, message);

      final bobMnemonic = crypto.generateMnemonic();
      final bobSeed = crypto.mnemonicToSeed(bobMnemonic);
      final bobKeys = crypto.generateIdentityKeys(bobSeed);

      final isValid = crypto.verify(bobKeys.publicKey, message, signature);

      expect(isValid, isFalse,
          reason: 'Signature should not verify with wrong public key');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 4. ECDH Key Agreement
  // ═══════════════════════════════════════════════════════════════

  group('ECDH Key Agreement', () {
    test('Alice and Bob compute the SAME shared secret', () {
      final aliceMnemonic = crypto.generateMnemonic();
      final aliceSeed = crypto.mnemonicToSeed(aliceMnemonic);
      final aliceKeys = crypto.generateIdentityKeys(aliceSeed);

      final bobMnemonic = crypto.generateMnemonic();
      final bobSeed = crypto.mnemonicToSeed(bobMnemonic);
      final bobKeys = crypto.generateIdentityKeys(bobSeed);

      final aliceSharedSecret =
          crypto.computeSharedSecret(aliceKeys.privateKey, bobKeys.publicKey);

      final bobSharedSecret =
          crypto.computeSharedSecret(bobKeys.privateKey, aliceKeys.publicKey);

      expect(aliceSharedSecret.length, 32,
          reason: 'Shared secret should be 32 bytes');
      expect(bobSharedSecret.length, 32,
          reason: 'Shared secret should be 32 bytes');
      expect(aliceSharedSecret, equals(bobSharedSecret),
          reason:
              'Alice and Bob must derive the identical shared secret via ECDH');
    });

    test('different key pairs produce DIFFERENT shared secrets', () {
      final aliceMnemonic = crypto.generateMnemonic();
      final aliceSeed = crypto.mnemonicToSeed(aliceMnemonic);
      final aliceKeys = crypto.generateIdentityKeys(aliceSeed);

      final bobMnemonic = crypto.generateMnemonic();
      final bobSeed = crypto.mnemonicToSeed(bobMnemonic);
      final bobKeys = crypto.generateIdentityKeys(bobSeed);

      final eveMnemonic = crypto.generateMnemonic();
      final eveSeed = crypto.mnemonicToSeed(eveMnemonic);
      final eveKeys = crypto.generateIdentityKeys(eveSeed);

      final aliceBobSecret =
          crypto.computeSharedSecret(aliceKeys.privateKey, bobKeys.publicKey);

      final aliceEveSecret =
          crypto.computeSharedSecret(aliceKeys.privateKey, eveKeys.publicKey);

      expect(
          aliceBobSecret,
          isNot(equals(aliceEveSecret)),
          reason:
              'Shared secrets with different peers must be different');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 5. ChaCha20-Poly1305 AEAD
  // ═══════════════════════════════════════════════════════════════

  group('ChaCha20-Poly1305 AEAD', () {
    late Uint8List key;
    late Uint8List nonce;
    late Uint8List plaintext;

    setUp(() {
      key = crypto.randomBytes(32);
      nonce = crypto.randomBytes(12);
      plaintext = Uint8List.fromList(utf8.encode(
          'The quick brown fox jumps over the lazy dog'));
    });

    test('encrypt and decrypt roundtrip works', () {
      final result = crypto.encryptAEAD(key, nonce, plaintext);
      final decrypted =
          crypto.decryptAEAD(key, nonce, result.ciphertext, result.mac);

      expect(decrypted, equals(plaintext),
          reason:
              'Decrypted plaintext should match original after roundtrip');
    });

    test('decrypt with wrong key throws MAC error', () {
      final result = crypto.encryptAEAD(key, nonce, plaintext);
      final wrongKey = crypto.randomBytes(32);

      expect(
        () => crypto.decryptAEAD(
            wrongKey, nonce, result.ciphertext, result.mac),
        throwsA(isA<ArgumentError>()),
        reason:
            'Decrypting with wrong key should throw MAC verification error',
      );
    });

    test('decrypt with wrong nonce throws MAC error', () {
      final result = crypto.encryptAEAD(key, nonce, plaintext);
      final wrongNonce = crypto.randomBytes(12);

      expect(
        () => crypto.decryptAEAD(
            key, wrongNonce, result.ciphertext, result.mac),
        throwsA(isA<ArgumentError>()),
        reason:
            'Decrypting with wrong nonce should throw MAC verification error',
      );
    });

    test('encrypt with AAD (additional authenticated data) works', () {
      final aad = Uint8List.fromList(utf8.encode('metadata'));
      final result = crypto.encryptAEAD(key, nonce, plaintext, aad: aad);
      final decrypted =
          crypto.decryptAEAD(key, nonce, result.ciphertext, result.mac,
              aad: aad);

      expect(decrypted, equals(plaintext),
          reason: 'AEAD roundtrip with AAD should preserve plaintext');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 6. SHA256 and HKDF
  // ═══════════════════════════════════════════════════════════════

  group('SHA256 and HKDF', () {
    test('SHA256 of "hello" matches known hash', () {
      final input = Uint8List.fromList(utf8.encode('hello'));
      final hash = crypto.sha256(input);
      final hashHex = crypto.sha256Hex(input);

      const expectedHex =
          '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

      expect(hashHex, expectedHex,
          reason: 'SHA256("hello") should match known test vector');
      expect(hash.length, 32, reason: 'SHA256 output should be 32 bytes');
    });

    test('HKDF produces consistent and distinct outputs', () {
      final ikm = Uint8List.fromList(List.generate(32, (i) => i));
      final salt = Uint8List.fromList(List.generate(16, (i) => (i * 3) % 256));

      final info1 = Uint8List.fromList(utf8.encode('encryption-key'));
      final info2 = Uint8List.fromList(utf8.encode('mac-key'));

      final key1 = crypto.hkdf(salt, ikm, info1, 32);
      final key2 = crypto.hkdf(salt, ikm, info2, 32);

      expect(key1.length, 32, reason: 'HKDF output should be requested length');
      expect(key2.length, 32, reason: 'HKDF output should be requested length');
      expect(key1, isNot(equals(key2)),
          reason:
              'HKDF with different info should produce different output keys');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 7. BIP39 Wordlist
  // ═══════════════════════════════════════════════════════════════

  group('BIP39 Wordlist', () {
    test('contains exactly 2048 words with no duplicates', () {
      final words = Bip39Wordlist.words;

      expect(words.length, 2048,
          reason: 'BIP39 wordlist should contain exactly 2048 words');

      final uniqueWords = words.toSet();
      expect(uniqueWords.length, 2048,
          reason: 'BIP39 wordlist should have no duplicate words');
    });

    test('indexOf and isValid work correctly', () {
      expect(Bip39Wordlist.indexOf('abandon'), 0,
          reason: '"abandon" should be at index 0');
      expect(Bip39Wordlist.indexOf('zoo'), 2047,
          reason: '"zoo" should be at index 2047');
      expect(Bip39Wordlist.indexOf('notaword'), isNull,
          reason: 'Non-existent word should return null');

      expect(Bip39Wordlist.isValid('zero'), isTrue,
          reason: '"zero" is a valid BIP39 word');
      expect(Bip39Wordlist.isValid('notaword'), isFalse,
          reason: '"notaword" is not a valid BIP39 word');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 8. DID Document
  // ═══════════════════════════════════════════════════════════════

  group('DID Document', () {
    late ZeroCrypto crypto;
    late DIDService didService;
    late IdentityKeyPair identityKeys;
    late ECPreKeyPair preKeyPair;
    late String zeroId;

    setUp(() {
      crypto = ZeroCrypto();
      didService = DIDService();

      final mnemonic = crypto.generateMnemonic();
      final seed = crypto.mnemonicToSeed(mnemonic);
      identityKeys = crypto.generateIdentityKeys(seed);
      preKeyPair = crypto.generatePreKeyPair(seed, 0);
      zeroId = crypto.sha256Hex(utf8.encode(mnemonic)).substring(0, 16);
    });

    test('create DID document with valid keys', () {
      final doc = didService.createDIDDocument(
        zeroId,
        identityKeys.publicKeyHex,
        preKeyPair.publicKeyHex,
      );

      expect(doc['id'], 'did:zero:$zeroId');
      expect(doc['controller'], 'did:zero:$zeroId');

      final verificationMethods = doc['verificationMethod'] as List<dynamic>;
      expect(verificationMethods.length, 1);
      expect(verificationMethods[0]['type'],
          'EcdsaSecp256r1VerificationKey2019');
      expect(verificationMethods[0]['publicKeyHex'],
          identityKeys.publicKeyHex);

      final keyAgreement = doc['keyAgreement'] as List<dynamic>;
      expect(keyAgreement.length, 1);
      expect(keyAgreement[0]['type'], 'EcdhSecp256r1KeyAgreementKey2019');
      expect(keyAgreement[0]['publicKeyHex'], preKeyPair.publicKeyHex);
    });

    test('sign and verify DID document', () {
      final doc = didService.createDIDDocument(
        zeroId,
        identityKeys.publicKeyHex,
        preKeyPair.publicKeyHex,
      );

      final signedJson = didService.signDIDDocument(doc, identityKeys.privateKey);
      expect(signedJson, isNotEmpty);
      expect(signedJson, contains('"proof"'));

      final isValid = didService.verifyDIDDocument(signedJson);
      expect(isValid, isTrue,
          reason: 'Signed DID document should verify successfully');
    });

    test('verify tampered DID document fails', () {
      final doc = didService.createDIDDocument(
        zeroId,
        identityKeys.publicKeyHex,
        preKeyPair.publicKeyHex,
      );

      final signedJson = didService.signDIDDocument(doc, identityKeys.privateKey);

      final tamperedJson = signedJson.replaceFirst('did:zero:', 'did:evil:');
      final isValid = didService.verifyDIDDocument(tamperedJson);

      expect(isValid, isFalse,
          reason: 'Tampered DID document should fail verification');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 9. CID Utils
  // ═══════════════════════════════════════════════════════════════

  group('CID Utils', () {
    test('generate CID from content', () {
      final content = Uint8List.fromList(utf8.encode('test content'));
      final cid = generateContentId(content);

      expect(cid.startsWith('z0'), isTrue,
          reason: 'CID should start with "z0" prefix');
      expect(cid.length, 34, reason: 'CID should be 34 characters');
    });

    test('verify content against CID', () {
      final content = Uint8List.fromList(utf8.encode('test content'));
      final cid = generateContentId(content);

      expect(verifyContentId(cid, content), isTrue,
          reason: 'Content should verify against its own CID');

      final differentContent = Uint8List.fromList(utf8.encode('other content'));
      expect(verifyContentId(cid, differentContent), isFalse,
          reason: 'Different content should not match the same CID');
    });

    test('isValidCid checks format correctly', () {
      final content = Uint8List.fromList(utf8.encode('test'));
      final validCid = generateContentId(content);

      expect(isValidCid(validCid), isTrue,
          reason: 'Generated CID should pass format validation');

      expect(isValidCid('not-a-cid'), isFalse,
          reason: 'Random string should fail CID validation');
      expect(isValidCid('z0too-short'), isFalse,
          reason: 'Too-short CID should fail validation');
      expect(isValidCid('z0gggggggggggggggggggggggggggggggg'), isFalse,
          reason: 'CID with invalid hex chars should fail validation');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 10. Full E2EE Flow (Integration Test)
  // ═══════════════════════════════════════════════════════════════

  test('Full E2EE Flow: Alice and Bob exchange encrypted messages', () {
    final aliceMnemonic = crypto.generateMnemonic();
    final aliceSeed = crypto.mnemonicToSeed(aliceMnemonic);
    final aliceIdentity = crypto.generateIdentityKeys(aliceSeed);
    final alicePreKey = crypto.generatePreKeyPair(aliceSeed, 0);

    final bobMnemonic = crypto.generateMnemonic();
    final bobSeed = crypto.mnemonicToSeed(bobMnemonic);
    final bobIdentity = crypto.generateIdentityKeys(bobSeed);
    final bobPreKey = crypto.generatePreKeyPair(bobSeed, 0);

    final sharedSecret = crypto.computeSharedSecret(
        alicePreKey.privateKey, bobPreKey.publicKey);

    final verifiedSecret = crypto.computeSharedSecret(
        bobPreKey.privateKey, alicePreKey.publicKey);
    expect(sharedSecret, equals(verifiedSecret),
        reason: 'Both sides must agree on the shared secret');

    final aliceEncryptKey = crypto.hkdf(
        sharedSecret, Uint8List(0),
        Uint8List.fromList(utf8.encode('alice-encrypt')), 32);
    final bobEncryptKey = crypto.hkdf(
        sharedSecret, Uint8List(0),
        Uint8List.fromList(utf8.encode('bob-encrypt')), 32);

    final aliceMsg1 =
        Uint8List.fromList(utf8.encode('Hi Bob, this is Alice!'));
    final nonce1 = crypto.randomBytes(12);
    final encrypted1 = crypto.encryptAEAD(aliceEncryptKey, nonce1, aliceMsg1);
    final decrypted1 = crypto.decryptAEAD(
        aliceEncryptKey, nonce1, encrypted1.ciphertext, encrypted1.mac);

    expect(decrypted1, equals(aliceMsg1),
        reason: 'Alice -> Bob: message 1 roundtrip should work');

    final bobMsg1 =
        Uint8List.fromList(utf8.encode('Hi Alice, Bob here! Got your message.'));
    final nonce2 = crypto.randomBytes(12);
    final encrypted2 = crypto.encryptAEAD(bobEncryptKey, nonce2, bobMsg1);
    final decrypted2 = crypto.decryptAEAD(
        bobEncryptKey, nonce2, encrypted2.ciphertext, encrypted2.mac);

    expect(decrypted2, equals(bobMsg1),
        reason: 'Bob -> Alice: reply roundtrip should work');

    final messages = [
      'How are you doing?',
      'I am great, thanks!',
      'Let us chat more later.',
      'Sounds good, bye!',
    ];

    for (var i = 0; i < messages.length; i++) {
      final msgBytes = Uint8List.fromList(utf8.encode(messages[i]));
      final nonce = crypto.randomBytes(12);

      if (i % 2 == 0) {
        final enc = crypto.encryptAEAD(aliceEncryptKey, nonce, msgBytes);
        final dec = crypto.decryptAEAD(
            aliceEncryptKey, nonce, enc.ciphertext, enc.mac);
        expect(dec, equals(msgBytes),
            reason: 'Multi-message roundtrip $i should work');
      } else {
        final enc = crypto.encryptAEAD(bobEncryptKey, nonce, msgBytes);
        final dec = crypto.decryptAEAD(
            bobEncryptKey, nonce, enc.ciphertext, enc.mac);
        expect(dec, equals(msgBytes),
            reason: 'Multi-message roundtrip $i should work');
      }
    }
  });
}