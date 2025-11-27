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
      child: Container(
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
