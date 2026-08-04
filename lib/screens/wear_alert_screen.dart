import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habitos_wear/config/wear_theme.dart';
import 'package:habitos_wear/models/wear_habit_model.dart';
import 'package:habitos_wear/providers/wear_provider.dart';

class WearAlertScreen extends StatelessWidget {
  final WearHabitModel habit;

  const WearAlertScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WearProvider>();

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de Alerta
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: habit.accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: habit.accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),

                // Título de Hábito
                Text(
                  'Recordatorio',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: habit.accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: WearTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¿Has cumplido con este hábito?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    color: WearTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Completar
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WearTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: const Text('Completar', style: TextStyle(fontSize: 10)),
                      onPressed: () {
                        if (habit.targetType == 'water') {
                          provider.addWater(habit);
                        } else {
                          provider.toggleHabit(habit);
                        }
                        provider.dismissAlert();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 6),

                    // Posponer
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WearTheme.textSecondary,
                        side: const BorderSide(color: WearTheme.border),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        provider.dismissAlert();
                        Navigator.pop(context);
                      },
                      child: const Text('Posponer', style: TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
