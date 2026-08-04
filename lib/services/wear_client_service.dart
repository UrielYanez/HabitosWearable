import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  static const String _prefKeyPin = 'wear_pairing_pin';
  static const String _prefKeyHost = 'wear_server_host';
  static const String _prefKeyPaired = 'wear_is_paired';
  static const String _prefKeyUserName = 'wear_user_name';
  static const String _prefKeyCachedHabits = 'wear_cached_habits';

  String _pin = '';
  String _host = '10.0.2.2'; // IP por defecto para Android Emulator
  int _port = 8088;
  bool _isPaired = false;
  String _userName = 'Mi Cuenta';
  WearConnectionStatus _status = WearConnectionStatus.disconnected;

  WebSocket? _socket;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Callbacks
  Function(WearConnectionStatus status)? onStatusChanged;
  Function(List<WearHabitModel> habits, double completionRate, String userName)? onHabitsUpdated;

  String get pin => _pin;
  String get host => _host;
  int get port => _port;
  bool get isPaired => _isPaired;
  String get userName => _userName;
  WearConnectionStatus get status => _status;

  /// Inicializa el servicio cargando estado previo o generando un nuevo PIN
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_prefKeyPin) ?? _generateRandomPin();
    await prefs.setString(_prefKeyPin, _pin);

    _host = prefs.getString(_prefKeyHost) ?? '10.0.2.2';
    _isPaired = prefs.getBool(_prefKeyPaired) ?? false;
    _userName = prefs.getString(_prefKeyUserName) ?? 'Usuario';

    // Cargar caché local previo si existe
    _loadCachedHabits(prefs);
  }

  /// Genera un PIN aleatorio de 4 dígitos
  String _generateRandomPin() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  /// Regenera un nuevo código PIN
  Future<void> regeneratePin() async {
    _pin = _generateRandomPin();
    _isPaired = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyPin, _pin);
    await prefs.setBool(_prefKeyPaired, false);
    _setStatus(WearConnectionStatus.disconnected);
    connect();
  }

  /// Actualiza la IP del servidor (teléfono o emulador)
  Future<void> setServerHost(String newHost) async {
    _host = newHost.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyHost, _host);
    disconnect();
    connect();
  }

  /// Conecta mediante WebSocket al servidor de la app móvil
  Future<void> connect() async {
    if (_status == WearConnectionStatus.connecting || _status == WearConnectionStatus.connected) {
      return;
    }

    _setStatus(WearConnectionStatus.connecting);
    _reconnectTimer?.cancel();

    try {
      final wsUrl = Uri.parse('ws://$_host:$_port');
      debugPrint('[WearClient] Conectando a $wsUrl ...');

      _socket = await WebSocket.connect(
        wsUrl.toString(),
      ).timeout(const Duration(seconds: 4));

      _setStatus(WearConnectionStatus.connected);
      debugPrint('[WearClient] ¡Conectado al servidor móvil!');

      // Enviar solicitud de emparejamiento con el PIN de 4 dígitos
      _sendPairRequest();

      // Iniciar heartbeat ping cada 15s
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        sendPing();
      });

      _socket!.listen(
        _handleServerMessage,
        onDone: () {
          debugPrint('[WearClient] Desconectado del servidor');
          _setStatus(WearConnectionStatus.disconnected);
          _scheduleReconnect();
        },
        onError: (e) {
          debugPrint('[WearClient] Error en WebSocket: $e');
          _setStatus(WearConnectionStatus.error);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('[WearClient] Falló la conexión a $_host:$_port -> $e');
      _setStatus(WearConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  /// Desconecta el WebSocket y detiene reintentos
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
    _setStatus(WearConnectionStatus.disconnected);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  void _setStatus(WearConnectionStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }

  /// Envía la solicitud de vinculación con el PIN de este reloj
  void _sendPairRequest() {
    final payload = {
      'action': 'PAIR_REQUEST',
      'pin': _pin,
      'deviceName': 'Wear OS Smartwatch',
    };
    _sendMessage(payload);
  }

  /// Envía comando para marcar / desmarcar hábito
  void toggleHabit(String habitId, String habitName) {
    _sendMessage({
      'action': 'TOGGLE_HABIT',
      'habitId': habitId,
      'habitName': habitName,
    });
  }

  /// Envía comando para registrar ingesta de agua
  void addWater(String habitId, int amount, int targetMl, String habitName) {
    _sendMessage({
      'action': 'ADD_WATER',
      'habitId': habitId,
      'amount': amount,
      'targetMl': targetMl,
      'habitName': habitName,
    });
  }

  /// Envía comando para completar temporizador
  void completeTimer(String habitId, int minutes, String habitName) {
    _sendMessage({
      'action': 'COMPLETE_TIMER',
      'habitId': habitId,
      'minutes': minutes,
      'habitName': habitName,
    });
  }

  /// Solicita refresco manual de la lista de hábitos
  void requestHabits() {
    _sendMessage({'action': 'GET_HABITS'});
  }

  /// Envía ping para mantener la conexión viva
  void sendPing() {
    _sendMessage({'action': 'PING'});
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      try {
        _socket!.add(jsonEncode(data));
      } catch (e) {
        debugPrint('[WearClient] Error al enviar mensaje: $e');
      }
    }
  }

  /// Procesa las respuestas que llegan desde el teléfono
  Future<void> _handleServerMessage(dynamic raw) async {
    try {
      final String text = raw is String ? raw : utf8.decode(raw as List<int>);
      final Map<String, dynamic> json = jsonDecode(text);
      final type = json['type'] as String?;

      if (type == 'PAIR_SUCCESS') {
        _isPaired = true;
        _userName = json['userName']?.toString() ?? 'Usuario';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKeyPaired, true);
        await prefs.setString(_prefKeyUserName, _userName);
        _setStatus(WearConnectionStatus.connected);
        debugPrint('[WearClient] Emparejamiento exitoso con usuario $_userName');
      } else if (type == 'HABITS_UPDATE') {
        _isPaired = true;
        _userName = json['userName']?.toString() ?? _userName;
        final completionRate = (json['completionRate'] as num?)?.toDouble() ?? 0.0;
        final rawHabits = json['habits'] as List<dynamic>? ?? [];

        final List<WearHabitModel> habits = rawHabits
            .map((item) => WearHabitModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Guardar en caché local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyCachedHabits, jsonEncode(rawHabits));
        await prefs.setBool(_prefKeyPaired, true);
        await prefs.setString(_prefKeyUserName, _userName);

        onHabitsUpdated?.call(habits, completionRate, _userName);
      }
    } catch (e) {
      debugPrint('[WearClient] Error procesando mensaje del teléfono: $e');
    }
  }

  void _loadCachedHabits(SharedPreferences prefs) {
    final cached = prefs.getString(_prefKeyCachedHabits);
    if (cached != null && cached.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        final habits = list
            .map((item) => WearHabitModel.fromJson(item as Map<String, dynamic>))
            .toList();
        onHabitsUpdated?.call(habits, 0.0, _userName);
      } catch (_) {}
    }
  }

  /// Desvincula el dispositivo
  Future<void> unpair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyPaired);
    await prefs.remove(_prefKeyCachedHabits);
    _isPaired = false;
    await regeneratePin();
  }
}
