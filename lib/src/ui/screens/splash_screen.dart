import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Make sure you have defined AppColors.primary somewhere, e.g.:
class AppColors {
  static const primary = Color(0xFFF2E5E3);
}

class SplashScreen extends StatefulWidget {
  /// How long the splash shows before navigating (in seconds)
  final int duration;
  /// The next page to navigate to
  final Widget nextPage;

  const SplashScreen({
    Key? key,
    this.duration = 250,
    required this.nextPage,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule navigation to nextPage after [duration] seconds
    Timer(Duration(seconds: widget.duration), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextPage),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background color
          Container(color: AppColors.primary),

          // Faint outline logo as background
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.2,
              child: SvgPicture.asset(
                'assets/images/login_new.svg',
                width: MediaQuery.of(context).size.width, // full width
                height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
                fit: BoxFit.fitWidth, // scales to width
              ),
            ),
          ),





          // Foreground content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: width * 0.65,
                  height: height * 0.18,
                ),
                const SizedBox(height: 20),
                const Text(
                  'تسجيل الحضور',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF551B21),
                    fontSize: 32,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
