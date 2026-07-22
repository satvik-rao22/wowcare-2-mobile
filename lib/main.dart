import 'package:flutter/material.dart';
import 'package:wowcare/app/app.dart';
import 'package:wowcare/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppBootstrap.initialize();

  runApp(const MyApp());
}
