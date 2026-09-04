import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/students/models/info_row.dart';

/// Which list a person belongs to, and therefore what the card offers.
enum PersonKind {
  /// A parent or guardian on the record: `StudentGuardian`. Message them.
  guardian,

  /// Someone allowed to collect: `StudentPickup`. Call them.
  pickup,
}

/// What a badge on a person card says about them.
enum PersonBadgeTone {
  /// Emergency contact: called first.
  emergency,

  /// A standing arrangement, in the student tint.
  arrangement,

  /// A lapsed pass, drawn quietly rather than in red: it is not a danger.
  lapsed,
}

/// A parent, guardian or pickup contact on a student's record (5c Family and
/// Pickup).
///
/// Mirrors `StudentGuardian` (relation, mobile, email, clockPin,
/// primaryContact, legalCustody) and `StudentPickup` (relation, phoneNumber,
/// clockPin, pickupType).
@immutable
class StudentPerson extends Equatable {
  const StudentPerson({
    required this.id,
    required this.name,
    required this.initials,
    required this.relation,
    required this.kind,
    this.badge,
    this.badgeTone = PersonBadgeTone.arrangement,
    this.rows = const <InfoRow>[],
  });

  final String id;
  final String name;
  final String initials;

  /// Mother, Father, Grandmother, Family friend.
  final String relation;

  final PersonKind kind;

  /// "Emergency contact", "Fridays only", "Expired". Null draws no badge.
  final String? badge;
  final PersonBadgeTone badgeTone;

  /// Phone, email, Sign-In PIN, legal custody: whatever the record carries.
  final List<InfoRow> rows;

  @override
  List<Object?> get props => [
    id,
    name,
    initials,
    relation,
    kind,
    badge,
    badgeTone,
    rows,
  ];
}
