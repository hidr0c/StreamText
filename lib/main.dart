import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PXT Test CLGT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(8, 218, 209, 1)),
      ),
      home: const InputManager(),
    );
  }
}

class InputManager extends StatefulWidget {
  const InputManager({super.key});

  @override
  State<InputManager> createState() => _InputManagerState();
}

class _InputManagerState extends State<InputManager> {
  final List<TextEditingController> _nameControllers = [TextEditingController()];
  final List<TextEditingController> _teamControllers = [TextEditingController()];
  final TextEditingController _roundController = TextEditingController();
  String dropdownValue = 'Manual Input';
  List<String> jsonOptions = [];

  final Color _appColor = const Color.fromRGBO(8, 218, 209, 1); // Default to RGB(8, 218, 209)
  Color _textColor = Colors.black; // Default text color
  String _fontFamily = 'Roboto';

  bool _showTeamColumn = true;
  File? _uploadedJsonFile;

  bool _showRound = true;
  bool _showTeam = true;
  bool _showName = true;
  bool _isRoundDropdown = false; // Track if Round is dropdown
  bool _isTeamNameDropdown = false; // Track if Team & Name are dropdown

  @override
  void initState() {
    super.initState();
    _loadJsonOptions();
    _updateTextColor(); // Set initial text color based on app color
  }

  void _loadJsonOptions() async {
    try {
      final file = File('name.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        setState(() {
          jsonOptions = List<String>.from(data);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _saveToTxt() async {
    final name = _nameControllers.map((c) => c.text).join(', ');
    final team = _teamControllers.map((c) => c.text).join(', ');
    final round = _roundController.text;

    final content = 'Name: $name\nTeam: $team\nRound: $round';
    final file = File('output.txt');
    await file.writeAsString(content);
  }

  void _saveToJson() async {
    final names = _nameControllers.map((c) => c.text).toList();
    final teams = _teamControllers.map((c) => c.text).toList();
    final round = _roundController.text;

    final data = {
      'round': round,
      'teams': teams,
      'names': names,
    };

    final file = File('output.json');
    await file.writeAsString(jsonEncode(data));
  }

  void _addInputField(List<TextEditingController> controllers) {
    if (controllers.length < 4) {
      setState(() {
        controllers.add(TextEditingController());
      });
    }
  }

  void _removeInputField(List<TextEditingController> controllers) {
    if (controllers.length > 1) {
      setState(() {
        controllers.removeLast();
      });
    }
  }

  void _toggleTeamColumn() {
    setState(() {
      _showTeamColumn = !_showTeamColumn;
    });
  }

  void _changeFontFamily() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Font Family', style: TextStyle(color: _textColor)),
          content: TextField(
            onSubmitted: (value) {
              setState(() {
                _fontFamily = value;
              });
              Navigator.of(context).pop();
            },
            decoration: InputDecoration(
              hintText: 'Font Family (e.g., Arial)',
              hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
            ),
            style: TextStyle(color: _textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: _textColor)),
            ),
          ],
        );
      },
    );
  }

  void _updateTextColor() {
    // Calculate luminance of the app color
    double luminance = 0.299 * _appColor.red + 0.587 * _appColor.green + 0.114 * _appColor.blue;
    setState(() {
      _textColor = luminance > 128 ? Colors.black : Colors.white;
    });
  }

  void _uploadJsonFile() async {
    // Simulate file upload (replace with actual file picker logic if needed)
    final file = File('uploaded.json');
    if (await file.exists()) {
      setState(() {
        _uploadedJsonFile = file;
      });
    }
  }

  void _saveIndividualFile(String type, String value, int index) async {
    final fileName = '$type${index + 1}.txt';
    final file = File(fileName);
    await file.writeAsString(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PXT Test CLGT', style: TextStyle(color: _textColor)),
        backgroundColor: _appColor,
        elevation: 2,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: Text('Settings', style: TextStyle(color: _textColor)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      fontFamily: _fontFamily,
                      showRound: _showRound,
                      showTeam: _showTeam,
                      showName: _showName,
                      isRoundDropdown: _isRoundDropdown,
                      isTeamNameDropdown: _isTeamNameDropdown,
                      onFontChanged: (font) => setState(() => _fontFamily = font),
                      onRoundVisibilityChanged: (visible) => setState(() => _showRound = visible),
                      onTeamVisibilityChanged: (visible) => setState(() => _showTeam = visible),
                      onNameVisibilityChanged: (visible) => setState(() => _showName = visible),
                      onRoundInputModeChanged: (isDropdown) => setState(() => _isRoundDropdown = isDropdown),
                      onTeamNameInputModeChanged: (isDropdown) => setState(() => _isTeamNameDropdown = isDropdown),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showRound)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _isRoundDropdown
                            ? DropdownButtonFormField<String>(
                                value: dropdownValue,
                                items: jsonOptions
                                    .map((option) => DropdownMenuItem(
                                          value: option,
                                          child: Text(option, style: TextStyle(color: _textColor)),
                                        ))
                                    .toList(),
                                onChanged: (value) => setState(() => dropdownValue = value ?? 'Manual Input'),
                                decoration: InputDecoration(
                                  hintText: 'Round',
                                  hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              )
                            : TextField(
                                controller: _roundController,
                                decoration: InputDecoration(
                                  hintText: 'Round',
                                  hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                style: TextStyle(color: _textColor),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, color: _appColor),
                      onPressed: _teamControllers.length > 1
                          ? () {
                              setState(() {
                                _teamControllers.removeLast();
                                _nameControllers.removeLast();
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: _appColor),
                      onPressed: _teamControllers.length < 4
                          ? () {
                              setState(() {
                                _teamControllers.add(TextEditingController());
                                _nameControllers.add(TextEditingController());
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _teamControllers.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          if (_showTeam)
                            _isTeamNameDropdown
                                ? DropdownButtonFormField<String>(
                                    value: dropdownValue,
                                    items: jsonOptions
                                        .map((option) => DropdownMenuItem(
                                              value: option,
                                              child: Text(option, style: TextStyle(color: _textColor)),
                                            ))
                                        .toList(),
                                    onChanged: (value) => setState(() => dropdownValue = value ?? 'Manual Input'),
                                    decoration: InputDecoration(
                                      hintText: 'Team ${index + 1}',
                                      hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  )
                                : TextField(
                                    controller: _teamControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Team ${index + 1}',
                                      hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.save, color: _appColor),
                                        onPressed: () => _saveIndividualFile('team', _teamControllers[index].text, index),
                                      ),
                                    ),
                                    style: TextStyle(color: _textColor),
                                    textAlign: TextAlign.center,
                                  ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _nameControllers.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          if (_showName)
                            _isTeamNameDropdown
                                ? IgnorePointer(
                                    ignoring: true,
                                    child: Opacity(
                                      opacity: 0.5, // Blur effect by reducing opacity
                                      child: DropdownButtonFormField<String>(
                                        value: dropdownValue,
                                        items: jsonOptions
                                            .map((option) => DropdownMenuItem(
                                                  value: option,
                                                  child: Text(option, style: TextStyle(color: _textColor)),
                                                ))
                                            .toList(),
                                        onChanged: null, // Disable interaction
                                        decoration: InputDecoration(
                                          hintText: 'Name ${index + 1}',
                                          hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  )
                                : TextField(
                                    controller: _nameControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Name ${index + 1}',
                                      hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.save, color: _appColor),
                                        onPressed: () => _saveIndividualFile('name', _nameControllers[index].text, index),
                                      ),
                                    ),
                                    style: TextStyle(color: _textColor),
                                    textAlign: TextAlign.center,
                                  ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _uploadJsonFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Upload JSON File', style: TextStyle(color: _textColor)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: _saveToTxt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _appColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text('Save .txt', style: TextStyle(color: _textColor)),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                        onPressed: _saveToJson,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _appColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text('Save .json', style: TextStyle(color: _textColor)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    for (var controller in _teamControllers) {
      controller.dispose();
    }
    _roundController.dispose();
    super.dispose();
  }
}

class SettingsPage extends StatefulWidget {
  final String fontFamily;
  final bool showRound;
  final bool showTeam;
  final bool showName;
  final bool isRoundDropdown;
  final bool isTeamNameDropdown;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<bool> onRoundVisibilityChanged;
  final ValueChanged<bool> onTeamVisibilityChanged;
  final ValueChanged<bool> onNameVisibilityChanged;
  final ValueChanged<bool> onRoundInputModeChanged;
  final ValueChanged<bool> onTeamNameInputModeChanged;

  const SettingsPage({
    Key? key,
    required this.fontFamily,
    required this.showRound,
    required this.showTeam,
    required this.showName,
    required this.isRoundDropdown,
    required this.isTeamNameDropdown,
    required this.onFontChanged,
    required this.onRoundVisibilityChanged,
    required this.onTeamVisibilityChanged,
    required this.onNameVisibilityChanged,
    required this.onRoundInputModeChanged,
    required this.onTeamNameInputModeChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _showRound;
  late bool _showTeam;
  late bool _showName;
  late bool _isRoundDropdown;
  late bool _isTeamNameDropdown;

  @override
  void initState() {
    super.initState();
    _showRound = widget.showRound;
    _showTeam = widget.showTeam;
    _showName = widget.showName;
    _isRoundDropdown = widget.isRoundDropdown;
    _isTeamNameDropdown = widget.isTeamNameDropdown;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = (0.299 * 8 + 0.587 * 218 + 0.114 * 209) > 128 ? Colors.black : Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: textColor)),
        backgroundColor: const Color.fromRGBO(8, 218, 209, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Enter Font Family', style: TextStyle(color: textColor)),
                        content: TextField(
                          onSubmitted: (value) {
                            widget.onFontChanged(value);
                            Navigator.of(context).pop();
                          },
                          decoration: InputDecoration(
                            hintText: 'Font Family (e.g., Arial)',
                            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Close', style: TextStyle(color: textColor)),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(8, 218, 209, 1)),
                child: Text('Change Font Family', style: TextStyle(color: textColor)),
              ),
              const SizedBox(height: 16),
              Text('Visibility Options:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              CheckboxListTile(
                title: Text('Show Round', style: TextStyle(color: textColor)),
                value: _showRound,
                onChanged: (value) {
                  setState(() {
                    _showRound = value ?? true;
                  });
                  widget.onRoundVisibilityChanged(_showRound);
                },
              ),
              CheckboxListTile(
                title: Text('Show Team', style: TextStyle(color: textColor)),
                value: _showTeam,
                onChanged: (value) {
                  setState(() {
                    _showTeam = value ?? true;
                  });
                  widget.onTeamVisibilityChanged(_showTeam);
                },
              ),
              CheckboxListTile(
                title: Text('Show Name', style: TextStyle(color: textColor)),
                value: _showName,
                onChanged: (value) {
                  setState(() {
                    _showName = value ?? true;
                  });
                  widget.onNameVisibilityChanged(_showName);
                },
              ),
              const SizedBox(height: 16),
              Text('Round Input Mode:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              CheckboxListTile(
                title: Text('Use Dropdown for Round', style: TextStyle(color: textColor)),
                value: _isRoundDropdown,
                onChanged: (value) {
                  setState(() {
                    _isRoundDropdown = value ?? false;
                  });
                  widget.onRoundInputModeChanged(_isRoundDropdown);
                },
              ),
              const SizedBox(height: 16),
              Text('Team & Name Input Mode:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              CheckboxListTile(
                title: Text('Use Dropdown for Team & Name', style: TextStyle(color: textColor)),
                value: _isTeamNameDropdown,
                onChanged: (value) {
                  setState(() {
                    _isTeamNameDropdown = value ?? false;
                  });
                  widget.onTeamNameInputModeChanged(_isTeamNameDropdown);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}