import 'package:flutter/cupertino.dart';
import 'package:home_automation_tablet/utils/app_state.dart';
import 'package:home_automation_tablet/utils/fb_utils.dart';
import 'package:provider/provider.dart';

class PresetContent extends StatefulWidget {
  final String presetTitle;

  const PresetContent({super.key, required this.presetTitle});

  @override
  State<PresetContent> createState() => _PresetContentState();
}

class _PresetContentState extends State<PresetContent> {
  bool isEditing = false;
  bool isSaving = false;
  bool isLoadingFromFirebase = true;
  late Map<String, TextEditingController> controllers;

  Map<String, Map<String, String>> defaultPresets = {
    'Morning': {
      'AC Temperature': '22°C',
      'Lights': 'Off',
      'Curtains': 'Open',
      'Security': 'Inactive',
    },
    'Afternoon': {
      'AC Temperature': '24°C',
      'Lights': 'Off',
      'Curtains': 'Partially Open',
      'Security': 'Active',
    },
    'Evening': {
      'AC Temperature': '23°C',
      'Lights': 'On',
      'Curtains': 'Closed',
      'Security': 'Active',
    },
    'Night': {
      'AC Temperature': '20°C',
      'Lights': 'On',
      'Curtains': 'Closed',
      'Security': 'Active',
    },
    'Fire Sensor Configuration': {'Alarm': 'On', 'Notifications': 'Enabled'},
    'Gas Sensor Configuration': {'Alarm': 'On', 'Notifications': 'Enabled'},
    'Window Sensor Configuration': {'Alarm': 'On', 'Notifications': 'Enabled'},
    'Lights Configuration': {'Access': 'On', 'Notifications': 'Enabled'},
  };

  Map<String, List<String>> dropdownOptions = {
    'Alarm': ['On', 'Off'],
    'Notifications': ['Enabled', 'Disabled'],
    'Access': ['On', 'Off'],
    'Security': ['Active', 'Inactive'],
    'Curtains': ['Open', 'Closed'],
    'Lights': ['Off', 'On'],
  };

  @override
  void initState() {
    super.initState();
    initializeControllers();
    loadPresetFromFirebase();
  }

  void initializeControllers() {
    controllers = {};
    final presetConfig = defaultPresets[widget.presetTitle] ?? {};

    for (String key in presetConfig.keys) {
      controllers[key] = TextEditingController(text: '');
    }
  }

  Future<void> loadPresetFromFirebase() async {
    try {
      print('Loading ${widget.presetTitle} from Firebase...');

      final presetData = await FirebaseUtils.readPreset(widget.presetTitle);

      if (mounted) {
        if (presetData != null && presetData.isNotEmpty) {
          setState(() {
            _applyFirebaseData(presetData);
            isLoadingFromFirebase = false;
          });
          print('✅ Loaded ${widget.presetTitle} from Firebase: $presetData');
        } else {
          setState(() {
            _loadDefaultValues();
            isLoadingFromFirebase = false;
          });
          print(
            '⚠️ No Firebase data, using defaults for ${widget.presetTitle}',
          );
        }
      }
    } catch (e) {
      print('❌ Error loading ${widget.presetTitle} from Firebase: $e');
      if (mounted) {
        setState(() {
          _loadDefaultValues();
          isLoadingFromFirebase = false;
        });

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Connection Error'),
            content: Text(
              'Failed to load ${widget.presetTitle} from database. Using default values.',
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _applyFirebaseData(Map<String, dynamic> presetData) {
    // Check if data is nested (e.g., morning_preset inside morning_preset)
    String presetKey = '${widget.presetTitle.toLowerCase()}_preset';
    Map<String, dynamic>? actualPresetData;

    if (presetData.containsKey(presetKey)) {
      // Data is nested, extract the actual preset
      actualPresetData = Map<String, dynamic>.from(presetData[presetKey]);
      print('📦 Extracting nested preset data: $actualPresetData');
    } else {
      // Data is already in the correct format
      actualPresetData = presetData;
    }

    // AC Temperature
    if (actualPresetData['ac_temp'] != null) {
      controllers['AC Temperature']?.text = '${actualPresetData['ac_temp']}°C';
    }

    // Lights
    if (actualPresetData['lights'] != null) {
      controllers['Lights']?.text = actualPresetData['lights'] == true
          ? 'On'
          : 'Off';
    }

    // Security
    if (actualPresetData['security'] != null) {
      controllers['Security']?.text = actualPresetData['security'] == true
          ? 'Active'
          : 'Inactive';
    }

    // Curtains/Window
    if (actualPresetData['window'] != null) {
      if (actualPresetData['window'] is bool) {
        controllers['Curtains']?.text = actualPresetData['window'] == true
            ? 'Open'
            : 'Closed';
      } else if (actualPresetData['window'] is String) {
        controllers['Curtains']?.text = actualPresetData['window'];
      }
    }

    // Alarm
    if (actualPresetData['alarm'] != null) {
      controllers['Alarm']?.text = actualPresetData['alarm'] == true
          ? 'On'
          : 'Off';
    }

    // Notifications
    if (actualPresetData['notifications'] != null) {
      controllers['Notifications']?.text =
          actualPresetData['notifications'] == true ? 'Enabled' : 'Disabled';
    }

    // Access
    if (actualPresetData['access'] != null) {
      controllers['Access']?.text = actualPresetData['access'] == true
          ? 'On'
          : 'Off';
    }

    print('✅ Applied preset data to controllers');
  }

  void _loadDefaultValues() {
    final defaultConfig = defaultPresets[widget.presetTitle] ?? {};
    controllers.forEach((key, controller) {
      if (defaultConfig.containsKey(key)) {
        controller.text = defaultConfig[key]!;
      }
    });
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool isDropdownField(String fieldName) {
    return dropdownOptions.containsKey(fieldName);
  }

  void toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  Future<void> saveChanges() async {
    setState(() {
      isSaving = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      Map<String, String> updatedPreset = {};
      controllers.forEach((key, controller) {
        updatedPreset[key] = controller.text;
      });

      await FirebaseUtils.savePreset(widget.presetTitle, updatedPreset);

      print('Saving ${widget.presetTitle} preset: $updatedPreset');

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Success'),
            content: Text('${widget.presetTitle} preset saved successfully!'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error'),
            content: Text('Failed to save preset: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void resetToDefaults() {
    final defaultConfig = defaultPresets[widget.presetTitle] ?? {};
    setState(() {
      controllers.forEach((key, controller) {
        if (defaultConfig.containsKey(key)) {
          controller.text = defaultConfig[key]!;
        }
      });
    });
  }

  Widget buildConfigItem(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.black,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: isEditing
                ? (isDropdownField(title)
                      ? buildDropdown(title, controller)
                      : buildTextField(controller))
                : buildDisplayContainer(controller),
          ),
        ],
      ),
    );
  }

  Widget buildDropdown(String fieldName, TextEditingController controller) {
    List<String> options = dropdownOptions[fieldName] ?? [];
    String currentValue = controller.text;

    if (!options.contains(currentValue) && currentValue.isNotEmpty) {
      options.add(currentValue);
    }

    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) {
            int selectedIndex = options.indexOf(currentValue);
            if (selectedIndex == -1) selectedIndex = 0;

            return Container(
              height: 250,
              color: CupertinoColors.systemBackground,
              child: Column(
                children: [
                  Container(
                    height: 44,
                    color: CupertinoColors.systemGrey6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoButton(
                          child: Text('Done'),
                          onPressed: () {
                            setState(() {
                              controller.text = options[selectedIndex];
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedIndex,
                      ),
                      onSelectedItemChanged: (int index) {
                        selectedIndex = index;
                      },
                      children: options.map((String value) {
                        return Center(child: Text(value));
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                currentValue.isNotEmpty ? currentValue : 'Select $fieldName',
                style: TextStyle(
                  fontSize: 14,
                  color: currentValue.isNotEmpty
                      ? CupertinoColors.black
                      : CupertinoColors.systemGrey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              color: CupertinoColors.systemGrey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: CupertinoTextField(
        controller: controller,
        style: TextStyle(fontSize: 14, color: CupertinoColors.black),
        decoration: BoxDecoration(),
        padding: EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget buildDisplayContainer(TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: Text(
        controller.text,
        style: TextStyle(
          fontSize: 14,
          color: CupertinoColors.white,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...controllers.entries
              .map((entry) => buildConfigItem(entry.key, entry.value))
              .toList(),
          SizedBox(height: 20),
          if (isEditing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: CupertinoColors.activeGreen,
                  onPressed: isSaving ? null : saveChanges,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSaving)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CupertinoActivityIndicator(radius: 8),
                        )
                      else
                        Icon(CupertinoIcons.check_mark, size: 16),
                      SizedBox(width: 4),
                      Text(isSaving ? 'Saving...' : 'Save'),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: CupertinoColors.systemOrange,
                  onPressed: isSaving ? null : resetToDefaults,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.refresh, size: 16),
                      SizedBox(width: 4),
                      Text('Reset'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
          Center(
            child: CupertinoButton(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: isEditing
                  ? CupertinoColors.systemRed
                  : CupertinoColors.activeBlue,
              onPressed: isSaving ? null : toggleEdit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEditing ? CupertinoIcons.xmark : CupertinoIcons.pencil,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    isEditing ? 'Cancel' : 'Edit Preset',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
