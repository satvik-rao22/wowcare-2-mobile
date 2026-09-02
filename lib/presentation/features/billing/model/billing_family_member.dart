import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';

/// A student or guardian shown on the family billing screens (siblings card,
/// statements tabs, generate-statement selector, family chips/parents line).
///
/// Presentation carrier only: it replaces the raw `Map<String, dynamic>` that
/// was threaded between the transaction-details state, the parent/admin
/// statements widgets and the generate-statement screen. Fields are nullable to
/// preserve the exact `?? fallback` semantics the widgets relied on when a key
/// was absent from the old map (e.g. `name ?? fullName`, `room ?? roomName`).
class BillingFamilyMember extends Equatable {
  const BillingFamilyMember({
    this.code,
    this.fullName,
    this.name,
    this.room,
    this.roomName,
    this.role,
    this.outstanding,
    this.photoUuid,
  });

  /// Maps a family-ledger person (student/guardian) exactly as the old
  /// `_mapPeople` map did: code/fullName/role/outstanding from the entity, a
  /// null photo. `name`/`room`/`roomName` stay null so the widgets fall back to
  /// `fullName` just as they did when those keys were absent.
  factory BillingFamilyMember.fromEntity(FamilyLedgerPersonEntity person) {
    return BillingFamilyMember(
      code: person.code,
      fullName: person.fullName,
      role: person.role,
      outstanding: person.outstanding,
      photoUuid: null,
    );
  }

  final String? code;
  final String? fullName;
  final String? name;
  final String? room;
  final String? roomName;
  final String? role;
  final double? outstanding;
  final String? photoUuid;

  @override
  List<Object?> get props =>
      [code, fullName, name, room, roomName, role, outstanding, photoUuid];
}
