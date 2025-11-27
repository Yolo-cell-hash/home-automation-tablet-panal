import 'package:flutter/material.dart';
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
    'Window Sensor Configuration': {'Notifications': 'Enabled'},
    'Lights Configuration': {'Access': 'On', 'Notifications': 'Enabled'},
  };

  // Define fields that should use dropdowns and their options
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
      controllers[key] = TextEditingController(text: presetConfig[key]);
    }
  }

  /// Load preset data from Firebase
  Future<void> loadPresetFromFirebase() async {
    try {
      final presetData = await FirebaseUtils.readPreset(widget.presetTitle);

      if (presetData != null && mounted) {
        setState(() {
          // Update controllers with Firebase data
          if (presetData['ac_temp'] != null) {
            controllers['AC Temperature']?.text = '${presetData['ac_temp']}°C';
          }
          if (presetData['lights'] != null) {
            controllers['Lights']?.text = presetData['lights'] ? 'On' : 'Off';
          }
          if (presetData['security'] != null) {
            controllers['Security']?.text = presetData['security']
                ? 'Active'
                : 'Inactive';
          }
          if (presetData['window'] != null) {
            controllers['Curtains']?.text = presetData['window']
                ? 'Open'
                : 'Closed';
          }
        });
      }
    } catch (e) {
      print('Error loading preset from Firebase: $e');
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
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

      // Create a map with the updated values
      Map<String, String> updatedPreset = {};
      controllers.forEach((key, controller) {
        updatedPreset[key] = controller.text;
      });

      // Save to Firebase
      await FirebaseUtils.savePreset(widget.presetTitle, updatedPreset);

      print('Saving ${widget.presetTitle} preset: $updatedPreset');

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      // Show success confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('${widget.presetTitle} preset saved successfully! '),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to save preset: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
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

    // Ensure current value is in options, if not add it
    if (!options.contains(currentValue) && currentValue.isNotEmpty) {
      options.add(currentValue);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white54),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue.isNotEmpty ? currentValue : null,
          isExpanded: true,
          hint: Text(
            'Select $fieldName',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          style: TextStyle(fontSize: 14, color: Colors.black87),
          items: options.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                controller.text = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white54),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget buildDisplayContainer(TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white54),
      ),
      child: Text(
        controller.text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
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
          // Configuration items
          ...controllers.entries
              .map((entry) => buildConfigItem(entry.key, entry.value))
              .toList(),

          SizedBox(height: 20),

          // Action buttons when editing
          if (isEditing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isSaving ? null : saveChanges,
                  icon: isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(Icons.save, size: 16),
                  label: Text(isSaving ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : resetToDefaults,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],

          // Edit/Cancel button
          Center(
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : toggleEdit,
              icon: Icon(isEditing ? Icons.cancel : Icons.edit, size: 16),
              label: Text(isEditing ? 'Cancel' : 'Edit Preset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEditing ? Colors.red : Colors.blue[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
