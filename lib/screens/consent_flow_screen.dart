import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'patient_form_screen.dart';

class ConsentFlowScreen extends StatefulWidget {
  const ConsentFlowScreen({super.key});

  @override
  State<ConsentFlowScreen> createState() => _ConsentFlowScreenState();
}

class _ConsentFlowScreenState extends State<ConsentFlowScreen> {
  final List<bool> _consents = List.generate(3, (_) => false);

  bool get _allAgreed => _consents.every((element) => element);

  void _onNext() {
    if (_allAgreed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PatientFormScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to all terms to proceed with the scan.')),
      );
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String text,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color textColor,
    required Color textGreyColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color: textGreyColor,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
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

  Widget _buildConsentCard({
    required String text,
    required int index,
    required bool isDark,
    required Color textColor,
    required Color textGreyColor,
  }) {
    final value = _consents[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg.withValues(alpha: 0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value ? AppTheme.primary.withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.black12), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: value,
            activeColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) {
              setState(() => _consents[index] = val ?? false);
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _consents[index] = !value);
              },
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: value ? textColor : textGreyColor,
                  height: 1.4,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Consent', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
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
                    'Important Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoCard(
                    title: 'Purpose of the Scan',
                    text: 'This scan is used to screen for potential anomalies in the oral cavity to support your overall dental health.',
                    icon: Icons.info_outline_rounded,
                    color: AppTheme.primary,
                    isDark: isDark, textColor: textColor, textGreyColor: textGreyColor,
                  ),
                  _buildInfoCard(
                    title: 'AI is NOT a Diagnosis',
                    text: 'The AI output is ONLY AN AID for your doctor. It can be wrong. Only a biopsy examined by a pathologist can diagnose or rule out cancer.',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                    isDark: isDark, textColor: textColor, textGreyColor: textGreyColor,
                  ),
                  _buildInfoCard(
                    title: 'Privacy & Data Security',
                    text: 'Your personal data and images will be securely processed and stored in compliance with applicable healthcare privacy regulations.',
                    icon: Icons.shield_outlined,
                    color: AppTheme.success,
                    isDark: isDark, textColor: textColor, textGreyColor: textGreyColor,
                  ),
                  _buildInfoCard(
                    title: 'Voluntary Participation',
                    text: 'Your participation is strictly VOLUNTARY. You have the right to withdraw your consent at any time before submission.',
                    icon: Icons.pan_tool_outlined,
                    color: Colors.purple,
                    isDark: isDark, textColor: textColor, textGreyColor: textGreyColor,
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      const Icon(Icons.assignment_turned_in, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  _buildConsentCard(
                    text: 'I confirm I have read the Patient Information Sheet and had all my questions answered.',
                    index: 0,
                    isDark: isDark, textColor: textColor, textGreyColor: textGreyColor,
                  ),
                  _buildConsentCard(
                    text: 'I explicitly consent to my oral images being captured, uploaded, and analyzed by the application.',
                    index: 1,
                    isDark: isDark, textColor: textColor, textGreyColor: textGreyColor,
                  ),
                  _buildConsentCard(
                    text: 'I agree to provide accurate medical history and cooperate in providing clear images.',
                    index: 2,
                    isDark: isDark, textColor: textColor, textGreyColor: textGreyColor,
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allAgreed ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    disabledForegroundColor: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _allAgreed ? 5 : 0,
                  ),
                  child: const Text(
                    'I Agree & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
