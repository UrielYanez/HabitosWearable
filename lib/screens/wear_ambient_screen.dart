import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:habitos_wear/providers/wear_provider.dart';

class WearAmbientScreen extends StatefulWidget {
  const WearAmbientScreen({super.key});

  @override
  State<WearAmbientScreen> createState() => _WearAmbientScreenState();
}

class _WearAmbientScreenState extends State<WearAmbientScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wearProvider = context.watch<WearProvider>();
    final pendingHabit = wearProvider.habits.where((h) => !h.isCompleted).firstOrNull;

    final timeStr = DateFormat('HH:mm').format(_now);
    final dateStr = DateFormat('EEE, d MMM', 'es').format(_now);

    return GestureDetector(
      onTap: () => wearProvider.toggleAmbientMode(false),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hora en estilo minimalista blanco/negro
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                Text(
                  dateStr.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 14),

                // Próximo hábito pendiente
                if (pendingHabit != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.radio_button_unchecked, color: Colors.white60, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        pendingHabit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    '¡Todo completado hoy!',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white60,
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Indicador táctil
                const Text(
                  'Toca para despertar',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.5,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
