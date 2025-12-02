import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation_tablet/widgets/sensor_card.dart';
import 'package:home_automation_tablet/screens/front_door_page.dart';
import 'package:home_automation_tablet/screens/vdb.dart';
import 'package:home_automation_tablet/screens/connectivity_page.dart';

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
      padding: EdgeInsets.only(top: 0),
      child: Card(
        color: Color(0xFF08306B),
        elevation: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Device Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 230,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SensorCard(
                    title: 'Front Door',
                    icon: 'images/smart-lock.png',
                    elevation: 0,
                    useNavigation: true,
                    navigationPage: FrontDoorPage(),
                  ),
                  SensorCard(
                    title: 'VDB',
                    icon: 'images/door-bell.png',
                    elevation: 0,
                    useNavigation: true,
                    navigationPage: VDB(),
                  ),
                  SensorCard(
                    title: 'Connectivity',
                    icon: 'images/wi-fi-icon.png',
                    elevation: 0,
                    useNavigation: true,
                    navigationPage: ConnectivityPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
