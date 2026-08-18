import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habitos_wear/config/wear_theme.dart';
import 'package:habitos_wear/models/wear_habit_model.dart';
import 'package:habitos_wear/providers/wear_provider.dart';

class WearTimerScreen extends StatefulWidget {
  final WearHabitModel habit;

  const WearTimerScreen({super.key, required this.habit});

  @override
  State<WearTimerScreen> createState() => _WearTimerScreenState();
}

class _WearTimerScreenState extends State<WearTimerScreen> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    final minutes = widget.habit.targetValue > 0 ? widget.habit.targetValue : 15;
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _completeSession() {
    _timer?.cancel();
    final minutesCompleted = ((_totalSeconds - _remainingSeconds) / 60).ceil();
    final actualMinutes = minutesCompleted > 0 ? minutesCompleted : widget.habit.targetValue;

    final provider = context.read<WearProvider>();
    provider.completeTimer(widget.habit, actualMinutes);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: WearTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: WearTheme.success, size: 28),
              const SizedBox(height: 4),
              const Text(
                '¡Completado!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.habit.name} ($actualMinutes min)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: WearTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WearTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  minimumSize: const Size(0, 30),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Exit timer screen
                },
                child: const Text('Aceptar', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? 1.0 - (_remainingSeconds / _totalSeconds) : 0.0;

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: SafeArea(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anillo de progreso exterior
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: WearTheme.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(WearTheme.timer),
                ),
              ),

              // Contenido central
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WearTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: WearTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Botones de reproducción y completar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Play / Pause
                      IconButton(
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          _isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: WearTheme.timer,
                        ),
                        onPressed: () {
                          if (_isRunning) {
                            _pauseTimer();
                          } else {
                            _startTimer();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      // Finalizar sesión
                      IconButton(
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.check_circle_rounded, color: WearTheme.success),
                        onPressed: _completeSession,
                      ),
                      const SizedBox(width: 8),
                      // Salir
                      IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.close_rounded, color: WearTheme.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
