// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:schoolerp/core/util/api_paths.dart';
// import 'package:schoolerp/core/util/constants.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// /// Model class for a student in a room, used for deserializing API responses.
// class StudentByRoom {
//   final int id;
//   final String fullName;
//   final bool isPresentToday; // Represents napping status or presence

//   StudentByRoom({
//     required this.id,
//     required this.fullName,
//     required this.isPresentToday,
//   });

//   factory StudentByRoom.fromJson(Map<String, dynamic> json) {
//     return StudentByRoom(
//       id: json['id'] as int? ?? 0,
//       fullName: json['fullName'] as String? ?? '',
//       isPresentToday: json['isPresentToday'] as bool? ?? false,
//     );
//   }

//   List get activities => activities;
// }

// /// Service class for handling API requests related to the SchoolERP application.
// class ApiService {
//   /// Fetches the list of students by room ID, including their napping status.
//   ///
//   /// [roomId] is the ID of the room to fetch students for.
//   /// [context] is used to display error messages via snackbar.
//   ///
//   /// Returns a list of [StudentByRoom] objects or an empty list if the request fails.
//   Future<List<StudentByRoom>> fetchStudentsByRoom(
//       String roomId, BuildContext context) async {
//     try {
//       // NOTE: Auth token is intentionally NOT sent for this request.
//       // Only send basic JSON headers so the API is called without Authorization.
//       final headers = {
//         'Content-Type': 'application/json',
//       };

//       String path = APIPathHelper.getValue(APIPath.studentsByRoom);
//       final url = Uri.parse('$baseUrl$path/$roomId');
//       // var request = http.Request('GET', url);

//       // Send request
//       // final url = Uri.parse(
//       //     'https://qa.childcarewow.app/wowcare-qa/api/students-by-room/$roomId');
//       AppLogger.d('Fetching napping status for URL: $url');
//       final response = await http.get(url, headers: headers).timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           if (context.mounted) {
//             _showErrorSnackBar(context, 'Request timed out. Please try again.');
//           }
//           return http.Response('Timeout', 408);
//         },
//       );

//       // Handle response
//       switch (response.statusCode) {
//         case 200:
//           final List<dynamic> studentsJson = jsonDecode(response.body);
//           return studentsJson
//               .map((json) => StudentByRoom.fromJson(json))
//               .toList();
//         case 401:
//           if (context.mounted) {
//             _showErrorSnackBar(context, 'Session expired. Please login again.');
//           }
//           return [];
//         case 404:
//           if (context.mounted) {
//             _showErrorSnackBar(context, 'Room not found.');
//           }
//           return [];
//         case 500:
//         case 503:
//           if (context.mounted) {
//             _showErrorSnackBar(
//                 context, 'Server unavailable. Please try again later.');
//           }
//           return [];
//         default:
//           if (context.mounted) {
//             _showErrorSnackBar(
//                 context, response.reasonPhrase ?? 'Failed to fetch students.');
//           }
//           return [];
//       }
//     } catch (e) {
//       debugPrint('Error fetching students by room: $e');
//       if (context.mounted) {
//         _showErrorSnackBar(context, 'Error fetching students: $e');
//       }
//       return [];
//     }
//   }

//   /// Displays an error snackbar with the provided message.
//   void _showErrorSnackBar(BuildContext context, String message) {
//     CoreUtils.showTopSnackBar(
//       context: context,
//       isError: true,
//       isWarning: false,
//       isSuccess: false,
//       isAdjust: false,
//       message: message,
//     );
//   }
// }
