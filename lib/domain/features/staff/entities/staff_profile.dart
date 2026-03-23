import 'package:equatable/equatable.dart';

class StaffProfileAddress extends Equatable {
  const StaffProfileAddress({
    this.street = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
  });

  final String street;
  final String line2;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  String get formattedAddress {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (line2.isNotEmpty) parts.add(line2);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipCode.isNotEmpty) parts.add(zipCode);
    if (country.isNotEmpty) parts.add(country);
    return parts.isEmpty ? '' : parts.join(', ');
  }

  @override
  List<Object?> get props => [street, line2, city, state, zipCode, country];
}

class StaffProfileTime extends Equatable {
  const StaffProfileTime({
    required this.hour,
    required this.minute,
    this.second = 0,
    this.nano = 0,
  });

  final int hour;
  final int minute;
  final int second;
  final int nano;

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute$period';
  }

  @override
  List<Object?> get props => [hour, minute, second, nano];
}

class StaffProfileWorkSchedule extends Equatable {
  const StaffProfileWorkSchedule({
    required this.dayOfWeek,
    required this.workStartTime,
    required this.workEndTime,
  });

  final String dayOfWeek;
  final StaffProfileTime workStartTime;
  final StaffProfileTime workEndTime;

  String get formattedTime {
    return '${workStartTime.formattedTime} - ${workEndTime.formattedTime}';
  }

  @override
  List<Object?> get props => [dayOfWeek, workStartTime, workEndTime];
}

class StaffProfileBreakSchedule extends Equatable {
  const StaffProfileBreakSchedule({
    required this.dayOfWeek,
    required this.breakType,
    required this.breakStartTime,
    required this.breakEndTime,
  });

  final String dayOfWeek;
  final String breakType;
  final StaffProfileTime breakStartTime;
  final StaffProfileTime breakEndTime;

  String get formattedTime {
    return '${breakStartTime.formattedTime} - ${breakEndTime.formattedTime}';
  }

  @override
  List<Object?> get props => [dayOfWeek, breakType, breakStartTime, breakEndTime];
}

class StaffProfile extends Equatable {
  const StaffProfile({
    required this.staffCode,
    required this.userCode,
    required this.organizationCode,
    required this.schoolCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoUrl = '',
    this.birthDate = '',
    required this.staffType,
    /// User-service role for school-users activate/deactivate (e.g. LEAD_TEACHER, SCHOOL_ADMIN).
    this.schoolUserRole = '',
    required this.status,
    required this.designation,
    this.jobTag = '',
    this.clockPin = '',
    this.primaryClassroomCode = '',
    required this.allowedClassroomCodes,
    required this.address,
    required this.workSchedules,
    required this.breakSchedules,
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String staffCode;
  final String userCode;
  final String organizationCode;
  final String schoolCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String profilePhotoUrl;
  final String birthDate;
  final String staffType;
  final String schoolUserRole;
  final String status;
  final String designation;
  final String jobTag;
  final String clockPin;
  final String primaryClassroomCode;
  final List<String> allowedClassroomCodes;
  final StaffProfileAddress address;
  final List<StaffProfileWorkSchedule> workSchedules;
  final List<StaffProfileBreakSchedule> breakSchedules;
  final String createdAt;
  final String updatedAt;

  @override
  List<Object?> get props => [
        staffCode,
        userCode,
        organizationCode,
        schoolCode,
        firstName,
        lastName,
        fullName,
        email,
        phoneNumber,
        profilePhotoUrl,
        birthDate,
        staffType,
        schoolUserRole,
        status,
        designation,
        jobTag,
        clockPin,
        primaryClassroomCode,
        allowedClassroomCodes,
        address,
        workSchedules,
        breakSchedules,
        createdAt,
        updatedAt,
      ];
}

