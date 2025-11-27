import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation_tablet/widgets/preset_content.dart';
import 'package:animate_do/animate_do.dart';

class PresetsTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const PresetsTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<PresetsTile> createState() => _PresetsTileState();
}

class _PresetsTileState extends State<PresetsTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return FadeIn(
              child: CupertinoAlertDialog(
                title: Text(
                  '${widget.title} Preset',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                content: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: PresetContent(presetTitle: widget.title),
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent),
          color: Colors.blue[900],
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        margin: EdgeInsets.all(5.0),
        padding: EdgeInsets.all(10.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(widget.icon),
              SizedBox(width: 25),
              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(width: 30),
              Icon(CupertinoIcons.chevron_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
