import 'package:flutter/material.dart';
import 'package:habitos_wear/config/wear_theme.dart';

class WearHabitModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String targetType;
  final int targetValue;
  final int currentProgress;
  final String unit;
  final bool isCompleted;

  const WearHabitModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'otro',
    this.targetType = 'simpleCheck',
    this.targetValue = 1,
    this.currentProgress = 0,
    this.unit = 'check',
    this.isCompleted = false,
  });

  factory WearHabitModel.fromJson(Map<String, dynamic> json) {
    return WearHabitModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Hábito',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'otro',
      targetType: json['targetType']?.toString() ?? 'simpleCheck',
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      unit: json['unit']?.toString() ?? 'check',
      isCompleted: json['isCompleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'targetType': targetType,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'unit': unit,
      'isCompleted': isCompleted,
    };
  }

  double get progressFraction {
    if (isCompleted) return 1.0;
    if (targetValue <= 0) return 0.0;
    final frac = currentProgress / targetValue;
    return frac.clamp(0.0, 1.0);
  }

  String get progressDisplay {
    if (targetType == 'water') {
      return '$currentProgress / $targetValue $unit';
    } else if (targetType == 'timer') {
      return '$currentProgress / $targetValue min';
    } else if (targetType == 'steps') {
      return '$currentProgress / $targetValue pasos';
    } else if (targetType == 'counter') {
      return '$currentProgress / $targetValue $unit';
    }
    return isCompleted ? 'Completado' : 'Pendiente';
  }

  Color get accentColor {
    switch (targetType.toLowerCase()) {
      case 'water':
        return WearTheme.water;
      case 'timer':
        return WearTheme.timer;
      case 'steps':
        return WearTheme.steps;
      case 'counter':
        return WearTheme.secondary;
      default:
        switch (category.toLowerCase()) {
          case 'salud':
            return WearTheme.success;
          case 'estudio':
            return WearTheme.primary;
          case 'fitness':
            return WearTheme.steps;
          default:
            return WearTheme.primary;
        }
    }
  }

  IconData get iconData {
    switch (targetType.toLowerCase()) {
      case 'water':
        return Icons.water_drop_rounded;
      case 'timer':
        return Icons.timer_rounded;
      case 'steps':
        return Icons.directions_walk_rounded;
      case 'counter':
        return Icons.numbers_rounded;
      default:
        switch (category.toLowerCase()) {
          case 'salud':
            return Icons.favorite_rounded;
          case 'estudio':
            return Icons.menu_book_rounded;
          case 'fitness':
            return Icons.fitness_center_rounded;
          default:
            return Icons.check_circle_outline_rounded;
        }
    }
  }

  WearHabitModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? targetType,
    int? targetValue,
    int? currentProgress,
    String? unit,
    bool? isCompleted,
  }) {
    return WearHabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
