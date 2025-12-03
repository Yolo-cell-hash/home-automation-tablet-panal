import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:animate_do/animate_do.dart';

class UserCardRow extends StatelessWidget {
  final String name;
  final Uint8List? imageData;

  const UserCardRow({super.key, required this.name, this.imageData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('You tapped a user - $name');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              imageData != null
                  ? GestureDetector(
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => FadeIn(
                            child: CupertinoAlertDialog(
                              title: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              content: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: InteractiveViewer(
                                  panEnabled: true,
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  child: Image.memory(
                                    imageData!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Close'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.memory(
                          imageData!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: CupertinoColors.systemRed,
                                size: 28,
                              ),
                        ),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        color: CupertinoColors.systemGrey,
                        size: 28,
                      ),
                    ),

              const SizedBox(width: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
