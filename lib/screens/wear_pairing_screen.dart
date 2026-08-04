import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habitos_wear/config/wear_theme.dart';
import 'package:habitos_wear/providers/wear_provider.dart';
import 'package:habitos_wear/services/wear_client_service.dart';

class WearPairingScreen extends StatefulWidget {
  const WearPairingScreen({super.key});

  @override
  State<WearPairingScreen> createState() => _WearPairingScreenState();
}

class _WearPairingScreenState extends State<WearPairingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showHostDialog(BuildContext context, WearProvider provider) {
    final controller = TextEditingController(text: provider.host);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: WearTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'IP del Teléfono',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '10.0.2.2 o IP Wi-Fi',
                  hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black45,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      provider.setHost('10.0.2.2');
                      Navigator.pop(ctx);
                    },
                    child: const Text('Emulador', style: TextStyle(fontSize: 10)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WearTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    onPressed: () {
                      provider.setHost(controller.text);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Guardar', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wearProvider = context.watch<WearProvider>();
    final isConnecting = wearProvider.connectionStatus == WearConnectionStatus.connecting;

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header circular
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnecting ? WearTheme.timer : WearTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'VITALHABIT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: WearTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Caja del Código PIN con animación
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: WearTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: WearTheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: WearTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      wearProvider.pin.isNotEmpty ? wearProvider.pin : '....',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: WearTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Instrucción
                const Text(
                  'Ingresa este PIN en el móvil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: WearTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  isConnecting
                      ? 'Conectando a ${wearProvider.host}...'
                      : 'Host: ${wearProvider.host}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: WearTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),

                // Botones de acción inferiores
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.settings_outlined, color: WearTheme.textSecondary),
                      onPressed: () => _showHostDialog(context, wearProvider),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.refresh_rounded, color: WearTheme.primary),
                      onPressed: () => wearProvider.regeneratePin(),
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
