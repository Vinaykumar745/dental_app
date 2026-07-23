import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextDark : AppTheme.textDark;
    final textGreyColor = isDark ? AppTheme.darkTextGrey : AppTheme.textGrey;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr('about_app')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/images/dental_logo.png', fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'DentalScan AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
            SizedBox(height: 40),
            _buildSection(
              title: 'Our Mission',
              content: 'DentalScan AI aims to revolutionize oral healthcare by providing an advanced AI-powered tool for early detection and assessment of oral cancer risks. We empower dental professionals with state-of-the-art technology to make informed clinical decisions.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            SizedBox(height: 24),
            _buildSection(
              title: 'How It Works',
              content: 'Using highly-trained convolutional neural networks, our system analyzes oral lesion images captured via smartphone cameras. It provides a real-time risk assessment, probability scoring, and clinical recommendations based on global medical datasets.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            SizedBox(height: 24),
            _buildSection(
              title: 'Medical Disclaimer',
              content: 'DentalScan AI is designed to assist dental professionals and should not be used as a standalone diagnostic tool. Always consult a certified medical practitioner or oncologist for a definitive diagnosis.',
              textColor: textColor,
              textGreyColor: textGreyColor,
            ),
            SizedBox(height: 40),
            Text(
              '© 2026 DentalScan AI. All rights reserved.',
              style: TextStyle(color: textGreyColor, fontSize: 12),
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
    return Column(
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
        SizedBox(height: 10),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: textGreyColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
