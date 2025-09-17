// import 'dart:convert';
// import 'dart:io';

// import 'package:http/http.dart' as http;
// import 'package:schoolerp/core/util/typedefs.dart';
// import '../errors/ApiException.dart';

// class ApiBaseHelper {
//   final String _baseUrl = "http://qa.techvgi.com/schoolerp-qa/";

//   Future<dynamic> get(String url) async {
//     var responseJson;
//     try {
//       final response = await http.get(Uri.parse(url));
//       responseJson = returnResponse(response);
//     } on SocketException {
//       throw FetchDataException('No Internet connection');
//     }
//     return responseJson;
//   }

//   Future<dynamic> fetch(String url, String token) async {
//     var responseJson;
//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'accept': '*/*',
//           'Content-Type': 'application/json',
//         },
//       );
//       responseJson = returnResponse(response);
//     } on SocketException {
//       throw FetchDataException('No Internet connection');
//     }
//     return responseJson;
//   }

//   Future<dynamic> post(String url, dynamic data, String token) async {
//     var responseJson;
//     try {
//       final response = await http.post(
//         Uri.parse(_baseUrl + url),
//         body: json.encode(data),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'accept': '*/*',
//           'Content-Type': 'application/json',
//         },
//       );
//       responseJson = returnResponse(response);
//     } on SocketException {
//       throw FetchDataException('No Internet connection');
//     }
//     return responseJson;
//   }

//   Future<dynamic> access(String url, dynamic data) async {
//     var responseJson;
//     try {
//       final response = await http.post(
//         Uri.parse(_baseUrl + url),
//         body: json.encode(data),
//         headers: {'accept': '*/*', 'Content-Type': 'application/json'},
//       );
//       responseJson = returnResponse(response);
//     } on SocketException {
//       throw FetchDataException('No Internet connection');
//     }
//     return responseJson;
//   }

//   dynamic returnResponse(http.Response response) {
//     switch (response.statusCode) {
//       case 200:
//         var responseJson = json.decode(response.body) as DataMap;
//         print(responseJson);
//         return responseJson;
//       case 400:
//         throw BadRequestException(response.body.toString());
//       case 401:
//         throw UnauthorisedException(response.body.toString());
//       case 403:
//         throw UnauthorisedException(response.body.toString());
//       case 503:
//         throw ServerException(response.body.toString());
//       case 500:
//       default:
//         throw FetchDataException(
//           'Error occurred while Communication with Server with StatusCode : ${response.statusCode}',
//         );
//     }
//   }
// }
