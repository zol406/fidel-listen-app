import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/scan_history.dart';
import 'camera_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  late Box<ScanHistory> historyBox;

  @override
  void initState() {
    super.initState();
    historyBox = Hive.box<ScanHistory>('scans');
  }

  Future<void> _importFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      print("Error picking image from gallery: $e");
    }
  }

  void _scanWithCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fidel Listen (áŠá‹°áˆ áˆµáˆ›)'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildActionButtons(),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Recent Scans',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildHistoryList()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _scanWithCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _importFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return ValueListenableBuilder<Box<ScanHistory>>(
      valueListenable: historyBox.listenable(),
      builder: (context, box, _) {
        final scans = box.values.toList().cast<ScanHistory>().reversed.toList();
        if (scans.isEmpty) {
          return const Center(
            child: Text(
              'No scans yet.\nStart by using the camera or gallery!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: scans.length,
          itemBuilder: (context, index) {
            final scan = scans[index];
            return Dismissible(
              key: Key(scan.key.toString()),
              onDismissed: (direction) {
                scan.delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan deleted')),
                );
              },
              background: Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.history_edu, size: 40),
                  title: Text(
                    'Scan from ${scan.timestamp.day}/${scan.timestamp.month}/${scan.timestamp.year}',
                  ),
                  subtitle: Text(
                    scan.recognizedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultsScreen(historyItem: scan),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
