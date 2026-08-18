import 'package:flutter/foundation.dart';
import 'package:habitos_wear/models/wear_habit_model.dart';
import 'package:habitos_wear/services/wear_client_service.dart';

class WearProvider extends ChangeNotifier {
  final WearClientService _clientService = WearClientService();

  List<WearHabitModel> _habits = [];
  double _completionRate = 0.0;
  String _userName = 'Usuario';
  bool _isAmbientMode = false;
  WearHabitModel? _activeAlertHabit;

  List<WearHabitModel> get habits => _habits;
  double get completionRate => _completionRate;
  int get completedCount => _habits.where((h) => h.isCompleted).length;
  int get totalCount => _habits.length;
  String get userName => _userName;
  String get deviceId => _clientService.deviceId;
  String get qrData => _clientService.qrData;
  bool get isPaired => _clientService.isPaired;
  WearConnectionStatus get connectionStatus => _clientService.status;
  bool get isAmbientMode => _isAmbientMode;
  WearHabitModel? get activeAlertHabit => _activeAlertHabit;

  Future<void> init() async {
    await _clientService.init();

    _clientService.onStatusChanged = (status) {
      notifyListeners();
    };

    _clientService.onHabitsUpdated = (newHabits, rate, user) {
      _habits = newHabits;
      _completionRate = rate;
      _userName = user;
      notifyListeners();
    };

    notifyListeners();
  }

  void toggleHabit(WearHabitModel habit) {
    final nextCompleted = !habit.isCompleted;
    // Optimistic UI update
    _habits = _habits.map((h) {
      if (h.id == habit.id) {
        return h.copyWith(isCompleted: nextCompleted);
      }
      return h;
    }).toList();
    _recalculateRate();
    notifyListeners();

    _clientService.toggleHabit(habit.id, habit.name);
  }

  void addWater(WearHabitModel habit, [int amount = 250]) {
    final nextProgress = habit.currentProgress + amount;
    final isDone = nextProgress >= habit.targetValue;
    // Optimistic UI update
    _habits = _habits.map((h) {
      if (h.id == habit.id) {
        return h.copyWith(
          currentProgress: nextProgress,
          isCompleted: isDone,
        );
      }
      return h;
    }).toList();
    _recalculateRate();
    notifyListeners();

    _clientService.addWater(habit.id, amount, habit.targetValue, habit.name);
  }

  void completeTimer(WearHabitModel habit, int minutes) {
    // Optimistic UI update
    _habits = _habits.map((h) {
      if (h.id == habit.id) {
        return h.copyWith(
          currentProgress: minutes,
          isCompleted: true,
        );
      }
      return h;
    }).toList();
    _recalculateRate();
    notifyListeners();

    _clientService.completeTimer(habit.id, minutes, habit.name);
  }

  void refreshHabits() {
    _clientService.requestHabits();
  }

  void toggleAmbientMode([bool? force]) {
    _isAmbientMode = force ?? !_isAmbientMode;
    notifyListeners();
  }

  void triggerAlert(WearHabitModel habit) {
    _activeAlertHabit = habit;
    notifyListeners();
  }

  void dismissAlert() {
    _activeAlertHabit = null;
    notifyListeners();
  }

  Future<void> unpair() async {
    await _clientService.unpair();
    _habits.clear();
    _completionRate = 0.0;
    notifyListeners();
  }

  Future<void> regeneratePin() async {
    await _clientService.regeneratePin();
    notifyListeners();
  }

  void _recalculateRate() {
    if (_habits.isEmpty) {
      _completionRate = 0.0;
    } else {
      _completionRate = completedCount / _habits.length;
    }
  }
}
