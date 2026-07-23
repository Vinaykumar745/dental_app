import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';

class TutorialScreen extends StatefulWidget {
  final PatientModel patient;

  const TutorialScreen({super.key, required this.patient});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late VideoPlayerController _controller;
  bool _dontShowAgain = false;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use the real clinical tutorial video downloaded into assets
    _controller = VideoPlayerController.asset('assets/videos/tutorial.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceedToCamera() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('skip_tutorial', true);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CameraScreen(patient: widget.patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: _proceedToCamera,
                  ),
                  Expanded(
                    child: Text(
                      'How to Capture Images',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _isVideoInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Follow the Video Guide',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Find a brightly lit room.\n2. Open your mouth wide.\n3. Position the camera exactly as shown to ensure an accurate AI analysis.',
                    style: TextStyle(fontSize: 16, color: AppTheme.textGrey, height: 1.5),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        activeColor: AppTheme.primary,
                        onChanged: (val) {
                          setState(() {
                            _dontShowAgain = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(AppLocalizations.tr('dont_show_this_tutorial_again'), style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _proceedToCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(AppLocalizations.tr('i_understand_open_camera'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
