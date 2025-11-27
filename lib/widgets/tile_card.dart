import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:home_automation_tablet/utils/app_state.dart';
import 'package:animate_do/animate_do.dart';

class TileCard extends StatefulWidget {
  final int flex;
  final Color tileColor;
  final String title;
  final double height;
  final String? icon;
  final bool isStatusBar;
  final bool? isImageTile;
  final VoidCallback callBack;
  final bool? isUserProfileTile;
  final bool useExpanded; // Add this parameter

  const TileCard({
    super.key,
    required this.height,
    this.isUserProfileTile,
    this.isImageTile,
    required this.flex,
    required this.title,
    required this.tileColor,
    this.icon,
    required this.isStatusBar,
    required this.callBack,
    this.useExpanded = true, // Default to true for backward compatibility
  });

  @override
  State<TileCard> createState() => _TileCardState();
}

class _TileCardState extends State<TileCard> {
  Widget _buildCardContent() {
    if (widget.icon == null && widget.isStatusBar == false) {
      return SizedBox(
        height: widget.height,
        child: Card(
          color: widget.tileColor,
          elevation: 4,
          margin: const EdgeInsets.all(15),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.title.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    } else if (widget.isStatusBar == true) {
      final appState = Provider.of<AppState>(context, listen: true);
      return GestureDetector(
        onTap: widget.callBack,
        child: SizedBox(
          height: widget.height,
          child: Card(
            color: widget.tileColor,
            elevation: 4,
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.wifi,
                    color: appState.isConnected ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  Icon(
                    CupertinoIcons.video_camera_solid,
                    color: Colors.white,
                    size: 32,
                  ),
                  Tada(
                    animate: appState.isFireActive,
                    infinite: appState.isFireActive,
                    child: Icon(
                      CupertinoIcons.flame_fill,
                      color: appState.isFireActive ? Colors.red : Colors.white,
                      size: 32,
                    ),
                  ),
                  Tada(
                    animate: appState.isWindowOpenActive,
                    infinite: appState.isWindowOpenActive,
                    child: Icon(
                      CupertinoIcons.uiwindow_split_2x1,
                      color: appState.isWindowOpenActive
                          ? Colors.red
                          : Colors.white,
                      size: 32,
                    ),
                  ),
                  Tada(
                    animate: appState.isGasLeakActive,
                    infinite: appState.isGasLeakActive,
                    child: Icon(
                      Icons.gas_meter,
                      color: appState.isGasLeakActive
                          ? Colors.red
                          : Colors.white,
                      size: 32,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.lightbulb_fill,
                    color: appState.isLightsOn ? Colors.yellow : Colors.white,
                    size: 32,
                  ),
                  Icon(
                    CupertinoIcons.bell_solid,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (widget.isStatusBar == false && widget.isImageTile == true) {
      return GestureDetector(
        onTap: widget.callBack,
        child: SizedBox(
          height: widget.height,
          child: Card(
            color: widget.tileColor,
            elevation: 4,
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 3,
                    child: Lottie.asset(
                      widget.icon!,
                      height: widget.height * 0.6,
                      width: widget.height * 0.6,
                      animate: false,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    flex: 1,
                    child: Text(
                      widget.title.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
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
    } else if (widget.isUserProfileTile == true) {
      return SizedBox(
        height: widget.height,
        child: GestureDetector(
          onTap: () {
            print('User Profile Clicked');
          },
          child: Card(
            color: widget.tileColor,
            elevation: 4,
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: widget.height * 0.7,
                    width: widget.height * 0.7,
                    child: Lottie.asset(
                      widget.icon!,
                      height: widget.height * 1.0,
                      width: widget.height * 1.0,
                      animate: false,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
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
    } else {
      return GestureDetector(
        onTap: widget.callBack,
        child: SizedBox(
          height: widget.height,
          child: Card(
            color: widget.tileColor,
            elevation: 4,
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 3,
                    child: Lottie.asset(
                      widget.icon!,
                      height: widget.height * 0.6,
                      width: widget.height * 0.6,
                      animate: false,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    flex: 1,
                    child: Text(
                      widget.title.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
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

  @override
  Widget build(BuildContext context) {
    Widget cardContent = _buildCardContent();

    // Conditionally wrap with Expanded based on useExpanded parameter
    if (widget.useExpanded) {
      return Expanded(flex: widget.flex, child: cardContent);
    } else {
      return cardContent;
    }
  }
}
