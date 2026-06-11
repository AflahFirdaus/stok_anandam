import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/utils.dart';

/// Service for generating RSA key pairs, signing challenges,
/// and securely storing private keys using FlutterSecureStorage.
class BiometricCryptoService {
  final FlutterSecureStorage _storage;

  BiometricCryptoService(this._storage);

  static const _privateKeyPrefix = 'biometric_private_';
  static const _publicKeyPrefix = 'biometric_public_';

  /// Generate RSA-2048 key pair and store the private key securely.
  /// Returns the public key in X.509 Base64 format.
  Future<String> generateKeyPair(String deviceId) async {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        FortunaRandom()..seed(KeyParameter(Uint8List.fromList(_generateSecureSeed()))),
      ));

    final pair = keyGen.generateKeyPair();

    // Store private key
    final privateKey = pair.privateKey;
    final privateKeyBytes = _encodePrivateKey(privateKey);
    await _storage.write(
      key: '$_privateKeyPrefix$deviceId',
      value: base64.encode(privateKeyBytes),
    );

    // Store public key
    final publicKey = pair.publicKey;
    final publicKeyBytes = _encodePublicKeyX509(publicKey);
    await _storage.write(
      key: '$_publicKeyPrefix$deviceId',
      value: base64.encode(publicKeyBytes),
    );

    // Return public key in X.509 Base64 format
    return base64.encode(publicKeyBytes);
  }

  /// Sign a challenge string with the stored private key.
  /// Returns the Base64-encoded signature.
  Future<String> signChallenge(String deviceId, String challenge) async {
    final privateKeyBase64 =
        await _storage.read(key: '$_privateKeyPrefix$deviceId');
    if (privateKeyBase64 == null) {
      throw Exception('Private key tidak ditemukan untuk device $deviceId');
    }

    final privateKeyBytes = base64.decode(privateKeyBase64);
    final privateKey = _decodePrivateKey(privateKeyBytes);

    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final signature =
        signer.generateSignature(utf8.encode(challenge)) as RSASignature;
    return base64.encode(signature.bytes);
  }

  /// Check if biometric keys exist for a device
  Future<bool> hasKeys(String deviceId) async {
    final key = await _storage.read(key: '$_privateKeyPrefix$deviceId');
    return key != null;
  }

  /// Delete biometric keys for a device
  Future<void> deleteKeys(String deviceId) async {
    await _storage.delete(key: '$_privateKeyPrefix$deviceId');
    await _storage.delete(key: '$_publicKeyPrefix$deviceId');
  }

  /// Get stored public key for a device
  Future<String?> getPublicKey(String deviceId) async {
    return await _storage.read(key: '$_publicKeyPrefix$deviceId');
  }

  // --- Private helper methods ---

  List<int> _generateSecureSeed() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  /// Encode RSAPrivateKey to bytes for storage
  Uint8List _encodePrivateKey(RSAPrivateKey key) {
    final keyMap = {
      'modulus': key.modulus!.toRadixString(16),
      'privateExponent': key.privateExponent!.toRadixString(16),
      'publicExponent': key.publicExponent!.toRadixString(16),
      'p': key.p!.toRadixString(16),
      'q': key.q!.toRadixString(16),
    };
    return utf8.encode(json.encode(keyMap));
  }

  /// Decode stored bytes back to RSAPrivateKey
  RSAPrivateKey _decodePrivateKey(List<int> bytes) {
    final keyMap = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    return RSAPrivateKey(
      BigInt.parse(keyMap['modulus']!, radix: 16),
      BigInt.parse(keyMap['privateExponent']!, radix: 16),
      BigInt.parse(keyMap['p']!, radix: 16),
      BigInt.parse(keyMap['q']!, radix: 16),
    );
  }

  /// Encode RSAPublicKey to bytes
  Uint8List _encodePublicKey(RSAPublicKey key) {
    final modulus = _bigIntToBytes(key.modulus!);
    final publicExponent = _bigIntToBytes(key.publicExponent!);

    final buffer = BytesBuilder();
    _writeBytes(buffer, modulus);
    _writeBytes(buffer, publicExponent);

    return buffer.toBytes();
  }

  /// Encode RSAPublicKey to standard X.509 DER format bytes
  Uint8List _encodePublicKeyX509(RSAPublicKey key) {
    final modulusBytes = _encodeASN1Integer(key.modulus!);
    final exponentBytes = _encodeASN1Integer(key.publicExponent!);

    final rsaPubKeySequence = _encodeASN1Sequence([modulusBytes, exponentBytes]);

    // OID 1.2.840.113549.1.1.1 in DER is: 06 09 2A 86 48 86 F7 0D 01 01 01
    final rsaOid = Uint8List.fromList([0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01]);
    final nullParams = Uint8List.fromList([0x05, 0x00]);
    final algorithmIdentifier = _encodeASN1Sequence([rsaOid, nullParams]);

    final bitStringValue = BytesBuilder()
      ..addByte(0x00)
      ..add(rsaPubKeySequence);
    final subjectPublicKey = _encodeASN1Type(0x03, bitStringValue.toBytes());

    return _encodeASN1Sequence([algorithmIdentifier, subjectPublicKey]);
  }

  Uint8List _encodeASN1Integer(BigInt value) {
    var bytes = _bigIntToBytes(value);
    if (bytes.isNotEmpty && (bytes[0] & 0x80) != 0) {
      bytes = Uint8List.fromList([0x00, ...bytes]);
    }
    return _encodeASN1Type(0x02, bytes);
  }

  Uint8List _encodeASN1Sequence(List<Uint8List> elements) {
    final body = BytesBuilder();
    for (final element in elements) {
      body.add(element);
    }
    return _encodeASN1Type(0x30, body.toBytes());
  }

  Uint8List _encodeASN1Type(int tag, Uint8List value) {
    final builder = BytesBuilder();
    builder.addByte(tag);
    
    final length = value.length;
    if (length < 128) {
      builder.addByte(length);
    } else {
      final lengthBytes = <int>[];
      var temp = length;
      while (temp > 0) {
        lengthBytes.insert(0, temp & 0xFF);
        temp >>= 8;
      }
      builder.addByte(0x80 | lengthBytes.length);
      builder.add(lengthBytes);
    }
    builder.add(value);
    return builder.toBytes();
  }

  void _writeBytes(BytesBuilder buffer, Uint8List bytes) {
    // Write length prefix (4 bytes) then data
    final length = bytes.length;
    buffer.addByte((length >> 24) & 0xFF);
    buffer.addByte((length >> 16) & 0xFF);
    buffer.addByte((length >> 8) & 0xFF);
    buffer.addByte(length & 0xFF);
    buffer.add(bytes);
  }

  Uint8List _readBytes(List<int> data, int offset) {
    final length = (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
    return Uint8List.fromList(data.sublist(offset + 4, offset + 4 + length));
  }

  Uint8List _bigIntToBytes(BigInt value) {
    return encodeBigInt(value);
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    return decodeBigInt(bytes);
  }
}