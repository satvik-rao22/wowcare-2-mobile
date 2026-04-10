import 'package:flutter/material.dart';

enum MovementStatus { overdue, upcoming, confirmed, rejected }

class MovementItem {
  const MovementItem({
    required this.id,
    required this.name,
    required this.fromClassroom,
    required this.toClassroom,
    required this.movementDate,
    this.comment = '',
    required this.status,
  });

  final int id;
  final String name;
  final String fromClassroom;
  final String toClassroom;
  final DateTime movementDate;
  final String comment;
  final MovementStatus status;

  MovementItem copyWith({
    String? name,
    String? fromClassroom,
    String? toClassroom,
    DateTime? movementDate,
    String? comment,
    MovementStatus? status,
  }) {
    return MovementItem(
      id: id,
      name: name ?? this.name,
      fromClassroom: fromClassroom ?? this.fromClassroom,
      toClassroom: toClassroom ?? this.toClassroom,
      movementDate: movementDate ?? this.movementDate,
      comment: comment ?? this.comment,
      status: status ?? this.status,
    );
  }
}

class MovementSection {
  const MovementSection({
    required this.title,
    required this.backgroundColor,
    required this.status,
    required this.items,
  });

  final String title;
  final Color backgroundColor;
  final MovementStatus status;
  final List<MovementItem> items;
}

class MovementFormResult {
  const MovementFormResult({
    required this.student,
    required this.currentClassroom,
    required this.nextClassroom,
    required this.movementDate,
    required this.comment,
  });

  final String student;
  final String currentClassroom;
  final String nextClassroom;
  final DateTime movementDate;
  final String comment;
}
