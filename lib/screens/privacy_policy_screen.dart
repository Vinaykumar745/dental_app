import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr('privacy_policy')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: June 18, 2026',
              style: TextStyle(
                color: textGreyColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24),
            _buildSection(
              title: '1. Data Collection',
              content: 'We collect images and basic demographic information (such as age and gender) solely for the purpose of analyzing oral lesions. We do not collect personally identifiable information (PII) beyond what is explicitly provided by the user for account management.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '2. Use of AI and Images',
              content: 'Images uploaded for scanning are processed by our secure AI servers. Anonymized images may be retained to improve the accuracy of our machine learning models, in accordance with medical data research guidelines.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '3. Data Security',
              content: 'We implement industry-standard encryption protocols (TLS/SSL) for data transmission. All stored data is encrypted at rest using AES-256 standards to prevent unauthorized access.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '4. Third-Party Sharing',
              content: 'We do not sell, trade, or otherwise transfer your data to outside parties. This does not include trusted third parties who assist us in operating our application, provided those parties agree to keep this information confidential.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            _buildSection(
              title: '5. User Rights',
              content: 'You have the right to request access to, modification of, or deletion of your personal data at any time. To exercise these rights, please contact our support team.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            SizedBox(height: 40),
            Center(
              child: Text(
                'By using DentalScan AI, you agree to this Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color textColor,
    required Color textGreyColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: textGreyColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
