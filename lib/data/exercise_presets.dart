class ExercisePreset {
  final String name;
  final String category;

  const ExercisePreset({required this.name, required this.category});
}

class ExerciseData {
  static const List<String> categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
  ];

  static const List<ExercisePreset> presets = [
    // Chest
    ExercisePreset(name: 'Bench Press', category: 'Chest'),
    ExercisePreset(name: 'Incline Dumbbell Press', category: 'Chest'),
    ExercisePreset(name: 'Chest Fly', category: 'Chest'),
    ExercisePreset(name: 'Push-Ups', category: 'Chest'),
    ExercisePreset(name: 'Dips', category: 'Chest'),

    // Back
    ExercisePreset(name: 'Deadlift', category: 'Back'),
    ExercisePreset(name: 'Lat Pulldown', category: 'Back'),
    ExercisePreset(name: 'Barbell Row', category: 'Back'),
    ExercisePreset(name: 'Pull-Ups', category: 'Back'),
    ExercisePreset(name: 'Seated Cable Row', category: 'Back'),

    // Legs
    ExercisePreset(name: 'Squat', category: 'Legs'),
    ExercisePreset(name: 'Leg Press', category: 'Legs'),
    ExercisePreset(name: 'Romanian Deadlift', category: 'Legs'),
    ExercisePreset(name: 'Leg Extension', category: 'Legs'),
    ExercisePreset(name: 'Lying Leg Curl', category: 'Legs'),
    ExercisePreset(name: 'Calf Raises', category: 'Legs'),

    // Shoulders
    ExercisePreset(name: 'Overhead Press', category: 'Shoulders'),
    ExercisePreset(name: 'Dumbbell Lateral Raise', category: 'Shoulders'),
    ExercisePreset(name: 'Face Pull', category: 'Shoulders'),
    ExercisePreset(name: 'Front Raise', category: 'Shoulders'),

    // Arms
    ExercisePreset(name: 'Bicep Curl', category: 'Arms'),
    ExercisePreset(name: 'Hammer Curl', category: 'Arms'),
    ExercisePreset(name: 'Tricep Pushdown', category: 'Arms'),
    ExercisePreset(name: 'Skull Crushers', category: 'Arms'),

    // Core
    ExercisePreset(name: 'Plank', category: 'Core'),
    ExercisePreset(name: 'Crunches', category: 'Core'),
    ExercisePreset(name: 'Hanging Leg Raise', category: 'Core'),
    ExercisePreset(name: 'Ab Wheel Rollout', category: 'Core'),

    // Cardio
    ExercisePreset(name: 'Treadmill Run', category: 'Cardio'),
    ExercisePreset(name: 'Stationary Bike', category: 'Cardio'),
    ExercisePreset(name: 'Rowing Machine', category: 'Cardio'),
    ExercisePreset(name: 'Jump Rope', category: 'Cardio'),
  ];
}
