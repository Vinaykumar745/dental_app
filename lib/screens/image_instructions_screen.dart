import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';

class ImageInstructionsScreen extends StatelessWidget {
  const ImageInstructionsScreen({super.key});

  Widget _buildInstructionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('How to take photos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You will need to capture 4 clear images of your mouth.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildInstructionItem(
                      icon: Icons.wb_sunny,
                      color: Colors.orange,
                      title: 'Find good lighting',
                      description: 'Stand in front of a mirror with good lighting, preferably near a window during daytime.',
                    ),
                    _buildInstructionItem(
                      icon: Icons.filter_center_focus,
                      color: Colors.blue,
                      title: 'Keep it in focus',
                      description: 'Make sure your camera is focused on your mouth. A blurry photo cannot be analyzed.',
                    ),
                    _buildInstructionItem(
                      icon: Icons.medical_services,
                      color: Colors.purple,
                      title: 'Follow the 4 steps',
                      description: 'You will take pictures of your tongue, gums, under the tongue, and inside cheeks.',
                    ),
                    _buildInstructionItem(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                      title: 'AI Verification',
                      description: 'Our AI will instantly verify if the photo is usable. If it is blurry or incorrect, it will ask you to retake it.',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CameraScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'I am ready, start camera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
