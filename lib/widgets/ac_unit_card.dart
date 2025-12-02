import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

class AcUnitCard extends StatefulWidget {
  final VoidCallback onTap;

  const AcUnitCard({super.key, required this.onTap});

  @override
  State<AcUnitCard> createState() => _AcUnitCardState();
}

class _AcUnitCardState extends State<AcUnitCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 230,
        margin: const EdgeInsets.all(15),
        child: Card(
          color: Colors.lightBlue[400]!,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 3,
                  child: Lottie.asset(
                    'images/animations/AC.json',
                    fit: BoxFit.contain,
                    animate: false,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  flex: 1,
                  child: Text(
                    'AC Unit Configuration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
