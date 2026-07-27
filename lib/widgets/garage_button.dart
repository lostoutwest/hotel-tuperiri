import 'package:flutter/material.dart';

class GarageButton extends StatelessWidget {

  final bool busy;
  final VoidCallback onPressed;

  const GarageButton({
    super.key,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: busy ? null : onPressed,

      child: AnimatedContainer(

        duration: const Duration(milliseconds: 250),

        width: busy ? 180 : 200,
        height: busy ? 180 : 200,

        decoration: BoxDecoration(

          shape: BoxShape.circle,

          color: Colors.blue,

          boxShadow: [

            BoxShadow(
              color: Colors.blue.withOpacity(.75),
              blurRadius: 50,
              spreadRadius: 5,
            )

          ],

        ),

        child: Center(

          child: busy
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : const Icon(
                  Icons.garage,
                  color: Colors.white,
                  size: 100,
                ),

        ),

      ),

    );

  }
}