import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'login.dart'; // Make sure this file exists and exports SignupScreen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyA2nv_zkbp-BP4Tl1fX2ngQcfdTTziHQv4',
          appId: '1:36995347433:android:2788dcd22211a6a4c9d178',
          messagingSenderId: '36995347433',
          projectId: 'resqintel',
        ),
      );
      debugPrint("✅ Firebase initialized.");
    } else {
      debugPrint("ℹ️ Firebase already initialized.");
    }
  } catch (e) {
    debugPrint("❌ Firebase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  bool _showWelcome = true;
  bool _showText = true;

  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _onTapContinue() {
    setState(() => _showText = false);

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _showWelcome = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQintel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        child: _showWelcome
            ? GestureDetector(
                key: const ValueKey('WelcomeScreen'),
                onTap: _onTapContinue,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('Assets/bg.png', fit: BoxFit.cover),
                    Center(
                      child: AnimatedOpacity(
                        opacity: _showText ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 700),
                        child: AnimatedBuilder(
                          animation: _waveAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                8 * (0.5 - _waveAnimation.value),
                              ),
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.9, end: 1.1)
                                    .animate(
                                      CurvedAnimation(
                                        parent: _waveAnimation,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      colors: [
                                        Colors.red.shade300,
                                        Colors.orange.shade400,
                                        Colors.yellow.shade400,
                                        Colors.red.shade300,
                                      ],
                                      stops: [
                                        (_waveAnimation.value - 0.3).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        (_waveAnimation.value - 0.15).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        (_waveAnimation.value + 0.15).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        (_waveAnimation.value + 0.3).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      ],
                                      begin: Alignment(-1, 0),
                                      end: Alignment(1, 0),
                                      tileMode: TileMode.mirror,
                                    ).createShader(bounds);
                                  },
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            '“Tap to continue”',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black87,
                                  offset: Offset(0, 3),
                                ),
                                Shadow(
                                  blurRadius: 25,
                                  color: Colors.redAccent,
                                  offset: Offset(0, 0),
                                ),
                              ],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const LoginScreen(key: ValueKey('LoginScreen')),
      ),
    );
  }
}
