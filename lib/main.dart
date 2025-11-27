import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const ProviderScope(child: LifePlanApp()));
}

// ============================================================================
// MODELS
// ============================================================================

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String category;
  final int priority;
  bool completed;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.category = 'All',
    this.priority = 1,
    this.completed = false,
  });
}

class Goal {
  final String id;
  final String title;
  final double progress;
  final String category;

  Goal({
    required this.id,
    required this.title,
    this.progress = 0.0,
    this.category = 'Personal',
  });
}

// ============================================================================
// PROVIDERS
// ============================================================================

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier();
});

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier() : super(_demoTasks());

  static List<Task> _demoTasks() {
    final uuid = const Uuid();
    return [
      Task(
        id: uuid.v4(),
        title: 'E-Mails beantworten',
        dueDate: DateTime.now(),
        category: 'Arbeit',
      ),
      Task(
        id: uuid.v4(),
        title: 'Sport: 30 min Joggen',
        dueDate: DateTime.now(),
        category: 'Gesundheit',
      ),
      Task(
        id: uuid.v4(),
        title: 'Einkaufen gehen',
        category: 'Privat',
      ),
    ];
  }

  void addTask(String title, {DateTime? due, String category = 'All'}) {
    final uuid = const Uuid();
    final t = Task(
      id: uuid.v4(),
      title: title,
      dueDate: due,
      category: category,
    );
    state = [...state, t];
  }

  void toggleComplete(String id) {
    state = state.map((t) {
      if (t.id == id) {
        t.completed = !t.completed;
      }
      return t;
    }).toList();
  }

  void removeTask(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final goalsProvider = StateProvider<List<Goal>>((ref) {
  final uuid = const Uuid();
  return [
    Goal(id: uuid.v4(), title: '10 kg abnehmen', progress: 0.45, category: 'Gesundheit'),
    Goal(id: uuid.v4(), title: 'Buch schreiben', progress: 0.20, category: 'Kreativ'),
    Goal(id: uuid.v4(), title: 'Neue Sprache lernen', progress: 0.65, category: 'Bildung'),
  ];
});

final moodProvider = StateProvider<double>((ref) => 1.0);

// ============================================================================
// MAIN APP
// ============================================================================

class LifePlanApp extends StatelessWidget {
  const LifePlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifePlan AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A6CF7)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FE),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainNavigator(),
    );
  }
}

// ============================================================================
// MAIN NAVIGATOR (Bottom Navigation)
// ============================================================================

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(),
    CalendarScreen(),
    GoalsScreen(),
    CoachScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A6CF7),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'Aufgaben'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Kalender'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_outlined), label: 'Ziele'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'Coach'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Consumer(
        builder: (context, ref, child) => AlertDialog(
          title: const Text('Neue Aufgabe'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Aufgabentitel'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  ref.read(tasksProvider.notifier).addTask(ctrl.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('Speichern'),
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SCREENS
// ============================================================================

// HOME SCREEN
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final incompleteTasks = tasks.where((t) => !t.completed).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Guten Morgen, Alex', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Dienstag, 26. November', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(child: Icon(Icons.person)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const MoodSlider(),
          const SizedBox(height: 20),
          const AIPlanCard(),
          const SizedBox(height: 20),
          const Text('Nächste Aufgaben', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...incompleteTasks.map((t) => TaskCard(task: t)),
        ],
      ),
    );
  }
}

// TASKS SCREEN
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aufgaben'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('Keine Aufgaben vorhanden'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final t = tasks[i];
                return TaskCard(
                  task: t,
                  onToggle: () => ref.read(tasksProvider.notifier).toggleComplete(t.id),
                  onDelete: () => ref.read(tasksProvider.notifier).removeTask(t.id),
                );
              },
            ),
    );
  }
}

// CALENDAR SCREEN
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) => isSameDay(d, _selected),
                  onDaySelected: (sel, foc) {
                    setState(() {
                      _selected = sel;
                      _focused = foc;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selected != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aufgaben für ${_selected!.day}.${_selected!.month}.${_selected!.year}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text('Keine Aufgaben für diesen Tag'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// GOALS SCREEN
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ziele & Gewohnheiten'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Meine Ziele', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...goals.map((g) => Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: g.progress),
                        const SizedBox(height: 4),
                        Text('${(g.progress * 100).toInt()}% erreicht'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                )),
            const SizedBox(height: 24),
            const Text('Gewohnheiten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                6,
                (i) => Chip(
                  label: Text('Gewohnheit ${i + 1}'),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// COACH SCREEN
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hallo! Ich bin dein KI-Coach. Wie kann ich dir heute helfen?'},
  ];

  void _send() {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': txt});
      _messages.add({
        'role': 'ai',
        'text': 'Das klingt interessant! Lass uns gemeinsam daran arbeiten. Hier sind meine Vorschläge...'
      });
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KI-Coach'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isAi = m['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAi ? Colors.white : const Color(0xFF4A6CF7),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      m['text']!,
                      style: TextStyle(color: isAi ? Colors.black : Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'Frag den Coach...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF4A6CF7),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (_) => onToggle?.call(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: task.dueDate != null
            ? Text('${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}')
            : null,
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            : const Icon(Icons.drag_handle),
      ),
    );
  }
}

class MoodSlider extends ConsumerWidget {
  const MoodSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wie fühlst du dich heute?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('😞', style: TextStyle(fontSize: 24)),
                Expanded(
                  child: Slider(
                    value: mood,
                    min: 0,
                    max: 2,
                    divisions: 2,
                    onChanged: (v) => ref.read(moodProvider.notifier).state = v,
                  ),
                ),
                const Text('😄', style: TextStyle(fontSize: 24)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AIPlanCard extends StatelessWidget {
  const AIPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dein Tag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Neu generieren'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _planRow('08:00', 'Meditation 10 min'),
            _planRow('08:30', 'Frühstück'),
            _planRow('09:00', 'Arbeit: E-Mails bearbeiten'),
            _planRow('12:00', 'Mittagspause'),
            _planRow('14:00', 'Sport: Joggen'),
          ],
        ),
      ),
    );
  }

  Widget _planRow(String time, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(time, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}
