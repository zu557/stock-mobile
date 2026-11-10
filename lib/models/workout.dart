class WorkoutSet {
  final int setNumber;
  final int reps;
  final double weight;
  final String type; // 'Normal', 'Warm-up', 'Drop set', 'Failure'
  final bool isCompleted;

  WorkoutSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.type = 'Normal',
    this.isCompleted = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'type': type,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      setNumber: json['setNumber'] as int? ?? 1,
      reps: json['reps'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'Normal',
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }

  WorkoutSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    String? type,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Workout {
  final String id;
  final String exerciseName;
  final String category;
  final List<WorkoutSet> sets;
  final DateTime date;
  final String? notes;

  Workout({
    required this.id,
    required this.exerciseName,
    required this.category,
    required this.sets,
    required this.date,
    this.notes,
  });

  // Derived metrics
  int get totalSets => sets.length;

  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);

  double get totalVolume =>
      sets.fold(0.0, (sum, set) => sum + (set.reps * set.weight));

  double get maxWeight => sets.isEmpty
      ? 0.0
      : sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'category': category,
      'sets': sets.map((s) => s.toJson()).toList(),
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    var rawSets = json['sets'] as List<dynamic>? ?? [];
    List<WorkoutSet> parsedSets = rawSets
        .map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s)))
        .toList();

    return Workout(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseName: json['exerciseName'] as String? ?? 'Workout',
      category: json['category'] as String? ?? 'Other',
      sets: parsedSets,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
    );
  }
}
