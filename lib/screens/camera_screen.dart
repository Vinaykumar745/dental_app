import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/localization_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';
import '../widgets/video_tutorial_dialog.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _images = [null, null, null, null];
  int _currentStep = 0;
  bool _isPickingImage = false;

  final List<Map<String, dynamic>> _imageTypes = [
    {
      'title': 'Tongue',
      'subtitle': 'Top surface of tongue',
      'icon': Icons.medical_services,
      'color': const Color(0xFF7B1FA2),
      'instruction': 'Open your mouth wide and stick out your tongue.',
      'tip': 'Make sure the full top surface of the tongue is visible.',
      'videoPath': 'assets/videos/tongue.mp4',
    },
    {
      'title': 'Gums',
      'subtitle': 'Upper & lower gums',
      'icon': Icons.healing,
      'color': const Color(0xFFC62828),
      'instruction': 'Pull lips back to expose gums completely.',
      'tip': 'Good lighting helps capture gum color accurately.',
      'videoPath': 'assets/videos/gums.mp4',
    },
    {
      'title': 'Floor of Mouth',
      'subtitle': 'Under the tongue',
      'icon': Icons.panorama_horizontal,
      'color': const Color(0xFF1565C0),
      'instruction': 'Lift tongue to roof of mouth to expose the floor.',
      'tip': 'This area is critical for early cancer detection.',
      'videoPath': 'assets/videos/floor_of_mouth.mp4',
    },
    {
      'title': 'Buccal Mucosa',
      'subtitle': 'Inner cheek lining',
      'icon': Icons.face,
      'color': const Color(0xFF2E7D32),
      'instruction': 'Pull cheek outward gently to expose the inner lining.',
      'tip': 'Capture both left and right cheeks if possible.',
      'videoPath': 'assets/videos/buccal_mucosa.mp4',
    },
  ];

  int get _capturedCount => _images.where((e) => e != null).length;
  bool get _allCaptured => _capturedCount == 4;

  Future<bool> _validateImage(int index, XFile photo) async {
    // Show a loading dialog while validating with the backend
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text('Validating ${_imageTypes[index]['title']}...'),
            ],
          ),
        ),
      );
    }

    try {
      final expectedType = _imageTypes[index]['title'];
      final apiResult = await ApiService.validateImage(photo, expectedType);
      
      // Close the loading dialog
      if (mounted) Navigator.pop(context);

      if (apiResult.success) {
        final isValid = apiResult.data['valid'] == true;
        final detected = apiResult.data['detected'] ?? 'unknown';

        if (!isValid) {
          if (mounted) {
            final errorMsg = apiResult.data['error'];
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
                  SizedBox(width: 8),
                  Text('Incorrect Photo Type'),
                ]),
                content: Text(
                  errorMsg != null 
                      ? 'Error: $errorMsg\n\nPlease try again.'
                      : 'The AI detected a "$detected".\n\nThis slot is specifically for your $expectedType. Please take a clear picture of the correct area.',
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.tr('try_again')),
                  ),
                ],
              ),
            );
          }
          return false;
        }
        return true;
      } else {
        debugPrint("Validation failed or model not loaded: ${apiResult.error}");
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [
                Icon(Icons.error_outline, color: AppTheme.danger, size: 28),
                SizedBox(width: 8),
                Text('Validation Error'),
              ]),
              content: Text(
                'Could not validate the image. Please check your connection to the AI server.\n\nError: ${apiResult.error}',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return false; // Fail closed instead of open
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close dialog
      debugPrint("API validation error: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text('An unexpected error occurred during validation:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return false; // Fail closed
    }
  }

  Future<void> _pickFromCamera(int index) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (mounted) setState(() => _isPickingImage = false);
      if (photo != null && mounted) {
        setState(() => _isPickingImage = true); // keep loading overlay
        bool isValid = await _validateImage(index, photo);
        if (mounted) setState(() => _isPickingImage = false);
        
        if (isValid && mounted) {
          setState(() {
            _images[index] = photo;
            if (index < 3) _currentStep = index + 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPickingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery(int index) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (mounted) setState(() => _isPickingImage = false);
      if (photo != null && mounted) {
        setState(() => _isPickingImage = true); // keep loading overlay
        bool isValid = await _validateImage(index, photo);
        if (mounted) setState(() => _isPickingImage = false);
        
        if (isValid && mounted) {
          setState(() {
            _images[index] = photo;
            if (index < 3) _currentStep = index + 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPickingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showSourceDialog(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final hideTutorial = prefs.getBool('hide_tutorial') ?? false;

    if (hideTutorial) {
      _showActualSourceDialog(index);
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => VideoTutorialDialog(
          videoPath: _imageTypes[index]['videoPath'],
          onProceed: () => _showActualSourceDialog(index),
        ),
      );
    }
  }

  void _showActualSourceDialog(int index) {
    final type = _imageTypes[index];
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(type['icon'] as IconData, color: type['color'] as Color, size: 22),
          const SizedBox(width: 8),
          Text('Capture ${type['title']}'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type['instruction'] as String,
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 16),
            // Camera option
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _pickFromCamera(index);
                  });
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(AppLocalizations.tr('take_photo_with_camera')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Gallery option
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _pickFromGallery(index);
                  });
                },
                icon: const Icon(Icons.photo_library),
                label: Text(AppLocalizations.tr('choose_from_gallery')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            if (_images[index] != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _images[index] = null);
                },
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                label: Text(AppLocalizations.tr('remove_image'),
                    style: const TextStyle(color: AppTheme.danger)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.tr('cancel')),
          ),
        ],
      ),
    );
  }

  void _proceedToResults() {
    if (!_allCaptured) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          images: _images.map((e) => e!).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.tr('capture_oral_images')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$_capturedCount/4',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress bar
              Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.tr('progress'),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12)),
                      Text('${(_capturedCount / 4 * 100).toInt()}% Complete',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _capturedCount / 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ]),
              ),

              // (Patient info removed)

              // Image list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (ctx, index) {
                    final type = _imageTypes[index];
                    final image = _images[index];
                    final isCurrent = index == _currentStep;
                    final isCaptured = image != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCaptured
                              ? AppTheme.success
                              : isCurrent
                                  ? type['color'] as Color
                                  : Colors.grey.shade200,
                          width: isCurrent || isCaptured ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: isCaptured
                                    ? AppTheme.success
                                    : (type['color'] as Color).withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: isCaptured
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 22)
                                : Icon(type['icon'] as IconData,
                                    color: type['color'] as Color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(type['title'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppTheme.textDark)),
                                  if (isCurrent && !isCaptured) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: type['color'] as Color,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(AppLocalizations.tr('current'),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ]),
                                const SizedBox(height: 2),
                                Text(type['subtitle'] as String,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textGrey)),
                                if (isCaptured) ...[
                                  const SizedBox(height: 4),
                                  Text(AppLocalizations.tr('image_captured'),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ],
                            ),
                          ),
                          if (isCaptured)
                            GestureDetector(
                              onTap: () => _showSourceDialog(index),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb
                                    ? Image.network(image.path, width: 56, height: 56, fit: BoxFit.cover)
                                    : Image.file(File(image.path), width: 56, height: 56, fit: BoxFit.cover),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _showSourceDialog(index),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: type['color'] as Color,
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10))),
                              child: Text(AppLocalizations.tr('capture'),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              // Bottom button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: Column(children: [
                  if (!_allCaptured)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                          'Capture ${4 - _capturedCount} more image${4 - _capturedCount == 1 ? '' : 's'} to continue',
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 13)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _allCaptured ? _proceedToResults : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _allCaptured
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              _allCaptured
                                  ? Icons.psychology
                                  : Icons.lock_outline,
                              color: _allCaptured
                                  ? Colors.white
                                  : AppTheme.textGrey,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                              _allCaptured
                                  ? 'Analyze with AI'
                                  : 'Capture all 4 images first',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: _allCaptured
                                      ? Colors.white
                                      : AppTheme.textGrey,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),

          // Loading overlay when picking image
          if (_isPickingImage)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primary),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.tr('opening_camera'),
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.textGrey)),
                      ],
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