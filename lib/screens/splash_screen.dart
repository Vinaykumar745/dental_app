import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import 'package:http/http.dart' as http;
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../services/auth_state.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnim;
  String _statusText = 'Connecting to server...';

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _logoController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _startAnimations();
    _wakeUpServer(); // Wake up Render server immediately
  }

  // This wakes up the Render server while splash is showing
  void _wakeUpServer() async {
    try {
      if (mounted) setState(() => _statusText = 'Waking up server...');
      await http
          .get(Uri.parse('${ApiService.baseUrl}/health'))
          .timeout(const Duration(seconds: 55));
      if (mounted) setState(() => _statusText = 'Server ready!');
    } catch (e) {
      if (mounted) setState(() => _statusText = 'Initializing...');
    }
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _textController.forward();
    // Wait at least 3 seconds on splash
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    _navigateNext();
  }

  void _navigateNext() async {
    Widget nextScreen;
    if (AuthState.isLoggedIn) {
      // Check if token still valid
      final result = await ApiService.getCurrentUser()
          .timeout(const Duration(seconds: 10))
          .catchError((_) => ApiResult(success: false));
      nextScreen = result.success
          ? const DashboardScreen()
          : const AuthScreen();
      if (!result.success) await AuthState.clear();
    } else {
      nextScreen = const AuthScreen();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF1976D2),
              Color(0xFF00ACC1),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
                top: -60,
                right: -60,
                child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05)))),
            Positioned(
                bottom: -80,
                left: -40,
                child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05)))),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_logoController, _pulseController]),
                    builder: (context, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value * _pulseAnim.value,
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5)
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/dental_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) => FadeTransition(
                      opacity: _textOpacity,
                      child:
                          SlideTransition(position: _textSlide, child: child),
                    ),
                    child: Column(
                      children: [
                        Text(AppLocalizations.tr('dentalscan_ai'),
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.0)),
                        SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(AppLocalizations.tr('aipowered_oral_cancer_detection'),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80),
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) =>
                        FadeTransition(opacity: _textOpacity, child: child),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8)),
                              strokeWidth: 2.5),
                        ),
                        SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _textController,
                          builder: (_, __) => Text(
                            _statusText,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) =>
                    FadeTransition(opacity: _textOpacity, child: child),
                child: Text(AppLocalizations.tr('version_100__for_medical_use'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}