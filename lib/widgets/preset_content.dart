import 'package:flutter/cupertino.dart';
import 'package:home_automation_tablet/utils/app_state.dart';
import 'package:home_automation_tablet/utils/fb_utils.dart';
import 'package:provider/provider.dart';

class PresetContent extends StatefulWidget {
  final String presetTitle;
  final String? dbRef;

  const PresetContent({super.key, required this.presetTitle, this.dbRef});

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
      print('Loading from custom dbRef: ${widget.dbRef}');

      Map<String, dynamic>? data;

      if (widget.dbRef != null && widget.dbRef!.isNotEmpty) {
        data = await FirebaseUtils.readFromPath(widget.dbRef!);
      } else {
        data = await FirebaseUtils.readPreset(widget.presetTitle);
      }

      if (mounted) {
        if (data != null && data.isNotEmpty) {
          print('🔍 Raw data received: $data');

          // Extract the specific configuration based on the dbRef path
          Map<String, dynamic> extractedData = _extractConfigurationData(data);

          print('📦 Extracted data: $extractedData');

          setState(() {
            _applyDataToControllers(extractedData);
            isLoadingFromFirebase = false;
          });

          print('✅ Loaded ${widget.presetTitle} from Firebase');
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

  Map<String, dynamic> _extractConfigurationData(Map<String, dynamic> data) {
    // If dbRef is null or empty, return data as-is (for presets)
    if (widget.dbRef == null || widget.dbRef!.isEmpty) {
      return data;
    }

    // Get the last segment of the path (e.g., 'fire_sensor_configs')
    String configKey = widget.dbRef!.split('/').last;

    print('🔑 Looking for config key: $configKey');

    // Check if data already contains the specific config
    if (data.containsKey(configKey) && data[configKey] is Map) {
      return Map<String, dynamic>.from(data[configKey]);
    }

    // If data doesn't contain the key, it might already be the config we want
    // Check if it has the expected fields
    bool hasExpectedFields = false;

    switch (configKey) {
      case 'fire_sensor_configs':
      case 'gas_sensor_config':
      case 'window_sensor_config':
        hasExpectedFields =
            data.containsKey('alarm') || data.containsKey('notifications');
        break;
      case 'lights_config':
        hasExpectedFields =
            data.containsKey('access') || data.containsKey('notifications');
        break;
      default:
        hasExpectedFields = true; // Assume it's correct for unknown configs
    }

    if (hasExpectedFields) {
      return data;
    }

    // If we reach here, we couldn't find the config, return empty map
    print('⚠️ Could not extract config for $configKey, returning empty map');
    return {};
  }

  void _applyDataToControllers(Map<String, dynamic> configData) {
    print('🔧 Applying data to controllers');
    print('Config data: $configData');

    // AC Temperature
    if (configData.containsKey('ac_temp') && configData['ac_temp'] != null) {
      controllers['AC Temperature']?.text = '${configData['ac_temp']}°C';
    }

    // Lights
    if (configData.containsKey('lights') && configData['lights'] != null) {
      controllers['Lights']?.text = configData['lights'] == true ? 'On' : 'Off';
    }

    // Security
    if (configData.containsKey('security') && configData['security'] != null) {
      controllers['Security']?.text = configData['security'] == true
          ? 'Active'
          : 'Inactive';
    }

    // Curtains/Window
    if (configData.containsKey('window') && configData['window'] != null) {
      if (configData['window'] is bool) {
        controllers['Curtains']?.text = configData['window'] == true
            ? 'Open'
            : 'Closed';
      } else if (configData['window'] is String) {
        controllers['Curtains']?.text = configData['window'];
      }
    }

    // Alarm (for sensor configurations)
    if (configData.containsKey('alarm') && configData['alarm'] != null) {
      controllers['Alarm']?.text = configData['alarm'] == true ? 'On' : 'Off';
    }

    // Notifications (for sensor configurations)
    if (configData.containsKey('notifications') &&
        configData['notifications'] != null) {
      controllers['Notifications']?.text = configData['notifications'] == true
          ? 'Enabled'
          : 'Disabled';
    }

    // Access (for lights configuration)
    if (configData.containsKey('access') && configData['access'] != null) {
      controllers['Access']?.text = configData['access'] == true ? 'On' : 'Off';
    }

    print('✅ Applied data to controllers');
    print(
      'Controller values: ${controllers.map((k, v) => MapEntry(k, v.text))}',
    );
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
      Map<String, String> currentValues = {};
      controllers.forEach((key, controller) {
        currentValues[key] = controller.text;
      });

      print('💾 Saving ${widget.presetTitle}...');
      print('Values to save: $currentValues');

      if (widget.dbRef != null && widget.dbRef!.isNotEmpty) {
        await _saveToCustomPath(widget.dbRef!, currentValues);
      } else {
        await FirebaseUtils.savePreset(widget.presetTitle, currentValues);
      }

      if (mounted) {
        setState(() {
          isEditing = false;
          isSaving = false;
        });

        final appState = Provider.of<AppState>(context, listen: false);
        appState.notifyListeners();

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Success'),
            content: Text('${widget.presetTitle} has been saved successfully!'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );

        print('✅ Successfully saved ${widget.presetTitle}');
      }
    } catch (e) {
      print('❌ Error saving ${widget.presetTitle}: $e');

      if (mounted) {
        setState(() {
          isSaving = false;
        });

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error'),
            content: Text('Failed to save changes. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveToCustomPath(
    String path,
    Map<String, String> values,
  ) async {
    try {
      print('💾 Saving to custom path: $path');

      Map<String, dynamic> firebaseData = _convertToFirebaseFormat(values);

      print('Converted data: $firebaseData');

      await FirebaseUtils.writeToPath(path, firebaseData);

      print('✅ Successfully saved to $path');
    } catch (e) {
      print('❌ Error saving to custom path: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _convertToFirebaseFormat(Map<String, String> values) {
    Map<String, dynamic> firebaseData = {};

    values.forEach((key, value) {
      String firebaseKey = _getFirebaseKey(key);
      dynamic firebaseValue = _getFirebaseValue(key, value);

      if (firebaseValue != null) {
        firebaseData[firebaseKey] = firebaseValue;
      }
    });

    return firebaseData;
  }

  String _getFirebaseKey(String displayKey) {
    switch (displayKey) {
      case 'Alarm':
        return 'alarm';
      case 'Notifications':
        return 'notifications';
      case 'Access':
        return 'access';
      case 'AC Temperature':
        return 'ac_temp';
      case 'Lights':
        return 'lights';
      case 'Security':
        return 'security';
      case 'Curtains':
        return 'window';
      default:
        return displayKey.toLowerCase().replaceAll(' ', '_');
    }
  }

  dynamic _getFirebaseValue(String key, String value) {
    switch (key) {
      case 'Alarm':
        return value.toLowerCase() == 'on';
      case 'Notifications':
        return value.toLowerCase() == 'enabled';
      case 'Access':
        return value.toLowerCase() == 'on';
      case 'Lights':
        return value.toLowerCase() == 'on';
      case 'Security':
        return value.toLowerCase() == 'active';
      case 'Curtains':
        return value.toLowerCase() == 'open';
      case 'AC Temperature':
        String numericString = value.replaceAll(RegExp(r'[^0-9-]'), '');
        return int.tryParse(numericString) ?? 22;
      default:
        return value;
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
