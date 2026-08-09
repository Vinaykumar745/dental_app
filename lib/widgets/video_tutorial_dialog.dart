import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class VideoTutorialDialog extends StatefulWidget {
  final VoidCallback onProceed;
  final String videoPath;
  
  const VideoTutorialDialog({super.key, required this.onProceed, required this.videoPath});

  @override
  State<VideoTutorialDialog> createState() => _VideoTutorialDialogState();
}

class _VideoTutorialDialogState extends State<VideoTutorialDialog> {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      }).catchError((e) {
        setState(() {
          _isError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleProceed() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hide_tutorial', true);
    }
    if (mounted) {
      Navigator.of(context).pop();
      widget.onProceed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black, // Dark background like the mockup
      insetPadding: const EdgeInsets.all(0), // Full width/height feel
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Text(
                    'How to Capture Images',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            // Video Section
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _isError
                          ? const Center(child: Text('Failed to load video', style: TextStyle(color: Colors.white)))
                          : _controller.value.isInitialized
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayer(_controller),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _controller.value.isPlaying
                                              ? _controller.pause()
                                              : _controller.play();
                                        });
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        alignment: Alignment.center,
                                        child: !_controller.value.isPlaying
                                            ? const Icon(Icons.play_circle_fill,
                                                size: 60, color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom White Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Follow the Video Guide',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionItem('1. Find a brightly lit room.'),
                  _buildInstructionItem('2. Open your mouth wide.'),
                  _buildInstructionItem('3. Position the camera exactly as shown to ensure an accurate AI analysis.'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _dontShowAgain,
                          onChanged: (val) {
                            setState(() {
                              _dontShowAgain = val ?? false;
                            });
                          },
                          activeColor: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Don\'t show this tutorial again',
                        style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF198754), // Exact green from mockup
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('I Understand, Proceed',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF6C757D), fontSize: 14, height: 1.4), // Muted text color
      ),
    );
  }
}
