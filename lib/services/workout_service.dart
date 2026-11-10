import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout.dart';

class WorkoutService {
  static const String _storageKey = 'user_logged_workouts_v1';

  /// Load workouts from local storage
  Future<List<Workout>> loadWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) => Workout.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save or update a single workout
  Future<void> saveWorkout(Workout workout) async {
    final workouts = await loadWorkouts();
    final index = workouts.indexWhere((w) => w.id == workout.id);
    if (index >= 0) {
      workouts[index] = workout;
    } else {
      workouts.insert(0, workout); // Insert newest first
    }
    await _persistList(workouts);
  }

  /// Delete a workout by ID
  Future<void> deleteWorkout(String id) async {
    final workouts = await loadWorkouts();
    workouts.removeWhere((w) => w.id == id);
    await _persistList(workouts);
  }

  /// Save full list of workouts to SharedPreferences
  Future<void> _persistList(List<Workout> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = workouts.map((w) => w.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Clear all workouts
  Future<void> clearAllWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
