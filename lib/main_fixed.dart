import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamText',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(8, 218, 209, 1),
        ),
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
  final List<TextEditingController> _nameControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<TextEditingController> _roundControllers = [
    TextEditingController(),
  ];

  List<String> _namesOptions = [];
  List<String> _roundsOptions = [];

  final Color _appColor = const Color.fromRGBO(8, 218, 209, 1);
  late Color _textColor;
  String _fontFamily = 'Roboto';

  bool _showRound = true;
  bool _showName = true;
  bool _isRoundDropdown = false;
  bool _isNameDropdown = false;

  @override
  void initState() {
    super.initState();
    _textColor = _calculateTextColor();
    _loadJsonOptions();
  }

  Color _calculateTextColor() {
    final luminance =
        0.299 * _appColor.red +
        0.587 * _appColor.green +
        0.114 * _appColor.blue;
    return luminance > 128 ? Colors.black : Colors.white;
  }

  Future<void> _loadJsonOptions() async {
    try {
      // Load names options
      final namesFile = File('names.json');
      if (await namesFile.exists()) {
        final namesData = jsonDecode(await namesFile.readAsString());
        if (namesData is List) {
          setState(
            () => _namesOptions = namesData
                .map((item) => item['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList(),
          );
        }
      }

      // Load rounds options
      final roundsFile = File('rounds.json');
      if (await roundsFile.exists()) {
        final roundsData = jsonDecode(await roundsFile.readAsString());
        if (roundsData is List) {
          setState(() => _roundsOptions = List<String>.from(roundsData));
        }
      }
    } catch (e) {
      print('Error loading JSON options: $e');
    }
  }

  void _saveToTxt() async {
    try {
      // Save individual name files
      for (int i = 0; i < _nameControllers.length; i++) {
        final name = _nameControllers[i].text;
        if (name.isNotEmpty) {
          await File('player${i + 1}.txt').writeAsString(name);
        }
      }

      // Save round file
      if (_roundControllers.isNotEmpty &&
          _roundControllers[0].text.isNotEmpty) {
        final round = _roundControllers[0].text;
        await File('round.txt').writeAsString(round);
      }

      // Save combined output
      final names = _nameControllers
          .where((c) => c.text.isNotEmpty)
          .map((c) => c.text)
          .join(', ');
      final round = _roundControllers.isNotEmpty
          ? _roundControllers[0].text
          : '';
      final content = 'Names: $names\nRound: $round';
      final file = File('output.txt');
      await file.writeAsString(content);

      // Show confirmation
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to TXT files')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving files: $e')));
    }
  }

  void _saveToJson() async {
    try {
      final encoder = JsonEncoder.withIndent('  ');

      // Export rounds to rounds.json
      if (_showRound) {
        final roundsData = _roundControllers
            .map((c) => c.text)
            .where((round) => round.isNotEmpty)
            .toList();
        await File('rounds.json').writeAsString(encoder.convert(roundsData));
      }

      // Export names to names.json
      if (_showName) {
        final namesData = _nameControllers
            .map((c) => {'name': c.text})
            .where((member) => member['name']!.isNotEmpty)
            .toList();

        await File('names.json').writeAsString(encoder.convert(namesData));
      }

      // Show confirmation
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exported to JSON files')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving JSON files: $e')));
    }
  }

  void _uploadJsonFile() async {
    try {
      // For this simple implementation, we'll just try to read existing files
      await _loadJsonOptions();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loaded JSON data')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading files: $e')));
    }
  }

  void _saveIndividualFile(String type, String value, int index) async {
    if (value.isEmpty) return;

    final fileName = '$type${index + 1}.txt';
    final file = File(fileName);
    await file.writeAsString(value);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved $fileName')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StreamText', style: TextStyle(color: _textColor)),
        backgroundColor: _appColor,
        elevation: 2,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: _appColor),
              child: Text(
                'Options',
                style: TextStyle(color: _textColor, fontSize: 24),
              ),
            ),
            ListTile(
              title: Text('Dashboard', style: TextStyle(color: Colors.black87)),
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            ListTile(
              title: Text('Settings', style: TextStyle(color: Colors.black87)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    fontFamily: _fontFamily,
                    showRound: _showRound,
                    showName: _showName,
                    isRoundDropdown: _isRoundDropdown,
                    isNameDropdown: _isNameDropdown,
                    onFontChanged: (font) => setState(() => _fontFamily = font),
                    onRoundVisibilityChanged: (visible) =>
                        setState(() => _showRound = visible),
                    onNameVisibilityChanged: (visible) =>
                        setState(() => _showName = visible),
                    onRoundInputModeChanged: (isDropdown) =>
                        setState(() => _isRoundDropdown = isDropdown),
                    onNameInputModeChanged: (isDropdown) =>
                        setState(() => _isNameDropdown = isDropdown),
                  ),
                ),
              ),
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
                        child: _isRoundDropdown && _roundsOptions.isNotEmpty
                            ? DropdownButtonFormField<String>(
                                value: _roundControllers[0].text.isNotEmpty
                                    ? _roundControllers[0].text
                                    : null,
                                items: _roundsOptions
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(
                                          item,
                                          style: TextStyle(color: _textColor),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _roundControllers[0].text = value;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Round',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: _textColor.withOpacity(0.1),
                                ),
                                style: TextStyle(color: _textColor),
                              )
                            : TextField(
                                controller: _roundControllers[0],
                                decoration: InputDecoration(
                                  labelText: 'Round',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: _textColor.withOpacity(0.1),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.save,
                                      color: Color.fromRGBO(8, 218, 209, 1),
                                    ),
                                    onPressed: () => _saveIndividualFile(
                                      'round',
                                      _roundControllers[0].text,
                                      0,
                                    ),
                                  ),
                                ),
                                style: TextStyle(color: _textColor),
                              ),
                      ),
                    ],
                  ),
                ),

              // Player names section header
              if (_showName)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Player Names',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // Player name inputs
              if (_showName)
                ...List.generate(
                  _nameControllers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _isNameDropdown && _namesOptions.isNotEmpty
                        ? DropdownButtonFormField<String>(
                            value: _nameControllers[index].text.isNotEmpty
                                ? _nameControllers[index].text
                                : null,
                            items: _namesOptions
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: TextStyle(color: _textColor),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _nameControllers[index].text = value;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Player ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: _textColor.withOpacity(0.1),
                            ),
                            style: TextStyle(color: _textColor),
                          )
                        : TextField(
                            controller: _nameControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Player ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: _textColor.withOpacity(0.1),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.save,
                                  color: Color.fromRGBO(8, 218, 209, 1),
                                ),
                                onPressed: () => _saveIndividualFile(
                                  'player',
                                  _nameControllers[index].text,
                                  index,
                                ),
                              ),
                            ),
                            style: TextStyle(color: _textColor),
                          ),
                  ),
                ),

              const SizedBox(height: 24),

              // Upload JSON file button
              Center(
                child: ElevatedButton(
                  onPressed: _uploadJsonFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Upload JSON File',
                    style: TextStyle(color: _textColor),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save buttons
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Save .txt',
                          style: TextStyle(color: _textColor),
                        ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Save .json',
                          style: TextStyle(color: _textColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
    for (var controller in _roundControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class SettingsPage extends StatefulWidget {
  final String fontFamily;
  final bool showRound;
  final bool showName;
  final bool isRoundDropdown;
  final bool isNameDropdown;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<bool> onRoundVisibilityChanged;
  final ValueChanged<bool> onNameVisibilityChanged;
  final ValueChanged<bool> onRoundInputModeChanged;
  final ValueChanged<bool> onNameInputModeChanged;

  const SettingsPage({
    Key? key,
    required this.fontFamily,
    required this.showRound,
    required this.showName,
    required this.isRoundDropdown,
    required this.isNameDropdown,
    required this.onFontChanged,
    required this.onRoundVisibilityChanged,
    required this.onNameVisibilityChanged,
    required this.onRoundInputModeChanged,
    required this.onNameInputModeChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _showRound;
  late bool _showName;
  late bool _isRoundDropdown;
  late bool _isNameDropdown;

  @override
  void initState() {
    super.initState();
    _showRound = widget.showRound;
    _showName = widget.showName;
    _isRoundDropdown = widget.isRoundDropdown;
    _isNameDropdown = widget.isNameDropdown;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = (0.299 * 8 + 0.587 * 218 + 0.114 * 209) > 128
        ? Colors.black
        : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromRGBO(8, 218, 209, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Enter Font Family',
                      style: TextStyle(color: textColor),
                    ),
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
                        child: Text(
                          'Close',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(8, 218, 209, 1),
                ),
                child: Text(
                  'Change Font Family',
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Visibility Options:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              CheckboxListTile(
                title: Text('Show Round', style: TextStyle(color: textColor)),
                value: _showRound,
                onChanged: (value) {
                  setState(() => _showRound = value ?? true);
                  widget.onRoundVisibilityChanged(_showRound);
                },
              ),
              CheckboxListTile(
                title: Text('Show Name', style: TextStyle(color: textColor)),
                value: _showName,
                onChanged: (value) {
                  setState(() => _showName = value ?? true);
                  widget.onNameVisibilityChanged(_showName);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Round Input Mode:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              CheckboxListTile(
                title: Text(
                  'Use Dropdown for Round',
                  style: TextStyle(color: textColor),
                ),
                value: _isRoundDropdown,
                onChanged: (value) {
                  setState(() => _isRoundDropdown = value ?? false);
                  widget.onRoundInputModeChanged(_isRoundDropdown);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Name Input Mode:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              CheckboxListTile(
                title: Text(
                  'Use Dropdown for Names',
                  style: TextStyle(color: textColor),
                ),
                value: _isNameDropdown,
                onChanged: (value) {
                  setState(() => _isNameDropdown = value ?? false);
                  widget.onNameInputModeChanged(_isNameDropdown);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
