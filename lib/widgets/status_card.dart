import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {

  final bool online;

  const StatusCard({
    super.key,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white24,
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(
            Icons.circle,
            color: online ? Colors.green : Colors.red,
            size: 14,
          ),

          const SizedBox(width: 10),

          Text(
            online ? "Garage Online" : "Garage Offline",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

        ],
      ),
    );

  }
}