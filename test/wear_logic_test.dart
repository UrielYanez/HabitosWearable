import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_wear/models/wear_habit_model.dart';
import 'package:habitos_wear/providers/wear_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WearHabitModel Unit Tests', () {
    test('should parse JSON correctly into WearHabitModel', () {
      final json = {
        'id': 'habit_123',
        'name': 'Tomar 2L de Agua',
        'description': 'Mantenerse hidratado todo el día',
        'category': 'salud',
        'targetType': 'water',
        'targetValue': 2000,
        'currentProgress': 750,
        'unit': 'ml',
        'isCompleted': false,
      };

      final model = WearHabitModel.fromJson(json);

      expect(model.id, equals('habit_123'));
      expect(model.name, equals('Tomar 2L de Agua'));
      expect(model.targetType, equals('water'));
      expect(model.targetValue, equals(2000));
      expect(model.currentProgress, equals(750));
      expect(model.progressFraction, closeTo(750 / 2000, 0.001));
      expect(model.progressDisplay, equals('750 / 2000 ml'));
      expect(model.isCompleted, isFalse);
    });

    test('should correctly compute progress fraction for completed habit', () {
      const model = WearHabitModel(
        id: 'h2',
        name: 'Leer 20 min',
        targetType: 'timer',
        targetValue: 20,
        currentProgress: 20,
        isCompleted: true,
      );

      expect(model.progressFraction, equals(1.0));
      expect(model.progressDisplay, equals('20 / 20 min'));
    });

    test('should serialize to JSON correctly', () {
      const model = WearHabitModel(
        id: 'h3',
        name: 'Caminar 8000 pasos',
        targetType: 'steps',
        targetValue: 8000,
        currentProgress: 4000,
        unit: 'pasos',
      );

      final json = model.toJson();
      expect(json['id'], equals('h3'));
      expect(json['name'], equals('Caminar 8000 pasos'));
      expect(json['targetType'], equals('steps'));
      expect(json['targetValue'], equals(8000));
      expect(json['currentProgress'], equals(4000));
    });

    test('copyWith should clone without mutating other fields', () {
      const original = WearHabitModel(
        id: 'h4',
        name: 'Meditar',
        targetType: 'timer',
        targetValue: 15,
        currentProgress: 0,
        isCompleted: false,
      );

      final updated = original.copyWith(
        currentProgress: 15,
        isCompleted: true,
      );

      expect(updated.id, equals('h4'));
      expect(updated.name, equals('Meditar'));
      expect(updated.currentProgress, equals(15));
      expect(updated.isCompleted, isTrue);
      expect(original.isCompleted, isFalse);
    });
  });

  group('WearProvider State Tests', () {
    test('initial state should have 0 completion rate and empty habits', () {
      final provider = WearProvider();

      expect(provider.habits, isEmpty);
      expect(provider.completionRate, equals(0.0));
      expect(provider.completedCount, equals(0));
      expect(provider.totalCount, equals(0));
      expect(provider.isAmbientMode, isFalse);
    });

    test('toggleAmbientMode should toggle AOD state', () {
      final provider = WearProvider();
      expect(provider.isAmbientMode, isFalse);

      provider.toggleAmbientMode(true);
      expect(provider.isAmbientMode, isTrue);

      provider.toggleAmbientMode(false);
      expect(provider.isAmbientMode, isFalse);
    });
  });
}
