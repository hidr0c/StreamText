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
  String _dropdownValue = 'Manual Input';
  List<String> _jsonOptions = [];

  final Color _appColor = const Color.fromRGBO(8, 218, 209, 1);
  late Color _textColor;
  String _fontFamily = 'Roboto';

  bool _showTeamColumn = true;
  File? _uploadedJsonFile;

  bool _showRound = true;
  bool _showTeam = true;
  bool _showName = true;
  bool _isRoundDropdown = false;
  bool _isTeamNameDropdown = false;

  // Score Session State
  final List<List<Map<String, String>>> _scores = [
    [
      {
        'round': '',
        'team': '',
        'name': '',
        'song': '',
        'achievement': '',
        'dxScore': '',
        'fc': 'FC',
        'fs': 'FS+',
      },
    ],
  ];
  final List<List<List<TextEditingController>>> _scoreControllers = [
    [
      [
        TextEditingController(), // round
        TextEditingController(), // team
        TextEditingController(), // name
        TextEditingController(), // song
        TextEditingController(), // achievement
        TextEditingController(), // dxScore
      ],
    ],
  ];
  final List<TextEditingController> _songNameControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    _textColor = _calculateTextColor();
  }

  Color _calculateTextColor() {
    final luminance = 0.299 * _appColor.red + 0.587 * _appColor.green + 0.114 * _appColor.blue;
    return luminance > 128 ? Colors.black : Colors.white;
  }

  Future<void> _loadJsonOptions() async {
    try {
      final file = File('name.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        setState(() => _jsonOptions = List<String>.from(data));
      }
    } catch (e) {
      // Handle error silently
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
    final data = {
      'round': _roundController.text,
      'teams': _teamControllers.map((c) => c.text).toList(),
      'names': _nameControllers.map((c) => c.text).toList(),
    };
    final encoder = JsonEncoder.withIndent('     ');
    final file = File('output.json');
    await file.writeAsString(encoder.convert(data));
  }

  void _addInputField(List<TextEditingController> controllers) {
    if (controllers.length < 4) {
      setState(() => controllers.add(TextEditingController()));
    }
  }

  void _removeInputField(List<TextEditingController> controllers) {
    if (controllers.length > 1) {
      setState(() {
        final controller = controllers.removeLast();
        controller.dispose(); // Dispose the removed controller
      });
    }
  }

  void _toggleTeamColumn() {
    setState(() => _showTeamColumn = !_showTeamColumn);
  }

  void _changeFontFamily() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Font Family', style: TextStyle(color: _textColor)),
        content: TextField(
          onSubmitted: (value) {
            setState(() => _fontFamily = value);
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
      ),
    );
  }

  void _uploadJsonFile() async {
    final file = File('uploaded.json');
    if (await file.exists()) {
      setState(() => _uploadedJsonFile = file);
    }
  }

  void _saveIndividualFile(String type, String value, int index) async {
    final fileName = '$type${index + 1}.txt';
    final file = File(fileName);
    await file.writeAsString(value);
  }

  void _addScoreSession() {
    final maxEntries = _teamControllers.length < _nameControllers.length
        ? _teamControllers.length
        : _nameControllers.length;
    final newSessionScores = List.generate(maxEntries, (index) => ({
          'round': _roundController.text,
          'team': _teamControllers[index].text,
          'name': _nameControllers[index].text,
          'song': '',
          'achievement': '',
          'dxScore': '',
          'fc': 'FC',
          'fs': 'FS+',
        }));
    final newSessionControllers = List.generate(maxEntries, (index) => [
          TextEditingController()..text = _roundController.text,
          TextEditingController()..text = _teamControllers[index].text,
          TextEditingController()..text = _nameControllers[index].text,
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
        ]);
    setState(() {
      _scores.add(newSessionScores);
      _scoreControllers.add(newSessionControllers);
      _songNameControllers.add(TextEditingController());
    });
    print('New session added. Total sessions: ${_scores.length}');
  }

  void _removeScoreSession(int sessionIndex) {
    if (_scores.length > 1) {
      setState(() {
        final sessionControllers = _scoreControllers.removeAt(sessionIndex);
        for (var playerControllers in sessionControllers) {
          for (var controller in playerControllers) {
            controller.dispose(); // Dispose all controllers in the session
          }
        }
        _scores.removeAt(sessionIndex);
        _songNameControllers.removeAt(sessionIndex).dispose(); // Dispose the song name controller
      });
      print('Session removed. Remaining sessions: ${_scores.length}');
    }
  }

  void _saveScore(int sessionIndex, int playerIndex) async {
    final controllers = _scoreControllers[sessionIndex][playerIndex];
    await File('song${sessionIndex + 1}_player${playerIndex + 1}.txt').writeAsString(controllers[3].text);
    await File('achievementforsong${sessionIndex + 1}_player${playerIndex + 1}.txt').writeAsString(controllers[4].text);
    await File('dxscoreforsong${sessionIndex + 1}_player${playerIndex + 1}.txt').writeAsString(controllers[5].text);
  }

  void _saveScoresToTxt() async {
    for (var sessionIndex = 0; sessionIndex < _scores.length; sessionIndex++) {
      final sessionControllers = _scoreControllers[sessionIndex];
      final sessionScores = _scores[sessionIndex];
      for (var playerIndex = 0; playerIndex < sessionScores.length; playerIndex++) {
        final controllers = sessionControllers[playerIndex];
        final content = 'Round: ${controllers[0].text}\nTeam: ${controllers[1].text}\nName: ${controllers[2].text}\nSong ${sessionIndex + 1}: ${controllers[3].text}\nAchievement: ${controllers[4].text}\nDX Score: ${controllers[5].text}\nFC: ${sessionScores[playerIndex]['fc']}\nFS: ${sessionScores[playerIndex]['fs']}';
        await File('score_session${sessionIndex}_player${playerIndex}.txt').writeAsString(content);
      }
    }
  }

  void _saveScoresToJson() async {
    final data = _scores.asMap().map((sessionIndex, sessionScores) {
      final sessionControllers = _scoreControllers[sessionIndex];
      return MapEntry(sessionIndex, sessionScores.asMap().map((playerIndex, score) {
        final controllers = sessionControllers[playerIndex];
        return MapEntry(playerIndex, {
          'round': controllers[0].text,
          'team': controllers[1].text,
          'name': controllers[2].text,
          'song': controllers[3].text,
          'achievement': controllers[4].text,
          'dxScore': controllers[5].text,
          'fc': score['fc'],
          'fs': score['fs'],
        });
      }));
    });
    final encoder = JsonEncoder.withIndent('     ');
    await File('scores.json').writeAsString(encoder.convert(data));
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
              title: Text('Dashboard', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            ListTile(
              title: Text('Score', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScorePage(
                    roundController: _roundController,
                    teamControllers: _teamControllers,
                    nameControllers: _nameControllers,
                    scores: _scores,
                    scoreControllers: _scoreControllers,
                    songNameControllers: _songNameControllers,
                    onAddScoreSession: _addScoreSession,
                    onRemoveScoreSession: _removeScoreSession,
                    onSaveScore: _saveScore,
                    onSaveScoresToTxt: _saveScoresToTxt,
                    onSaveScoresToJson: _saveScoresToJson,
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text('Settings', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.of(context).push(
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
                        child: _isRoundDropdown
                            ? FutureBuilder(
                                future: _loadJsonOptions(),
                                builder: (context, snapshot) => DropdownButtonFormField<String>(
                                  value: _dropdownValue,
                                  items: _jsonOptions
                                      .map((option) => DropdownMenuItem(
                                            value: option,
                                            child: Text(option, style: TextStyle(color: _textColor)),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() => _dropdownValue = value ?? 'Manual Input'),
                                  decoration: InputDecoration(
                                    hintText: 'Round',
                                    hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
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
                      icon: const Icon(Icons.remove, color: Color.fromRGBO(8, 218, 209, 1)),
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
                      icon: const Icon(Icons.add, color: Color.fromRGBO(8, 218, 209, 1)),
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
                                ? FutureBuilder(
                                    future: _loadJsonOptions(),
                                    builder: (context, snapshot) => DropdownButtonFormField<String>(
                                      value: _dropdownValue,
                                      items: _jsonOptions
                                          .map((option) => DropdownMenuItem(
                                                value: option,
                                                child: Text(option, style: TextStyle(color: _textColor)),
                                              ))
                                          .toList(),
                                      onChanged: (value) => setState(() => _dropdownValue = value ?? 'Manual Input'),
                                      decoration: InputDecoration(
                                        hintText: 'Team ${index + 1}',
                                        hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  )
                                : TextField(
                                    controller: _teamControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Team ${index + 1}',
                                      hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.save, color: Color.fromRGBO(8, 218, 209, 1)),
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
                                      opacity: 0.5,
                                      child: FutureBuilder(
                                        future: _loadJsonOptions(),
                                        builder: (context, snapshot) => DropdownButtonFormField<String>(
                                          value: _dropdownValue,
                                          items: _jsonOptions
                                              .map((option) => DropdownMenuItem(
                                                    value: option,
                                                    child: Text(option, style: TextStyle(color: _textColor)),
                                                  ))
                                              .toList(),
                                          onChanged: null,
                                          decoration: InputDecoration(
                                            hintText: 'Name ${index + 1}',
                                            hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
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
                                        icon: const Icon(Icons.save, color: Color.fromRGBO(8, 218, 209, 1)),
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
    for (var controllers in [_nameControllers, _teamControllers]) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    for (var session in _scoreControllers) {
      for (var player in session) {
        for (var controller in player) {
          controller.dispose();
        }
      }
    }
    for (var controller in _songNameControllers) {
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
                  ),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(8, 218, 209, 1)),
                child: Text('Change Font Family', style: TextStyle(color: textColor)),
              ),
              const SizedBox(height: 16),
              Text('Visibility Options:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              CheckboxListTile(
                title: Text('Show Round', style: TextStyle(color: textColor)),
                value: _showRound,
                onChanged: (value) {
                  setState(() => _showRound = value ?? true);
                  widget.onRoundVisibilityChanged(_showRound);
                },
              ),
              CheckboxListTile(
                title: Text('Show Team', style: TextStyle(color: textColor)),
                value: _showTeam,
                onChanged: (value) {
                  setState(() => _showTeam = value ?? true);
                  widget.onTeamVisibilityChanged(_showTeam);
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
              Text('Round Input Mode:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              CheckboxListTile(
                title: Text('Use Dropdown for Round', style: TextStyle(color: textColor)),
                value: _isRoundDropdown,
                onChanged: (value) {
                  setState(() => _isRoundDropdown = value ?? false);
                  widget.onRoundInputModeChanged(_isRoundDropdown);
                },
              ),
              const SizedBox(height: 16),
              Text('Team & Name Input Mode:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              CheckboxListTile(
                title: Text('Use Dropdown for Team & Name', style: TextStyle(color: textColor)),
                value: _isTeamNameDropdown,
                onChanged: (value) {
                  setState(() => _isTeamNameDropdown = value ?? false);
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

class ScorePage extends StatefulWidget {
  final TextEditingController roundController;
  final List<TextEditingController> teamControllers;
  final List<TextEditingController> nameControllers;
  final List<List<Map<String, String>>> scores;
  final List<List<List<TextEditingController>>> scoreControllers;
  final List<TextEditingController> songNameControllers;
  final VoidCallback onAddScoreSession;
  final Function(int) onRemoveScoreSession;
  final Function(int, int) onSaveScore;
  final VoidCallback onSaveScoresToTxt;
  final VoidCallback onSaveScoresToJson;

  const ScorePage({
    Key? key,
    required this.roundController,
    required this.teamControllers,
    required this.nameControllers,
    required this.scores,
    required this.scoreControllers,
    required this.songNameControllers,
    required this.onAddScoreSession,
    required this.onRemoveScoreSession,
    required this.onSaveScore,
    required this.onSaveScoresToTxt,
    required this.onSaveScoresToJson,
  }) : super(key: key);

  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  @override
  void initState() {
    super.initState();
    _syncScoreEntries();
  }

  void _syncScoreEntries() {
    final teamCount = widget.teamControllers.length;
    final nameCount = widget.nameControllers.length;
    final minCount = teamCount < nameCount ? teamCount : nameCount;

    for (var sessionIndex = 0; sessionIndex < widget.scores.length; sessionIndex++) {
      var sessionScores = widget.scores[sessionIndex];
      var sessionControllers = widget.scoreControllers[sessionIndex];

      // Remove excess entries if more than needed
      while (sessionScores.length > minCount) {
        final index = sessionScores.length - 1;
        sessionControllers[index].forEach((c) => c.dispose());
        sessionScores.removeAt(index);
        sessionControllers.removeAt(index);
      }

      // Add new entries if less than needed
      while (sessionScores.length < minCount) {
        final index = sessionScores.length;
        final newControllers = [
          TextEditingController()..text = widget.roundController.text,
          TextEditingController()..text = widget.teamControllers[index].text,
          TextEditingController()..text = widget.nameControllers[index].text,
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
        ];
        sessionControllers.add(newControllers);
        sessionScores.add({
          'round': widget.roundController.text,
          'team': widget.teamControllers[index].text,
          'name': widget.nameControllers[index].text,
          'song': widget.songNameControllers.length > sessionIndex ? widget.songNameControllers[sessionIndex].text : '',
          'achievement': '',
          'dxScore': '',
          'fc': 'FC',
          'fs': 'FS+',
        });
      }

      // Update existing entries with new team/name values
      for (var i = 0; i < sessionScores.length; i++) {
        sessionScores[i]['round'] = widget.roundController.text;
        sessionScores[i]['team'] = widget.teamControllers[i].text;
        sessionScores[i]['name'] = widget.nameControllers[i].text;
        sessionControllers[i][0].text = widget.roundController.text;
        sessionControllers[i][1].text = widget.teamControllers[i].text;
        sessionControllers[i][2].text = widget.nameControllers[i].text;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncScoreEntries();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = (0.299 * 8 + 0.587 * 218 + 0.114 * 209) > 128 ? Colors.black : Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: Text('Score', style: TextStyle(color: textColor)),
        backgroundColor: const Color.fromRGBO(8, 218, 209, 1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var sessionIndex = 0; sessionIndex < widget.scores.length && sessionIndex < widget.songNameControllers.length; sessionIndex++)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widget.songNameControllers[sessionIndex],
                              decoration: InputDecoration(
                                labelText: 'Song ${sessionIndex + 1}',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: textColor.withOpacity(0.1),
                              ),
                              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                              onChanged: (value) {
                                setState(() {
                                  for (var player in widget.scores[sessionIndex]) {
                                    player['song'] = value;
                                  }
                                });
                              },
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Color.fromRGBO(8, 218, 209, 1)),
                                onPressed: widget.scores.length > 1 ? () => widget.onRemoveScoreSession(sessionIndex) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Color.fromRGBO(8, 218, 209, 1)),
                                onPressed: () {
                                  widget.onAddScoreSession();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(widget.scores[sessionIndex].length, (playerIndex) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              widget.scoreControllers[sessionIndex][playerIndex][1].text.isNotEmpty
                                  ? widget.scoreControllers[sessionIndex][playerIndex][1].text
                                  : 'Team ${playerIndex + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(widget.scores[sessionIndex].length, (playerIndex) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              widget.scoreControllers[sessionIndex][playerIndex][2].text.isNotEmpty
                                  ? widget.scoreControllers[sessionIndex][playerIndex][2].text
                                  : 'Name ${playerIndex + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        )),
                      ),
                      const SizedBox(height: 12),
                      if (widget.scoreControllers[sessionIndex].isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(widget.scores[sessionIndex].length, (playerIndex) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: _buildTextField('Achievement', widget.scoreControllers[sessionIndex][playerIndex][4], sessionIndex, playerIndex, textColor),
                            ),
                          )),
                        ),
                      const SizedBox(height: 12),
                      if (widget.scoreControllers[sessionIndex].isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(widget.scores[sessionIndex].length, (playerIndex) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: _buildTextField('DX Score', widget.scoreControllers[sessionIndex][playerIndex][5], sessionIndex, playerIndex, textColor),
                            ),
                          )),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(widget.scores[sessionIndex].length, (playerIndex) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: _buildDropdown('FC', widget.scores[sessionIndex][playerIndex]['fc']!, ['FC', 'FC+', 'AP', 'AP+'], (value) {
                              if (value != null) {
                                setState(() => widget.scores[sessionIndex][playerIndex]['fc'] = value);
                              }
                            }, textColor),
                          ),
                        )),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(widget.scores[sessionIndex].length, (playerIndex) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: _buildDropdown('FS', widget.scores[sessionIndex][playerIndex]['fs']!, ['FS+', 'FDX', 'FDX+'], (value) {
                              if (value != null) {
                                setState(() => widget.scores[sessionIndex][playerIndex]['fs'] = value);
                              }
                            }, textColor),
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: widget.onSaveScoresToTxt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(8, 218, 209, 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Save .txt', style: TextStyle(color: textColor, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: widget.onSaveScoresToJson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(8, 218, 209, 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Save .json', style: TextStyle(color: textColor, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, int sessionIndex, int playerIndex, Color textColor) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.save, color: Color.fromRGBO(8, 218, 209, 1)),
          onPressed: () => widget.onSaveScore(sessionIndex, playerIndex),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: textColor.withOpacity(0.1),
      ),
      style: TextStyle(color: textColor),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, Color textColor) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: TextStyle(color: textColor)),
      )).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: textColor.withOpacity(0.1),
      ),
      style: TextStyle(color: textColor),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}