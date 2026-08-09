import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../models/result_model.dart';
import 'security_service.dart';

class LocalDatabaseService {
  static const String _patientsKey = 'secure_patients_db';
  static const String _scansKey = 'secure_scans_db';
  static const String _feedbackKey = 'secure_feedback_db';

  /// Save Patient locally with Encryption
  static Future<void> savePatient(PatientModel patient) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing
    final encryptedData = prefs.getString(_patientsKey);
    List<dynamic> patientsList = [];
    if (encryptedData != null) {
      final decrypted = SecurityService.decryptData(encryptedData);
      try {
        patientsList = jsonDecode(decrypted);
      } catch (_) {}
    }

    // Add new patient
    final existingIndex = patientsList.indexWhere((p) => p['id'] == patient.id);
    if (existingIndex >= 0) {
      patientsList[existingIndex] = patient.toMap();
    } else {
      patientsList.add(patient.toMap());
    }

    // Encrypt and save
    final newEncrypted = SecurityService.encryptData(jsonEncode(patientsList));
    await prefs.setString(_patientsKey, newEncrypted);
  }

  /// Get all Patients locally
  static Future<List<PatientModel>> getPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_patientsKey);
    if (encryptedData == null) return [];

    final decrypted = SecurityService.decryptData(encryptedData);
    try {
      final List<dynamic> patientsList = jsonDecode(decrypted);
      return patientsList.map((e) => PatientModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save Scan Result locally
  static Future<void> saveScanResult(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    
    final encryptedData = prefs.getString(_scansKey);
    List<dynamic> scansList = [];
    if (encryptedData != null) {
      final decrypted = SecurityService.decryptData(encryptedData);
      try {
        scansList = jsonDecode(decrypted);
      } catch (_) {}
    }

    scansList.add(result.toMap());

    final newEncrypted = SecurityService.encryptData(jsonEncode(scansList));
    await prefs.setString(_scansKey, newEncrypted);
  }

  /// Get all Scans locally
  static Future<List<ScanResult>> getAllScans() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_scansKey);
    if (encryptedData == null) return [];

    final decrypted = SecurityService.decryptData(encryptedData);
    try {
      final List<dynamic> scansList = jsonDecode(decrypted);
      return scansList.map((e) => ScanResult.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get Patient Scans locally
  static Future<List<ScanResult>> getPatientScans(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_scansKey);
    if (encryptedData == null) return [];

    final decrypted = SecurityService.decryptData(encryptedData);
    try {
      final List<dynamic> scansList = jsonDecode(decrypted);
      final results = scansList.map((e) => ScanResult.fromMap(e)).toList();
      return results.where((r) => r.patientId == patientId).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save Feedback locally
  static Future<void> saveFeedback(int rating, String comment) async {
    final prefs = await SharedPreferences.getInstance();
    
    final encryptedData = prefs.getString(_feedbackKey);
    List<dynamic> feedbackList = [];
    if (encryptedData != null) {
      final decrypted = SecurityService.decryptData(encryptedData);
      try {
        feedbackList = jsonDecode(decrypted);
      } catch (_) {}
    }

    feedbackList.add({
      'rating': rating,
      'comment': comment,
      'date': DateTime.now().toIso8601String(),
    });

    final newEncrypted = SecurityService.encryptData(jsonEncode(feedbackList));
    await prefs.setString(_feedbackKey, newEncrypted);
  }

  /// Get Average Feedback Rating
  static Future<double> getAverageRating() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_feedbackKey);
    if (encryptedData == null) return 0.0;

    try {
      final decrypted = SecurityService.decryptData(encryptedData);
      final List<dynamic> feedbackList = jsonDecode(decrypted);
      if (feedbackList.isEmpty) return 0.0;

      double total = 0;
      for (var fb in feedbackList) {
        total += fb['rating'] as int;
      }
      return total / feedbackList.length;
    } catch (_) {
      return 0.0;
    }
  }
}
