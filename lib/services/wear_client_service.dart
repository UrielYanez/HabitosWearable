import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitos_wear/models/wear_habit_model.dart';

enum WearConnectionStatus {
  disconnected,
  connecting,
  connected,
  paired,
  error,
}

class WearClientService {
  static const String _prefKeyDeviceId = 'wear_device_id';
  static const String _prefKeyToken = 'wear_login_token';
  static const String _prefKeyPaired = 'wear_is_paired';
  static const String _prefKeyUserName = 'wear_user_name';
  static const String _prefKeyUserId = 'wear_user_id';
  static const String _prefKeyCachedHabits = 'wear_cached_habits';

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String _deviceId = '';
  String _token = '';
  bool _isPaired = false;
  String _userName = 'Mi Cuenta';
  String _userId = '';
  WearConnectionStatus _status = WearConnectionStatus.disconnected;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sessionSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _habitsSub;

  // Callbacks
  Function(WearConnectionStatus status)? onStatusChanged;
  Function(List<WearHabitModel> habits, double completionRate, String userName)? onHabitsUpdated;

  String get deviceId => _deviceId;
  String get loginCode => _token;
  String get qrData => 'VITALHABIT:LOGIN:$_deviceId:$_token';
  bool get isPaired => _isPaired;
  String get userName => _userName;
  String get userId => _userId;
  WearConnectionStatus get status => _status;

  /// Inicializa Firebase, genera o carga el deviceId/token y escucha la sesión
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_prefKeyDeviceId) ?? _generateDeviceId();
    _token = prefs.getString(_prefKeyToken) ?? _generateToken();
    await prefs.setString(_prefKeyDeviceId, _deviceId);
    await prefs.setString(_prefKeyToken, _token);

    _isPaired = prefs.getBool(_prefKeyPaired) ?? false;
    _userName = prefs.getString(_prefKeyUserName) ?? 'Mi Cuenta';
    _userId = prefs.getString(_prefKeyUserId) ?? '';

    _loadCachedHabits(prefs);

    _setStatus(WearConnectionStatus.connecting);
    await _signInAnonymously();
    _listenToSession();
  }

  /// Inicia sesión anónima en Firebase
  Future<void> _signInAnonymously() async {
    try {
      final user = await _auth.signInAnonymously();
      debugPrint('[WearClient] Firebase auth OK (uid: ${user.user?.uid})');
    } catch (e) {
      debugPrint('[WearClient] Error en Firebase auth: $e');
      _setStatus(WearConnectionStatus.error);
    }
  }

  /// Escucha el documento `wear_sessions/{deviceId}` para detectar la autorización
  void _listenToSession() {
    _sessionSub?.cancel();
    _setStatus(WearConnectionStatus.connecting);

    _sessionSub = _firestore
        .collection('wear_sessions')
        .doc(_deviceId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          _isPaired = false;
          _setStatus(WearConnectionStatus.connected);
          return;
        }
        final data = snapshot.data() ?? {};
        final sessionUserId = data['userId']?.toString() ?? '';
        final sessionToken = data['token']?.toString() ?? '';

        // Solo autoriza si el token del QR coincide con el de la sesión
        if (sessionToken != _token || sessionUserId.isEmpty) {
          _isPaired = false;
          _setStatus(WearConnectionStatus.connected);
          return;
        }

        _userId = sessionUserId;
        _userName = data['userName']?.toString() ?? _userName;
        _isPaired = true;
        _saveAuthState();
        _setStatus(WearConnectionStatus.paired);
        _subscribeToHabits();
      },
      onError: (e) {
        debugPrint('[WearClient] Error escuchando sesión: $e');
        _setStatus(WearConnectionStatus.error);
      },
    );
  }

  /// Lee los hábitos del usuario autorizado directamente desde Firestore
  void _subscribeToHabits() {
    if (_userId.isEmpty) return;
    _habitsSub?.cancel();

    _habitsSub = _firestore
        .collection('habits')
        .where('user_id', isEqualTo: _userId)
        .snapshots()
        .listen(
      (snapshot) async {
        final habits = <WearHabitModel>[];
        final today = DateTime.now();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (!_isScheduled(data, today)) continue;

          final habit = await _buildWearHabit(doc.id, data, today);
          habits.add(habit);
        }

        final completedCount = habits.where((h) => h.isCompleted).length;
        final rate = habits.isEmpty ? 0.0 : completedCount / habits.length;

        // Guardar caché local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _prefKeyCachedHabits,
          jsonEncode(habits.map((h) => h.toJson()).toList()),
        );

        onHabitsUpdated?.call(habits, rate, _userName);
      },
      onError: (e) {
        debugPrint('[WearClient] Error leyendo hábitos: $e');
      },
    );
  }

  /// Construye el modelo del reloj con el estado del día
  Future<WearHabitModel> _buildWearHabit(
    String id,
    Map<String, dynamic> data,
    DateTime date,
  ) async {
    final targetType = data['target_type']?.toString() ?? 'simpleCheck';
    final targetValue = (data['target_value'] as num?)?.toInt() ?? 1;
    final unit = data['unit']?.toString() ?? 'check';

    final count = await _getCountForDate(id, date);
    final isWater = targetType == 'water';

    int currentProgress;
    bool isCompleted;
    if (isWater) {
      currentProgress = count * 250;
      isCompleted = currentProgress >= (targetValue > 0 ? targetValue : 2000);
    } else if (targetType == 'counter') {
      currentProgress = count;
      isCompleted = count > 0;
    } else if (targetType == 'steps') {
      currentProgress = count > 0 ? targetValue : 0;
      isCompleted = count > 0;
    } else {
      currentProgress = count > 0 ? targetValue : 0;
      isCompleted = count > 0;
    }

    return WearHabitModel(
      id: id,
      name: data['name']?.toString() ?? 'Hábito',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'otro',
      targetType: targetType,
      targetValue: targetValue,
      currentProgress: currentProgress,
      unit: unit,
      isCompleted: isCompleted,
    );
  }

  /// Replica la programación diaria del hábito
  bool _isScheduled(Map<String, dynamic> data, DateTime date) {
    if ((data['is_active'] as int? ?? 1) != 1) return false;

    final frequency = data['frequency']?.toString() ?? 'daily';
    final repeatRaw = data['repeat_days']?.toString() ?? '';
    final repeatDays = repeatRaw
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((d) => d > 0)
        .toList();

    if (frequency == 'monthly') {
      return repeatDays.isEmpty || repeatDays.contains(date.day);
    } else if (frequency == 'weekly') {
      return repeatDays.isEmpty || repeatDays.contains(date.weekday);
    }
    return true;
  }

  /// Cuenta los registros de un hábito en una fecha
  Future<int> _getCountForDate(String habitId, DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final snapshot = await _firestore
        .collection('habit_logs')
        .where('habit_id', isEqualTo: habitId)
        .where('date', isEqualTo: dateStr)
        .where('is_completed', isEqualTo: 1)
        .get();
    return snapshot.docs.length;
  }

  /// Marca / desmarca un hábito escribiendo directamente en Firestore
  Future<void> toggleHabit(String habitId, String habitName) async {
    final today = _dateString(DateTime.now());
    final count = await _getCountForDate(habitId, DateTime.now());

    if (count > 0) {
      // Desmarcar
      final snapshot = await _firestore
          .collection('habit_logs')
          .where('habit_id', isEqualTo: habitId)
          .where('date', isEqualTo: today)
          .where('is_completed', isEqualTo: 1)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
      }
    } else {
      // Marcar
      await _firestore.collection('habit_logs').add({
        'habit_id': habitId,
        'user_id': _userId,
        'date': today,
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      });
    }
    await _updateStreaks(habitId);
    _refreshHabitsFromFirestore();
  }

  /// Registra un vaso de agua (+250ml)
  Future<void> addWater(String habitId, int amount, int targetMl, String habitName) async {
    final today = _dateString(DateTime.now());
    await _firestore.collection('habit_logs').add({
      'habit_id': habitId,
      'user_id': _userId,
      'date': today,
      'is_completed': 1,
      'completed_at': DateTime.now().toIso8601String(),
    });
    await _updateStreaks(habitId);
    _refreshHabitsFromFirestore();
  }

  /// Completa un temporizador
  Future<void> completeTimer(String habitId, int minutes, String habitName) async {
    final today = _dateString(DateTime.now());
    final count = await _getCountForDate(habitId, DateTime.now());
    if (count == 0) {
      await _firestore.collection('habit_logs').add({
        'habit_id': habitId,
        'user_id': _userId,
        'date': today,
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      });
    }
    await _updateStreaks(habitId);
    _refreshHabitsFromFirestore();
  }

  /// Recalcula rachas y las guarda en el documento del hábito
  Future<void> _updateStreaks(String habitId) async {
    final snapshot = await _firestore
        .collection('habit_logs')
        .where('habit_id', isEqualTo: habitId)
        .orderBy('date', descending: true)
        .get();

    int currentStreak = 0;
    var checkDate = DateTime.now();

    for (final doc in snapshot.docs) {
      final logDate = DateTime.parse(doc.data()['date'] as String);
      final isToday = _isSameDay(logDate, checkDate);
      final isYesterday = _isSameDay(logDate, checkDate.subtract(const Duration(days: 1)));
      if (isToday || isYesterday) {
        currentStreak++;
        checkDate = logDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final habitDoc = await _firestore.collection('habits').doc(habitId).get();
    if (!habitDoc.exists) return;
    final bestStreak = (habitDoc.data()?['best_streak'] as num?)?.toInt() ?? 0;

    await _firestore.collection('habits').doc(habitId).update({
      'current_streak': currentStreak,
      'best_streak': currentStreak > bestStreak ? currentStreak : bestStreak,
    });
  }

  /// Refresca la lista actual de hábitos tras una acción
  Future<void> _refreshHabitsFromFirestore() async {
    if (_userId.isEmpty) return;
    try {
      final snapshot = await _firestore
          .collection('habits')
          .where('user_id', isEqualTo: _userId)
          .get();

      final habits = <WearHabitModel>[];
      final today = DateTime.now();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_isScheduled(data, today)) continue;
        habits.add(await _buildWearHabit(doc.id, data, today));
      }

      final completedCount = habits.where((h) => h.isCompleted).length;
      final rate = habits.isEmpty ? 0.0 : completedCount / habits.length;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKeyCachedHabits,
        jsonEncode(habits.map((h) => h.toJson()).toList()),
      );

      onHabitsUpdated?.call(habits, rate, _userName);
    } catch (e) {
      debugPrint('[WearClient] Error refrescando hábitos: $e');
    }
  }

  /// Solicita un refresco manual
  void requestHabits() {
    _refreshHabitsFromFirestore();
  }

  /// Genera un nuevo deviceId + token (nuevo QR de inicio de sesión)
  Future<void> regeneratePin() async {
    await _unsubscribe();
    _deviceId = _generateDeviceId();
    _token = _generateToken();
    _isPaired = false;
    _userId = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyDeviceId, _deviceId);
    await prefs.setString(_prefKeyToken, _token);
    await prefs.setBool(_prefKeyPaired, false);
    await prefs.remove(_prefKeyUserId);
    await prefs.remove(_prefKeyCachedHabits);

    _listenToSession();
  }

  /// Desvincula el dispositivo y limpia la sesión
  Future<void> unpair() async {
    await _unsubscribe();

    // Borrar la sesión de Firestore
    if (_deviceId.isNotEmpty) {
      try {
        await _firestore.collection('wear_sessions').doc(_deviceId).delete();
      } catch (e) {
        debugPrint('[WearClient] No se pudo borrar la sesión: $e');
      }
    }

    _isPaired = false;
    _userId = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyPaired, false);
    await prefs.remove(_prefKeyUserId);
    await prefs.remove(_prefKeyCachedHabits);

    _listenToSession();
  }

  Future<void> _unsubscribe() async {
    await _sessionSub?.cancel();
    await _habitsSub?.cancel();
    _sessionSub = null;
    _habitsSub = null;
  }

  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyPaired, true);
    await prefs.setString(_prefKeyUserName, _userName);
    await prefs.setString(_prefKeyUserId, _userId);
  }

  void _setStatus(WearConnectionStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }

  String _dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void _loadCachedHabits(SharedPreferences prefs) {
    final cached = prefs.getString(_prefKeyCachedHabits);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        final habits = list
            .map((item) => WearHabitModel.fromJson(item as Map<String, dynamic>))
            .toList();
        onHabitsUpdated?.call(habits, 0.0, _userName);
      } catch (_) {}
    }
  }
}
