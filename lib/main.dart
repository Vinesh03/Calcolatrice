import 'dart:math'; // Importato per il colore casuale
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Assicurati che i binding siano inizializzati prima di operazioni async
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CalculatorApp());
}

// Convertito in StatefulWidget per gestire lo stato del tema
class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  // Stato per il tema
  ThemeMode _themeMode = ThemeMode.system;
  Color _colorSchemeSeed = Colors.purple;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
    final colorValue = prefs.getInt('colorSchemeSeed') ?? Colors.purple.value;

    setState(() {
      _themeMode = ThemeMode.values[themeModeIndex];
      _colorSchemeSeed = Color(colorValue);
    });
  }

  // Lista di colori per il selettore
  final List<Color> _availableColors = [
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
  ];

  // Metodo per cambiare la modalità del tema
  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _saveSettings();
  }

  // Metodo per cambiare il colore del tema
  void _changeThemeColor(Color color) {
    setState(() {
      _colorSchemeSeed = color;
    });
    _saveSettings();
  }

  // Metodo per un colore casuale
  void _setRandomColor() {
    setState(() {
      _colorSchemeSeed =
          _availableColors[Random().nextInt(_availableColors.length)];
    });
    _saveSettings();
  }

  // Metodo per salvare le impostazioni
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('colorSchemeSeed', _colorSchemeSeed.value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calcolatrice Seeker86',
      // Attiviamo Material 3
      theme: ThemeData(
        useMaterial3: true,
        // Usa lo stato per il seed color
        colorSchemeSeed: _colorSchemeSeed,
        brightness: Brightness.light,
      ),
      // Definiamo anche un tema scuro
      darkTheme: ThemeData(
        useMaterial3: true,
        // Usa lo stato per il seed color
        colorSchemeSeed: _colorSchemeSeed,
        brightness: Brightness.dark,
      ),
      // Usa lo stato per la modalità tema
      themeMode: _themeMode,
      // Passiamo i metodi e lo stato alla HomePage
      home: CalculatorHomePage(
        currentThemeMode: _themeMode,
        currentColor: _colorSchemeSeed,
        availableColors: _availableColors,
        onThemeModeChanged: _changeThemeMode,
        onThemeColorChanged: _changeThemeColor,
        onRandomColor: _setRandomColor,
        initialColor: _colorSchemeSeed,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  // Proprietà per gestire lo stato del tema
  final ThemeMode currentThemeMode;
  final Color currentColor;
  final List<Color> availableColors;
  final Function(ThemeMode) onThemeModeChanged;
  final Function(Color) onThemeColorChanged;
  final Function() onRandomColor;
  final Color initialColor; // Aggiunto per tenere traccia del colore iniziale

  const CalculatorHomePage({
    super.key,
    required this.currentThemeMode,
    required this.currentColor,
    required this.availableColors,
    required this.onThemeModeChanged,
    required this.onThemeColorChanged,
    required this.initialColor,
    required this.onRandomColor,
  });

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  String _expression = '';
  String _result = '0';

  // Aggiungiamo stato per la pagina della tastiera e un PageController
  bool _isAdvancedPage = false;
  late PageController _pageController;

  // Lista per la cronologia
  final List<String> _history = [];

  final List<String> _buttons = [
    'C', '(', ')', '/',
    '7', '8', '9', '*',
    '4', '5', '6', '-',
    '1', '2', '3', '+',
    '0', '.', '%', '=',
  ];

  final List<String> _advancedButtons = [
    'sin', 'cos', 'tan', 'ln',
    '^', 'sqrt', 'pi', 'e',
  ];

  // Aggiungiamo initState per inizializzare il PageController e caricare la cronologia
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadHistory();
  }

  // Metodo per caricare la cronologia
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history.addAll(prefs.getStringList('history') ?? []);
    });
  }

  // Metodo per salvare la cronologia
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', _history);
  }

  // Metodo per pulire la cronologia
  void _clearHistory() {
    setState(() {
      _history.clear();
    });
    _saveHistory();
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _expression = '';
        _result = '0';
      } else if (buttonText == '=') {
        try {
          String finalExpression = _expression.replaceAll('%', '/100');
          Parser p = Parser();
          Expression exp = p.parse(finalExpression);
          
          // Usa ContextModel per definire le costanti
          ContextModel cm = ContextModel();
          cm.bindVariable(Variable('pi'), Number(pi));
          cm.bindVariable(Variable('e'), Number(e));
          
          double eval = exp.evaluate(EvaluationType.REAL, cm);

                    _result = eval.toStringAsFixed(eval.truncateToDouble() == eval ? 0 : 2);
          
                    // Aggiungi alla cronologia
                    _history.insert(0, '$_expression = $_result'); // Inserisce all'inizio
                    _saveHistory(); // Salva la cronologia dopo l'aggiunta
          
                    _expression = _result;        } catch (e) {
          _result = 'Errore';
          _expression = '';
        }
      } else {
        if (_result == 'Errore') {
          _result = '0';
          _expression = '';
        }
        if (_expression == _result &&
            !_isOperator(buttonText) &&
            !_isFunction(buttonText)) {
          _expression = '';
        }

        // --- INIZIO MODIFICA: Gestione moltiplicazione implicita ---
        String lastChar = '';
        if (_expression.isNotEmpty) {
          lastChar = _expression.substring(_expression.length - 1);
        }

        // Definiamo cosa è "aggiungibile"
        bool isNumericConstant = (buttonText == 'pi' || buttonText == 'e');
        bool isFunctionOrParen = (_isFunction(buttonText) || buttonText == '(');
        bool isNumber = RegExp(r'[0-9]').hasMatch(buttonText);

        // Definiamo cosa c'era prima
        bool endsWithNumber =
            lastChar.isNotEmpty && RegExp(r'[0-9]').hasMatch(lastChar);
        bool endsWithConstant =
            _expression.endsWith('pi') || _expression.endsWith('e');
        bool endsWithClosingParen = lastChar == ')';

        // Aggiungi '*' se...
        // 1. (numero) -> (costante, funzione, o '(')
        //    Es: 3pi, 3sin(...), 3(
        if (endsWithNumber && (isNumericConstant || isFunctionOrParen)) {
          _expression += '*';
        }

        // 2. (costante o ')') -> (numero, costante, funzione, o '(')
        //    Es: pi(3), pi*pi, pi*sin(...), ) ( -> )*(
        //    Es: (2+1)3, (2+1)pi, (2+1)sin(...), (2+1)(
        if ((endsWithConstant || endsWithClosingParen) &&
            (isNumber || isNumericConstant || isFunctionOrParen)) {
          _expression += '*';
        }
        // --- FINE MODIFICA ---

        if (_isFunction(buttonText)) {
          _expression += '$buttonText(';
        } else {
          _expression += buttonText;
        }
      }
    });
  }

  bool _isOperator(String s) {
    return s == '/' || s == '*' || s == '-' || s == '+';
  }

  bool _isFunction(String s) {
    return s == 'sin' || s == 'cos' || s == 'tan' || s == 'ln' || s == 'sqrt';
  }

  Widget _buildExpandedButton(String buttonText, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    ButtonStyle style;
    bool isAdvancedFunction = _advancedButtons.contains(buttonText);

    if (_isOperator(buttonText) || buttonText == '=') {
      style = FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      );
    } else if (buttonText == 'C' ||
        buttonText == '(' ||
        buttonText == ')' ||
        buttonText == '%' ||
        isAdvancedFunction) {
      style = FilledButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
      );
    } else {
      style = FilledButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
      );
    }

    // --- MODIFICA: Dimensione font dinamica ---
    final double fontSize = isAdvancedFunction ? 22 : 28;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: FilledButton(
          style: style,
          onPressed: () => _onButtonPressed(buttonText),
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: fontSize, // Usa la dimensione dinamica
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Modifichiamo _buildAdvancedKeyboard per avere 5 righe (come la base)
  Widget _buildAdvancedKeyboard() {
    return Padding(
      // Usiamo lo stesso padding della tastiera base
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            // Row 1
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandedButton(_advancedButtons[0], context), // sin
                _buildExpandedButton(_advancedButtons[1], context), // cos
                _buildExpandedButton(_advancedButtons[2], context), // tan
                _buildExpandedButton(_advancedButtons[3], context), // ln
              ],
            ),
          ),
          Expanded(
            // Row 2
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandedButton(_advancedButtons[4], context), // ^
                _buildExpandedButton(_advancedButtons[5], context), // sqrt
                _buildExpandedButton(_advancedButtons[6], context), // pi
                _buildExpandedButton(_advancedButtons[7], context), // e
              ],
            ),
          ),
          // Righe vuote per mantenere l'altezza
          Expanded(child: Row()), // Empty row 3
          Expanded(child: Row()), // Empty row 4
          Expanded(child: Row()), // Empty row 5
        ],
      ),
    );
  }

  // Estraiamo la tastiera base in un suo metodo
  Widget _buildBaseKeyboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandedButton(_buttons[0], context), // C
                _buildExpandedButton(_buttons[1], context), // (
                _buildExpandedButton(_buttons[2], context), // )
                _buildExpandedButton(_buttons[3], context), // /
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandedButton(_buttons[4], context), // 7
                _buildExpandedButton(_buttons[5], context), // 8
                _buildExpandedButton(_buttons[6], context), // 9
                _buildExpandedButton(_buttons[7], context), // *
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandedButton(_buttons[8], context), // 4
                _buildExpandedButton(_buttons[9], context), // 5
                _buildExpandedButton(_buttons[10], context), // 6
                _buildExpandedButton(_buttons[11], context), // -
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandedButton(_buttons[12], context), // 1
                _buildExpandedButton(_buttons[13], context), // 2
                _buildExpandedButton(_buttons[14], context), // 3
                _buildExpandedButton(_buttons[15], context), // +
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandedButton(_buttons[16], context), // 0
                _buildExpandedButton(_buttons[17], context), // .
                _buildExpandedButton(_buttons[18], context), // %
                _buildExpandedButton(_buttons[19], context), // =
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Naviga alla pagina Cronologia
  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryPage(
          history: _history,
          onClearHistory: _clearHistory,
        ),
      ),
    );
  }

  // Naviga alla pagina Impostazioni
  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          currentThemeMode: widget.currentThemeMode,
          currentColor: widget.currentColor,
          availableColors: widget.availableColors,
          onThemeModeChanged: widget.onThemeModeChanged,
          onThemeColorChanged: widget.onThemeColorChanged,
          initialColor: widget.currentColor, // Passa il colore corrente come iniziale
          onRandomColor: widget.onRandomColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcolatrice Seeker86'),
        actions: [
          // Pulsante Cronologia
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory, // Azione aggiornata
          ),
          // Pulsante Impostazioni
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings, // Azione aggiunta
          ),
        ],
      ),
      body: Column(
        children: [
          // === Area Display ===
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _result,
                    style: textTheme.displayLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // === Pulsante Advanced Toggle ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centrato
              children: [
                TextButton(
                  onPressed: () {
                    // Aggiorniamo lo stato e animiamo il controller
                    setState(() {
                      _isAdvancedPage = !_isAdvancedPage;
                    });
                    _pageController.animateToPage(
                      _isAdvancedPage ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Row(
                    children: [
                      // Icona 'indietro' se siamo in 'Avanzata'
                      if (_isAdvancedPage)
                        const Icon(Icons.arrow_back_ios_new, size: 16),
                      if (_isAdvancedPage) const SizedBox(width: 8),
                      
                      Text(_isAdvancedPage
                          ? 'Tastiera Base'
                          : 'Avanzata'),
                      
                      // Icona 'avanti' se siamo in 'Base'
                      if (!_isAdvancedPage) const SizedBox(width: 8),
                      if (!_isAdvancedPage)
                        const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === Tastiera Avanzata (Condizionale) ===
          // Rimuoviamo il widget condizionale da qui
          // if (_isAdvancedKeyboardVisible) _buildAdvancedKeyboard(),

          // === Area Pulsanti (ora PageView) ===
          Expanded(
            flex: 4,
            child: PageView(
              controller: _pageController,
              // Aggiorniamo il pulsante se l'utente scorre manualmente
              onPageChanged: (index) {
                setState(() {
                  _isAdvancedPage = (index == 1);
                });
              },
              children: [
                _buildBaseKeyboard(), // Pagina 0
                _buildAdvancedKeyboard(), // Pagina 1
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === NUOVA PAGINA: CRONOLOGIA ===
class HistoryPage extends StatefulWidget {
  final List<String> history;
  final VoidCallback onClearHistory;

  const HistoryPage({
    super.key,
    required this.history,
    required this.onClearHistory,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronologia Calcoli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              widget.onClearHistory();
              // Aggiorna l'interfaccia utente dopo la cancellazione
              setState(() {});
            },
            tooltip: 'Cancella tutta la cronologia',
          ),
        ],
      ),
      body: widget.history.isEmpty
          ? const Center(
              child: Text('Nessuna cronologia presente.'),
            )
          : ListView.builder(
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                final entry = widget.history[index];
                final parts = entry.split(' = ');
                final expression = parts[0];
                final result = parts.length > 1 ? parts[1] : '';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expression,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '= $result',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// === NUOVA PAGINA: IMPOSTAZIONI ===
class SettingsPage extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Color currentColor;
  final List<Color> availableColors;
  final Function(ThemeMode) onThemeModeChanged;
  final Function(Color) onThemeColorChanged;
  final Function() onRandomColor;
  final Color initialColor; // Colore iniziale quando la pagina viene aperta

  const SettingsPage({
    super.key,
    required this.currentThemeMode,
    required this.currentColor,
    required this.availableColors,
    required this.onThemeModeChanged,
    required this.onThemeColorChanged,
    required this.initialColor,
    required this.onRandomColor,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _selectedThemeMode;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.currentThemeMode;
    _selectedColor = widget.initialColor;
  }

  void _applySettings() {
    widget.onThemeModeChanged(_selectedThemeMode);
    widget.onThemeColorChanged(_selectedColor);
  }

  // Metodo per mostrare il popup "Dona"
  void _showDonateDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DonatePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Sezione Modalità Tema ---
          Text('Modalità Tema', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          RadioListTile<ThemeMode>(
            title: const Text('Sistema'),
            value: ThemeMode.system,
            groupValue: _selectedThemeMode,
            onChanged: (value) => setState(() => _selectedThemeMode = value!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Chiaro'),
            value: ThemeMode.light,
            groupValue: _selectedThemeMode,
            onChanged: (value) => setState(() => _selectedThemeMode = value!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Scuro'),
            value: ThemeMode.dark,
            groupValue: _selectedThemeMode,
            onChanged: (value) => setState(() => _selectedThemeMode = value!),
          ),

          const Divider(height: 32, thickness: 1),

          // --- Sezione Colore Tema ---
          Text('Colore Tema', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: widget.availableColors.map((color) {
              bool isSelected = color == _selectedColor;
              return InkWell(
                onTap: () => setState(() => _selectedColor = color),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected // Usa il colore del tema per il bordo
                        ? Border.all( 
                            color: colorScheme.outline,
                            width: 3,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Pulsante per applicare il colore di sistema (primary)
          // TextButton(
          //   onPressed: () => setState(() => _selectedColor = Theme.of(context).colorScheme.primary),
          //   child: const Text('Applica colore di sistema'),
          // ),
          // TextButton(
          //   onPressed: () {
          //     setState(() => _selectedColor = widget.availableColors[Random().nextInt(widget.availableColors.length)]);
          //   },
          //   child: const Text('Seleziona Colore Casuale'),
          // ),
          FilledButton(
            onPressed: _applySettings,
            child: const Text('Applica Impostazioni'),
          ),

          const Divider(height: 32, thickness: 1),
          // --- Sezione Dona ---
          FilledButton(
            onPressed: () => _showDonateDialog(context),
            child: const Text('Dona'),
          ),
          // --- NEW: Build by text ---
          const SizedBox(height: 24), // Add some spacing
          Center(
            child: Text(
              'Build by SheetSeeker1486',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === NUOVA PAGINA: DONA ===
class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dona'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grazie per il tuo supporto!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Questa funzionalità è in fase di sviluppo. Presto potrai supportare lo sviluppatore tramite donazioni.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Per maggiori informazioni o per donare direttamente, puoi contattare lo sviluppatore.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            // Puoi aggiungere qui link o indirizzi per donazioni future
          ],
        ),
      ),
    );
  }
}