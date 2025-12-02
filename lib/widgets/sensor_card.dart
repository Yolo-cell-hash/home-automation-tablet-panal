import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_automation_tablet/widgets/preset_content.dart';

class SensorCard extends StatefulWidget {
  final String title;
  final String icon;
  final double? height;
  final double? elevation;
  final String dbRef;
  final bool useNavigation;
  final Widget? navigationPage;

  const SensorCard({
    super.key,
    required this.title,
    required this.icon,
    this.height,
    this.elevation,
    this.dbRef = '',
    this.useNavigation = false,
    this.navigationPage,
  });

  @override
  State<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> {
  void _handleTap(BuildContext context) {
    if (widget.useNavigation && widget.navigationPage != null) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (context) => widget.navigationPage!));
    } else {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return FadeIn(
            child: CupertinoAlertDialog(
              title: Text(
                '${widget.title} Preset',
                style: TextStyle(color: CupertinoColors.black),
              ),
              content: PresetContent(
                presetTitle: widget.title,
                dbRef: widget.dbRef,
              ),
              actions: [
                Center(
                  child: CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(color: CupertinoColors.systemBlue),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: widget.height ?? 230,
        margin: const EdgeInsets.all(15),
        child: GestureDetector(
          onTap: () => _handleTap(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.lightBlue[400]!,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(
                    0.1 * (widget.elevation ?? 4),
                  ),
                  blurRadius: widget.elevation ?? 4,
                  offset: Offset(0, (widget.elevation ?? 4) / 2),
                ),
              ],
            ),
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
                      color: CupertinoColors.white,
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
