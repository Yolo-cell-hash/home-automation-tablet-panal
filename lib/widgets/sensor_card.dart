import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation_tablet/widgets/preset_content.dart';

class SensorCard extends StatefulWidget {
  final String title;
  final String icon;
  final double? height;
  final double? elevation;

  const SensorCard({
    super.key,
    required this.title,
    required this.icon,
    this.height,
    this.elevation,
  });

  @override
  State<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: widget.height ?? 230,
        margin: const EdgeInsets.all(15),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return FadeIn(
                  child: AlertDialog(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    title: Text(
                      '${widget.title} Preset',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: PresetContent(presetTitle: widget.title),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Close',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Card(
            color: Colors.lightBlue[400]!,
            elevation: widget.elevation ?? 4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.6,
                    child: Image.asset(widget.icon, height: 100, width: 100),
                  ),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
