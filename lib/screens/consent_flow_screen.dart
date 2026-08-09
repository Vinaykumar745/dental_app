import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'patient_form_screen.dart';

class ConsentFlowScreen extends StatefulWidget {
  const ConsentFlowScreen({super.key});

  @override
  State<ConsentFlowScreen> createState() => _ConsentFlowScreenState();
}

class _ConsentFlowScreenState extends State<ConsentFlowScreen> {
  bool _agreed = false;

  void _onNext() {
    if (_agreed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PatientFormScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to proceed with the scan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Scan Setup'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient Consent & Disclaimer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI-GENERATED OUTPUT — NOT A DIAGNOSIS — MUST BE INDEPENDENTLY VERIFIED\n\n'
                    'This application is a computer-generated, probabilistic risk estimate produced by pattern matching against a finite training dataset. It is NOT a diagnosis, NOT a pathology report, NOT a radiology report, and NOT a clinical opinion.\n\n'
                    'THE ALGORITHM CAN BE WRONG IN BOTH DIRECTIONS:\n\n'
                    'A LOW-RISK OR NEGATIVE RESULT DOES NOT EXCLUDE DYSPLASIA OR MALIGNANCY and must never be treated or communicated as reassurance.\n\n'
                    'A HIGH-RISK RESULT DOES NOT ESTABLISH DISEASE; many benign conditions produce a high-risk output.\n\n'
                    'Clinical responsibility rests entirely with the treating registered practitioner. Any clinically suspicious lesion must be referred and biopsied on clinical grounds irrespective of this output.\n\n'
                    'PATIENT CONSENT\n\n'
                    'Before proceeding, ensure you have obtained the following consents from the patient:\n\n'
                    '1. I confirm that I have read or had read to me the Patient Information Sheet and had the opportunity to ask questions.\n\n'
                    '2. I understand that a computer program using artificial intelligence will analyse photographs of my mouth, that its result is only an aid to my doctor, that it is not a diagnosis, that it can be wrong in both directions, and that only a biopsy examined by a pathologist can diagnose or rule out cancer. I understand that a low-risk result does not mean I am free of disease.\n\n'
                    '3. I agree to photographs and/or video of my oral cavity being taken, and to my personal, clinical and habit information being entered into the application and processed for the purpose of my clinical care. I understand that my participation is voluntary, that I may withdraw at any time, and that my care will not be affected if I refuse.',
                    style: TextStyle(
                      fontSize: 15,
                      color: textGreyColor,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _agreed,
                        activeColor: AppTheme.primary,
                        onChanged: (val) {
                          setState(() {
                            _agreed = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreed = !_agreed;
                            });
                          },
                          child: Text(
                            'I confirm that the patient has provided these mandatory consents and I agree to the terms.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _agreed ? _onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'I Agree & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
