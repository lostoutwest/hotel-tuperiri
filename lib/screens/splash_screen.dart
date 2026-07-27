import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  late final Animation<double> _fade;

  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scale = Tween<double>(
      begin: .85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 2), () {

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {

            return FadeTransition(
              opacity: animation,
              child: child,
            );

          },
        ),
      );

    });

  }

  @override
  void dispose() {

    _controller.dispose();

    super.dispose();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppTheme.background,

      body: Stack(

        fit: StackFit.expand,

        children: [

          Image.asset(
            "assets/garage.png",
            fit: BoxFit.cover,
          ),

          Container(
            color: Colors.black.withOpacity(.55),
          ),

          Center(

            child: FadeTransition(

              opacity: _fade,

              child: ScaleTransition(

                scale: _scale,

                child: Column(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Container(

                      padding: const EdgeInsets.all(28),

                      decoration: BoxDecoration(

                        shape: BoxShape.circle,

                        boxShadow: AppTheme.neonGlow,

                      ),

                      child: const Icon(
                        Icons.garage_rounded,
                        color: Colors.white,
                        size: 120,
                      ),

                    ),

                    const SizedBox(height: 40),

                    Text(
                      "HOTEL TUPERIRI",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                            letterSpacing: 3,
                          ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Garage Controller",
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(
                            color: Colors.white70,
                          ),
                    ),

                  ],

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}