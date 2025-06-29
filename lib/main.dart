import 'package:fidel_listen_app/models/scan_history.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ScanHistoryAdapter());
    await Hive.openBox<ScanHistory>('scans');
  } catch (e) {
    print('Hive initialization failed (expected in cloud build): $e');
  }

  runApp(const FidelListenApp());
}

class FidelListenApp extends StatelessWidget {
  const FidelListenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fidel Listen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
