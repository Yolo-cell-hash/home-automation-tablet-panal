import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:home_automation_tablet/utils/fb_utils.dart';

class AcUnitCard extends StatefulWidget {
  final VoidCallback onTap;

  const AcUnitCard({super.key, required this.onTap});

  @override
  State<AcUnitCard> createState() => _AcUnitCardState();
}

class _AcUnitCardState extends State<AcUnitCard> {
  void _showAcConfigDialog() async {
    // Show loading dialog with iOS style
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CupertinoActivityIndicator(radius: 20)),
    );

    try {
      final data = await FirebaseUtils.readFromPath(
        '/updates/ac_unit_configuration',
      );

      Navigator.of(context).pop();

      if (data != null && data['ac_unit_configuration'] != null) {
        final configData =
            data['ac_unit_configuration'] as Map<dynamic, dynamic>;
        final bool status = configData['status'] ?? false;
        final int temp = configData['temp'] ?? 22;
        final String presetConfigured =
            configData['preset_configured'] ?? 'None';

        _showEditableDialog(status, temp, presetConfigured);
      } else {
        _showErrorDialog('No configuration data found');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('Error loading configuration: $e');
    }
  }

  void _showEditableDialog(
    bool initialStatus,
    int initialTemp,
    String initialPreset,
  ) {
    bool status = initialStatus;
    int temp = initialTemp;
    String presetConfigured = initialPreset;
    final List<String> presets = [
      'None',
      'morning',
      'afternoon',
      'evening',
      'night',
    ];

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('AC Unit Configuration'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    CupertinoSwitch(
                      value: status,
                      onChanged: (value) => setState(() => status = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Temperature:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          setState(() => temp = (temp - 1).clamp(16, 30)),
                      child: const Icon(CupertinoIcons.minus_circle),
                    ),
                    Text(
                      '$temp°C',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          setState(() => temp = (temp + 1).clamp(16, 30)),
                      child: const Icon(CupertinoIcons.plus_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Preset:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: presets.indexOf(presetConfigured),
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() => presetConfigured = presets[index]);
                    },
                    children: presets
                        .map((preset) => Center(child: Text(preset)))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context).pop();
                await _saveConfiguration(status, temp, presetConfigured);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfiguration(bool status, int temp, String preset) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CupertinoActivityIndicator(radius: 20)),
    );

    try {
      final configData = {
        'status': status,
        'temp': temp,
        'preset_configured': preset,
      };

      await FirebaseUtils.writeToPath(
        '/updates/ac_unit_configuration',
        configData,
      );

      Navigator.of(context).pop();
      _showSuccessDialog('Configuration saved successfully');
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('Error saving configuration: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showAcConfigDialog,
      child: Container(
        height: 230,
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.lightBlue[400],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                  style: const TextStyle(
                    color: CupertinoColors.white,
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
    );
  }
}
