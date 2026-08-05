import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:habitos_wear/config/wear_theme.dart';
import 'package:habitos_wear/providers/wear_provider.dart';
import 'package:habitos_wear/services/wear_client_service.dart';

class WearPairingScreen extends StatefulWidget {
  const WearPairingScreen({super.key});

  @override
  State<WearPairingScreen> createState() => _WearPairingScreenState();
}

class _WearPairingScreenState extends State<WearPairingScreen> {
  @override
  Widget build(BuildContext context) {
    final wearProvider = context.watch<WearProvider>();
    final isConnecting = wearProvider.connectionStatus == WearConnectionStatus.connecting;

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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

                // Código QR de inicio de sesión para escanear desde el móvil
                if (wearProvider.qrData.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: WearTheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: QrImageView(
                      data: wearProvider.qrData,
                      version: QrVersions.auto,
                      size: 116,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Instrucción
                const Text(
                  'Escanea este QR desde la app en tu móvil para iniciar sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: WearTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  isConnecting ? 'Conectando a Firebase...' : 'Listo para vincular',
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
                      icon: const Icon(Icons.refresh_rounded, color: WearTheme.primary),
                      onPressed: () => wearProvider.regeneratePin(),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);
}
}