// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:schoolerp/core/common/app/providers/auth_providers.dart';
// import 'package:schoolerp/features/school/data/model/schoolDataModel.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

// void initializeTimeZones() {
//   tz.initializeTimeZones();
// }

// String convertLocalToUtc(DateTime localDateTime) {
//   final utcDateTime = localDateTime.toUtc();
//   // print('utcDateTime.toIso8601String()  $utcDateTime.toIso8601String()');
//   return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(utcDateTime) + 'Z';
// }

// Future<String> convertUtcToLocal(
//     String utcDateTimeString, BuildContext context) async {
//   tz.initializeTimeZones();

//   SchoolDataModel school = context.read<AuthProvider>().getUserSchool();
//   String localTimeZone = school.timeZone;

//   final utcDateTime = DateTime.parse(utcDateTimeString).toUtc();

//   final location = tz.getLocation(localTimeZone);

//   final localDateTime = tz.TZDateTime.from(utcDateTime, location);

//   String formattedLocalDateTime =
//       DateFormat('yyyy-MM-ddTHH:mm:ss').format(localDateTime) + 'Z';

//   // print('Local DateTime: $formattedLocalDateTime');

//   return formattedLocalDateTime;
// }

// Future<String> convertDateTimeNowToTimeZoneOne(BuildContext context) async {
//   tz.initializeTimeZones();

//   SchoolDataModel school = context.read<AuthProvider>().getUserSchool();
//   String localTimeZone = school.timeZone;

//   final utcDateTime = DateTime.now().toUtc();

//   final location = tz.getLocation(localTimeZone);

//   final localDateTime = tz.TZDateTime.from(utcDateTime, location);

//   String formattedLocalDateTime =
//       DateFormat('yyyy-MM-ddTHH:mm:ss').format(localDateTime) + 'Z';

//   // print('Local DateTime: $formattedLocalDateTime');

//   return formattedLocalDateTime;
// }

// String convertUTCtoLocalZoneTime(
//     String utcDateTimeString, BuildContext context) {
//   tz.initializeTimeZones();

//   SchoolDataModel school = context.read<AuthProvider>().getUserSchool();
//   String localTimeZone = school.timeZone;

//   final utcDateTime = DateTime.parse(utcDateTimeString).toUtc();

//   final location = tz.getLocation(localTimeZone);

//   final localDateTime = tz.TZDateTime.from(utcDateTime, location);

//   String formattedLocalDateTime =
//       DateFormat('yyyy-MM-ddTHH:mm:ss').format(localDateTime) + 'Z';

//   // print('Local DateTime: $formattedLocalDateTime');

//   return formattedLocalDateTime;
// }

// String convertDateTimeToIsoString(
//   DateTime dateTime,
// ) {
//   String formattedDateTime =
//       DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime) + 'Z';

//   return formattedDateTime;
// }

// TimeOfDay parseTimeOfDayFromString(String timeWithSecondsAmPm) {
//   final DateTime parsedTime =
//       DateFormat('hh:mm:ss a').parse(timeWithSecondsAmPm);
//   return TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
// }

// String convertUtcTimeofDayToLocalTimeOfDay(
//     String timeOfDay, BuildContext context) {
//   tz.initializeTimeZones();
//   final parts = timeOfDay.split(':');

//   int hour = int.parse(parts[0]);
//   int minute = int.parse(parts[1]);
//   int second = parts.length > 2 ? int.parse(parts[2]) : 0;
//   SchoolDataModel school = context.read<AuthProvider>().getUserSchool();
//   String localTimeZone = school.timeZone;
//   final now = DateTime.now().toUtc();
//   final utcDateTime =
//       DateTime.utc(now.year, now.month, now.day, hour, minute, second);

//   final location = tz.getLocation(localTimeZone);
//   final localDateTime = tz.TZDateTime.from(utcDateTime, location);

//   final formattedHour = localDateTime.hour.toString().padLeft(2, '0');
//   final formattedMin = localDateTime.minute.toString().padLeft(2, '0');
//   final formattedSec = localDateTime.second.toString().padLeft(2, '0');

//   return "$formattedHour:$formattedMin:$formattedSec";
// }

// String convertLocalTimeOfDayToUtcTimeOfDay(
//     String localTime, BuildContext context) {
//   tz.initializeTimeZones();
//   final parts = localTime.split(':');
//   int hour = int.parse(parts[0]);
//   int minute = int.parse(parts[1]);
//   int second = parts.length > 2 ? int.parse(parts[2]) : 0;

//   SchoolDataModel school = context.read<AuthProvider>().getUserSchool();
//   String localTimeZone = school.timeZone;

//   final location = tz.getLocation(localTimeZone);

//   final now = DateTime.now();
//   final localDateTime = tz.TZDateTime(
//       location, now.year, now.month, now.day, hour, minute, second);

//   final utcDateTime = localDateTime.toUtc();

//   final formattedHour = utcDateTime.hour.toString().padLeft(2, '0');
//   final formattedMin = utcDateTime.minute.toString().padLeft(2, '0');
//   final formattedSec = utcDateTime.second.toString().padLeft(2, '0');

//   return "$formattedHour:$formattedMin:$formattedSec";
// }

// int convertDateTimeNowToUtcTimestamp() {
//   Timestamp utcTimestamp = Timestamp.fromDate(DateTime.now().toUtc());
//   return utcTimestamp.millisecondsSinceEpoch;
// }

// String convertUtcTimestampToIsoInTimeZone(
//   int timestamp,
//   BuildContext context,
// ) {
//   tz.initializeTimeZones();
//   SchoolDataModel school = context.read<AuthProvider>().getUserSchool();

//   String localTimeZone = school.timeZone;
//   final newTimestamp = Timestamp.fromMillisecondsSinceEpoch(timestamp);

//   DateTime utcDateTime = newTimestamp.toDate();

//   final location = tz.getLocation(localTimeZone);

//   final localDateTime = tz.TZDateTime.from(utcDateTime, location);

//   return DateFormat.jm().format(localDateTime);
// }
