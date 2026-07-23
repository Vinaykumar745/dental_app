import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _pinKey = 'app_security_pin';
  static const String _encryptionKeyStr = 'DentalAppSecureEncryptionKey1234'; // 32 chars
  
  static final _key = encrypt.Key.fromUtf8(_encryptionKeyStr);
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  /// Encrypts plain text
  static String encryptData(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return plainText; // Fallback
    }
  }

  /// Decrypts base64 encoded encrypted text
  static String decryptData(String encryptedText) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      print('Decryption error: $e');
      return encryptedText; // Fallback
    }
  }

  /// Set the App PIN
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, encryptData(pin));
  }

  /// Check if PIN is set
  static Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  /// Verify App PIN
  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEncrypted = prefs.getString(_pinKey);
    if (storedEncrypted == null) return false;
    
    final storedPin = decryptData(storedEncrypted);
    return storedPin == pin;
  }
}
