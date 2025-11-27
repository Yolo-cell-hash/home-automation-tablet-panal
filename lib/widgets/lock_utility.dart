import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation_tablet/widgets/sensor_card.dart';

class LockUtility extends StatefulWidget {
  const LockUtility({super.key});

  @override
  State<LockUtility> createState() => _LockUtilityState();
}

class _LockUtilityState extends State<LockUtility> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(15),
      height: 250,
      width: MediaQuery.of(context).size.width.clamp(0, 800),
      child: Card(
        color: Color(0xFF08306B),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Device Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SensorCard(
                    title: 'Front Door',
                    icon: 'images/smart-lock.png',
                    height: 150,
                    elevation: 0,
                  ),
                  SensorCard(
                    title: 'VDB',
                    icon: 'images/door-bell.png',
                    height: 150,
                    elevation: 0,
                  ),
                  SensorCard(
                    title: 'Connectivity',
                    icon: 'images/wi-fi-icon.png',
                    height: 150,
                    elevation: 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
