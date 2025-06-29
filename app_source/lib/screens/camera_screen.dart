import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(_cameras[0], ResolutionPreset.high);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Failed to initialize camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    final XFile image = await _controller!.takePicture();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(imagePath: image.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: Text("Initializing Camera...")),
      );
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.yellow.withOpacity(0.7),
                width: 3,
              ),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera, color: Colors.white),
                iconSize: 70,
                style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
