import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://qs176zl8-8083.inc1.devtunnels.ms/api/v1/classroom/all-classrooms?schoolCode=SCH_1A748EF9-5&statuses=ACTIVE';
  final response = await http.get(Uri.parse(url), headers: {'accept': 'application/json'});
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
