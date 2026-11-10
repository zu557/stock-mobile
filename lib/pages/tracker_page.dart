import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../services/workout_service.dart';
import '../data/exercise_presets.dart';

class SetRowInput {
  TextEditingController repsController;
  TextEditingController weightController;
  String type;

  SetRowInput({
    required this.repsController,
    required this.weightController,
    this.type = 'Normal',
  });

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final WorkoutService _workoutService = WorkoutService();

  List<Workout> _workouts = [];
  bool _isLoading = true;
  bool _showForm = false;
  String? _editingWorkoutId;

  // Form State
  final _exerciseController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedCategory = 'Chest';
  DateTime _selectedDate = DateTime.now();
  final List<SetRowInput> _setInputs = [];

  // Filter State
  String _selectedFilterCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    for (var setInput in _setInputs) {
      setInput.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
    });
    final loaded = await _workoutService.loadWorkouts();
    setState(() {
      _workouts = loaded;
      _isLoading = false;
    });
  }

  void _resetForm() {
    _exerciseController.clear();
    _notesController.clear();
    _selectedCategory = 'Chest';
    _selectedDate = DateTime.now();
    _editingWorkoutId = null;

    for (var input in _setInputs) {
      input.dispose();
    }
    _setInputs.clear();

    // Default 3 empty set rows
    _addSetRow(defaultReps: '10', defaultWeight: '20');
    _addSetRow(defaultReps: '10', defaultWeight: '20');
    _addSetRow(defaultReps: '10', defaultWeight: '20');
  }

  void _addSetRow({String defaultReps = '', String defaultWeight = ''}) {
    // If empty, inherit from last set row if available
    if (defaultReps.isEmpty && _setInputs.isNotEmpty) {
      defaultReps = _setInputs.last.repsController.text;
    }
    if (defaultWeight.isEmpty && _setInputs.isNotEmpty) {
      defaultWeight = _setInputs.last.weightController.text;
    }

    setState(() {
      _setInputs.add(
        SetRowInput(
          repsController: TextEditingController(
            text: defaultReps.isEmpty ? '10' : defaultReps,
          ),
          weightController: TextEditingController(
            text: defaultWeight.isEmpty ? '20' : defaultWeight,
          ),
          type: 'Normal',
        ),
      );
    });
  }

  void _removeSetRow(int index) {
    if (_setInputs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one set is required.')),
      );
      return;
    }
    setState(() {
      final removed = _setInputs.removeAt(index);
      removed.dispose();
    });
  }

  void _openFormForNew() {
    _resetForm();
    setState(() {
      _showForm = true;
    });
  }

  void _openFormForEdit(Workout workout) {
    _exerciseController.text = workout.exerciseName;
    _notesController.text = workout.notes ?? '';
    _selectedCategory = workout.category;
    _selectedDate = workout.date;
    _editingWorkoutId = workout.id;

    for (var input in _setInputs) {
      input.dispose();
    }
    _setInputs.clear();

    for (var set in workout.sets) {
      _setInputs.add(
        SetRowInput(
          repsController: TextEditingController(text: set.reps.toString()),
          weightController: TextEditingController(text: set.weight.toString()),
          type: set.type,
        ),
      );
    }

    if (_setInputs.isEmpty) {
      _addSetRow();
    }

    setState(() {
      _showForm = true;
    });
  }

  Future<void> _saveWorkout() async {
    final exerciseName = _exerciseController.text.trim();
    if (exerciseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }

    List<WorkoutSet> parsedSets = [];
    for (int i = 0; i < _setInputs.length; i++) {
      final reps = int.tryParse(_setInputs[i].repsController.text) ?? 0;
      final weight =
          double.tryParse(_setInputs[i].weightController.text) ?? 0.0;

      if (reps <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set ${i + 1} reps must be greater than 0')),
        );
        return;
      }

      parsedSets.add(
        WorkoutSet(
          setNumber: i + 1,
          reps: reps,
          weight: weight,
          type: _setInputs[i].type,
        ),
      );
    }

    final newWorkout = Workout(
      id: _editingWorkoutId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseName: exerciseName,
      category: _selectedCategory,
      sets: parsedSets,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await _workoutService.saveWorkout(newWorkout);
    await _loadWorkouts();

    setState(() {
      _showForm = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingWorkoutId == null
                ? 'Workout saved successfully!'
                : 'Workout updated successfully!',
          ),
        ),
      );
    }
  }

  Future<void> _deleteWorkout(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout Log'),
        content: const Text(
          'Are you sure you want to delete this workout log?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _workoutService.deleteWorkout(id);
      await _loadWorkouts();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Workout deleted')));
      }
    }
  }

  List<Workout> get _filteredWorkouts {
    return _workouts.where((workout) {
      final matchesCategory =
          _selectedFilterCategory == 'All' ||
          workout.category.toLowerCase() ==
              _selectedFilterCategory.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty ||
          workout.exerciseName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          workout.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return Colors.redAccent;
      case 'back':
        return Colors.blue;
      case 'legs':
        return Colors.purple;
      case 'shoulders':
        return Colors.orange;
      case 'arms':
        return Colors.teal;
      case 'core':
        return Colors.amber.shade800;
      case 'cardio':
        return Colors.green;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final filtered = _filteredWorkouts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        elevation: 0,
        actions: [
          if (_workouts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWorkouts,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 24),

                  if (_showForm) ...[
                    _buildWorkoutForm(isMobile),
                    const SizedBox(height: 24),
                  ],

                  if (_workouts.isNotEmpty) ...[
                    _buildStatsSection(context),
                    const SizedBox(height: 24),
                    _buildFilterAndSearchSection(context),
                    const SizedBox(height: 24),
                  ],

                  _buildWorkoutsList(filtered, isMobile),
                ],
              ),
            ),
      floatingActionButton: !_showForm
          ? FloatingActionButton.extended(
              onPressed: _openFormForNew,
              icon: const Icon(Icons.add),
              label: const Text('Log Workout'),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Tracker',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log sets, reps, and weights to track strength progress over time.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (!isMobile)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_showForm) {
                      _showForm = false;
                    } else {
                      _openFormForNew();
                    }
                  });
                },
                icon: Icon(_showForm ? Icons.close : Icons.add),
                label: Text(_showForm ? 'Cancel' : 'Log Workout'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  if (_showForm) {
                    _showForm = false;
                  } else {
                    _openFormForNew();
                  }
                });
              },
              icon: Icon(_showForm ? Icons.close : Icons.add),
              label: Text(_showForm ? 'Cancel' : 'Log Workout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkoutForm(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _editingWorkoutId == null ? Icons.add_task : Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _editingWorkoutId == null ? 'Log Workout' : 'Edit Workout',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showForm = false),
              ),
            ],
          ),
          const Divider(height: 32),

          // Exercise Autocomplete / Name
          Text(
            'Exercise & Category',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Autocomplete<ExercisePreset>(
            displayStringForOption: (preset) => preset.name,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return ExerciseData.presets.take(5);
              }
              return ExerciseData.presets.where(
                (preset) => preset.name.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            onSelected: (ExercisePreset preset) {
              _exerciseController.text = preset.name;
              setState(() {
                _selectedCategory = preset.category;
              });
            },
            fieldViewBuilder:
                (
                  context,
                  fieldTextEditingController,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  if (_exerciseController.text.isNotEmpty &&
                      fieldTextEditingController.text.isEmpty) {
                    fieldTextEditingController.text = _exerciseController.text;
                  }

                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: focusNode,
                    onChanged: (val) {
                      _exerciseController.text = val;
                    },
                    decoration: InputDecoration(
                      labelText: 'Exercise Name',
                      hintText: 'e.g., Bench Press, Squat, Pull-Ups',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.fitness_center),
                    ),
                  );
                },
          ),
          const SizedBox(height: 12),

          // Category Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExerciseData.categories.where((c) => c != 'All').map((
              cat,
            ) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: _getCategoryColor(cat).withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? _getCategoryColor(cat) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Date Selection
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    'Date: ${_selectedDate.toString().split(' ')[0]}',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Dynamic Sets Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sets Breakdown',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _addSetRow(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Set'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _setInputs.length,
            itemBuilder: (context, index) {
              final setInput = _setInputs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Weight input
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: setInput.weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Reps input
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: setInput.repsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Type dropdown
                    DropdownButton<String>(
                      value: setInput.type,
                      underline: const SizedBox(),
                      items: ['Normal', 'Warm-up', 'Drop set', 'Failure']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            setInput.type = val;
                          });
                        }
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeSetRow(index),
                      tooltip: 'Remove set',
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g., Felt easy, focused on slow negatives',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.note_alt_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveWorkout,
              icon: const Icon(Icons.check),
              label: Text(
                _editingWorkoutId == null ? 'Save Workout' : 'Update Workout',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final totalWorkouts = _workouts.length;
    final totalSets = _workouts.fold<int>(0, (sum, w) => sum + w.totalSets);
    final totalVolume = _workouts.fold<double>(
      0.0,
      (sum, w) => sum + w.totalVolume,
    );
    final maxLift = _workouts.isEmpty
        ? 0.0
        : _workouts.map((w) => w.maxWeight).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isWide ? 1.8 : 1.4,
              children: [
                _buildStatCard(
                  title: 'Total Workouts',
                  value: totalWorkouts.toString(),
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  title: 'Total Sets',
                  value: totalSets.toString(),
                  icon: Icons.layers,
                  color: Colors.green,
                ),
                _buildStatCard(
                  title: 'Volume Lifted',
                  value: '${(totalVolume).toStringAsFixed(0)} kg',
                  icon: Icons.monitor_weight_outlined,
                  color: Colors.purple,
                ),
                _buildStatCard(
                  title: 'Max Lift',
                  value: '${maxLift.toStringAsFixed(1)} kg',
                  icon: Icons.emoji_events,
                  color: Colors.amber.shade800,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search workouts by exercise or category...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ExerciseData.categories.map((cat) {
              final isSelected = _selectedFilterCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilterCategory = cat;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutsList(List<Workout> filteredWorkouts, bool isMobile) {
    if (filteredWorkouts.isEmpty && !_showForm) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.fitness_center, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                _workouts.isEmpty
                    ? 'No workouts logged yet'
                    : 'No matching workouts',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _workouts.isEmpty
                    ? 'Tap "Log Workout" to record your sets, reps, and weights.'
                    : 'Try clearing your category filter or search query.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Logs (${filteredWorkouts.length})',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredWorkouts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildWorkoutCard(filteredWorkouts[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final catColor = _getCategoryColor(workout.category);
    final dateFormatted =
        '${workout.date.year}-${workout.date.month.toString().padLeft(2, '0')}-${workout.date.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Exercise name, Category badge, Action buttons
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.exerciseName,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            workout.category,
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormatted,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Total volume pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${workout.totalVolume.toStringAsFixed(0)} kg vol',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') {
                    _openFormForEdit(workout);
                  } else if (val == 'delete') {
                    _deleteWorkout(workout.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const Divider(height: 24),

          // Sets Table / List
          Column(
            children: workout.sets.map((set) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Set ${set.setNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (set.type != 'Normal') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              set.type,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${set.weight} kg  ×  ${set.reps} reps',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: ${workout.notes}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
