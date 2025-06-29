import 'package:fidel_listen_final/models/scan_history.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ScanHistoryAdapter());
  await Hive.openBox<ScanHistory>('scans');
  runApp(const FidelListenApp());
}

class FidelListenApp extends StatelessWidget {
  const FidelListenApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fidel Listen',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
