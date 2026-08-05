import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:habitos_wear/config/wear_theme.dart';
import 'package:habitos_wear/models/wear_habit_model.dart';
import 'package:habitos_wear/providers/wear_provider.dart';
import 'package:habitos_wear/screens/wear_alert_screen.dart';
import 'package:habitos_wear/screens/wear_timer_screen.dart';
import 'package:habitos_wear/services/wear_client_service.dart';

class WearDashboardScreen extends StatefulWidget {
  const WearDashboardScreen({super.key});

  @override
  State<WearDashboardScreen> createState() => _WearDashboardScreenState();
}

class _WearDashboardScreenState extends State<WearDashboardScreen> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
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
    final habits = wearProvider.habits;
    final isOnline = wearProvider.connectionStatus == WearConnectionStatus.paired;
    final timeFormatted = DateFormat('HH:mm').format(_currentTime);

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          children: [
            // 1. TimeText y Barra de Estado Superior del Reloj
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicador de conexión
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? WearTheme.success : WearTheme.timer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeFormatted,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: WearTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Botón Modo Ambiente AOD
                IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  icon: const Icon(Icons.dark_mode_outlined, color: WearTheme.textMuted),
                  tooltip: 'Modo AOD',
                  onPressed: () => wearProvider.toggleAmbientMode(true),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 2. Anillo de Progreso Diario Circular
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 82,
                    height: 82,
                    child: CircularProgressIndicator(
                      value: wearProvider.completionRate,
                      strokeWidth: 6,
                      backgroundColor: WearTheme.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(WearTheme.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(wearProvider.completionRate * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: WearTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${wearProvider.completedCount}/${wearProvider.totalCount}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: WearTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Saludo / Usuario
            Text(
              'Hoy • ${wearProvider.userName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: WearTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // 4. Lista de Hábitos de Hoy
            if (habits.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: WearTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WearTheme.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, color: WearTheme.primary, size: 24),
                    const SizedBox(height: 4),
                    const Text(
                      'Sincronizando hábitos...',
                      style: TextStyle(fontSize: 10, color: WearTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WearTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        minimumSize: const Size(60, 24),
                      ),
                      onPressed: () => wearProvider.refreshHabits(),
                      child: const Text('Refrescar', style: TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
              )
            else
              ...habits.map((habit) => _buildHabitCard(context, habit, wearProvider)),

            const SizedBox(height: 12),

            // 5. Opciones inferiores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: const Size(50, 24),
                  ),
                  icon: const Icon(Icons.sync_rounded, size: 12, color: WearTheme.primary),
                  label: const Text('Sync', style: TextStyle(fontSize: 9, color: WearTheme.primary)),
                  onPressed: () => wearProvider.refreshHabits(),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: const Size(50, 24),
                  ),
                  icon: const Icon(Icons.link_off_rounded, size: 12, color: WearTheme.textMuted),
                  label: const Text('PIN', style: TextStyle(fontSize: 9, color: WearTheme.textMuted)),
                  onPressed: () => wearProvider.unpair(),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    WearHabitModel habit,
    WearProvider provider,
  ) {
    final isWater = habit.targetType == 'water';
    final isTimer = habit.targetType == 'timer';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: habit.isCompleted
            ? WearTheme.success.withValues(alpha: 0.12)
            : WearTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: habit.isCompleted
              ? WearTheme.success.withValues(alpha: 0.4)
              : WearTheme.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isTimer) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WearTimerScreen(habit: habit),
                ),
              );
            } else if (isWater) {
              provider.addWater(habit, 250);
            } else {
              provider.toggleHabit(habit);
            }
          },
          onLongPress: () {
            // Abrir simulador de notificación interactiva
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WearAlertScreen(habit: habit),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Icono temático del hábito
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: habit.accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    habit.iconData,
                    size: 16,
                    color: habit.accentColor,
                  ),
                ),
                const SizedBox(width: 8),

                // Nombre y Progreso
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                          color: habit.isCompleted ? WearTheme.textMuted : WearTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        habit.progressDisplay,
                        style: TextStyle(
                          fontSize: 9,
                          color: habit.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón de acción rápida en la muñeca
                if (isWater)
                  GestureDetector(
                    onTap: () => provider.addWater(habit, 250),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: WearTheme.water.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '+250ml',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: WearTheme.water,
                        ),
                      ),
                    ),
                  )
                else if (isTimer)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WearTimerScreen(habit: habit),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: WearTheme.timer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 14,
                        color: WearTheme.timer,
                      ),
                    ),
                  )
                else
                  Icon(
                    habit.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: habit.isCompleted ? WearTheme.success : WearTheme.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
