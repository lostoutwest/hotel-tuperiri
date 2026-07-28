import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/garage_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _connectionTimer;

  bool connected = false;
  bool busy = false;
  bool pressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _checkConnection();

    _connectionTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkConnection(),
    );
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final ok = await GarageService.checkOnline();

    if (!mounted) return;

    setState(() {
      connected = ok;
    });
  }

  Future<void> _garagePressed() async {
    if (busy) return;
    HapticFeedback.mediumImpact();

    setState(() {
      busy = true;
      pressed = true;
    });

    final ok = await GarageService.pressButton();

    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 120));
    setState(() {
      busy = false;
      pressed = false;
      connected = ok;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? Colors.green : Colors.red,
        content: Text(
          ok ? "Garage Activated" : "Cannot Reach Garage",
        ),
      ),
    );

    _checkConnection();
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
                                ? "Garage Online"
                                : "Garage Offline",
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      final glow = 0.45 + (_pulseController.value * 0.35);
                      return GestureDetector(
                        onTap: busy ? null : _garagePressed,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: pressed ? 340 : 300,
                              height: pressed ? 340 : 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.purple.withOpacity(glow),
                                    blurRadius: pressed ? 180 : 130,
                                    spreadRadius: pressed ? 45 : 25,
                                  ),
                                ],
                              ),
                            ),
                            AnimatedScale(
                              duration: const Duration(milliseconds: 120),
                              scale: pressed ? 0.95 : 1,
                              child: busy
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Image.asset(
                                      'assets/icon.png',
                                      width: 220,
                                      filterQuality: FilterQuality.high,
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "HOTEL TUPERIRI",
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    connected
                        ? "Touch the Artwork"
                        : "Connect to GarageDoor Wi-Fi",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color: Colors.white70,
                        ),
                  ),

                  const Spacer(),

                  TextButton.icon(
                    onPressed: _checkConnection,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh Connection"),
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