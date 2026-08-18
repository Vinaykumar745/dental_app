import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FindDentistScreen extends StatelessWidget {
  const FindDentistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Dentist', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 80, color: AppTheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              const Text(
                'Dentist Directory',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              const Text(
                'This feature is coming soon. You will be able to find and book appointments with certified dentists in your area directly from the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGrey, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Go Back'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
