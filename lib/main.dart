import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:habitos_wear/config/wear_theme.dart';
import 'package:habitos_wear/providers/wear_provider.dart';
import 'package:habitos_wear/screens/wear_ambient_screen.dart';
import 'package:habitos_wear/screens/wear_dashboard_screen.dart';
import 'package:habitos_wear/screens/wear_pairing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  final wearProvider = WearProvider();
  await wearProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: wearProvider),
      ],
      child: const HabitosWearApp(),
    ),
  );
}

class HabitosWearApp extends StatelessWidget {
  const HabitosWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalHabit Wear',
      debugShowCheckedModeBanner: false,
      theme: WearTheme.darkTheme,
      home: const WearRootRouter(),
    );
  }
}

class WearRootRouter extends StatelessWidget {
  const WearRootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final wearProvider = context.watch<WearProvider>();

    // 1. Si está activo el modo Always-On Display (AOD)
    if (wearProvider.isAmbientMode) {
      return const WearAmbientScreen();
    }

    // 2. Si el dispositivo ya está vinculado a la app móvil
    if (wearProvider.isPaired) {
      return const WearDashboardScreen();
    }

    // 3. Si aún no está vinculado, mostrar pantalla con PIN de 4 dígitos
    return const WearPairingScreen();
  }
}
