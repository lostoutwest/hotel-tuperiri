import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulseController;

  bool connected = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _garagePressed() async {

    HapticFeedback.mediumImpact();

    setState(() {
      busy = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      busy = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.purple,
        content: const Text("Garage command sent"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Stack(

        fit: StackFit.expand,

        children: [

          Image.asset(
            "assets/garage.png",
            fit: BoxFit.cover,
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(.45),
                  Colors.black.withOpacity(.60),
                ],
              ),
            ),
          ),

          SafeArea(

            child: Padding(

              padding: const EdgeInsets.all(24),

              child: Column(

                children: [

                  const SizedBox(height: 20),

                  Container(

                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),

                    decoration: AppTheme.glassDecoration,

                    child: Row(

                      children: [

                        Icon(
                          Icons.circle,
                          color: connected
                              ? AppTheme.success
                              : AppTheme.error,
                          size: 14,
                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: Text(
                            connected
                                ? "Bluetooth Connected"
                                : "Garage Offline",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),

                        ),

                      ],

                    ),

                  ),

                  const Spacer(),

                  AnimatedBuilder(

                    animation: _pulseController,

                    builder: (_, child) {

                      final scale =
                          1 + (_pulseController.value * .05);

                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );

                    },

                    child: GestureDetector(

                      onTap: busy ? null : _garagePressed,

                      child: AnimatedContainer(

                        duration:
                            const Duration(milliseconds: 250),

                        width: busy ? 200 : 220,
                        height: busy ? 200 : 220,

                        decoration: BoxDecoration(

                          shape: BoxShape.circle,

                          color: AppTheme.purple,

                          boxShadow: AppTheme.neonGlow,

                        ),

                        child: Center(

                          child: busy

                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )

                              : const Icon(
                                  Icons.garage_rounded,
                                  color: Colors.white,
                                  size: 110,
                                ),

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: 40),

                  Text(
                    "GARAGE",
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Tap to Open",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color: Colors.white70,
                        ),
                  ),

                  const Spacer(),

                  TextButton.icon(

                    onPressed: () {},

                    icon: const Icon(Icons.settings),

                    label: const Text("Settings"),

                  ),

                  const SizedBox(height: 20),

                ],

              ),

            ),

          ),

        ],

      ),

    );
  }
}