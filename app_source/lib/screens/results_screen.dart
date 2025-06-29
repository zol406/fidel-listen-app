import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import '../models/scan_history.dart';

enum TtsState { playing, stopped, paused }

class ResultsScreen extends StatefulWidget {
  final String? imagePath;
  final ScanHistory? historyItem;

  const ResultsScreen({super.key, this.imagePath, this.historyItem})
      : assert(imagePath != null || historyItem != null);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isProcessingOcr = true;
  final TextEditingController _textController = TextEditingController();

  late FlutterTts flutterTts;
  TtsState _ttsState = TtsState.stopped;
  double _speechRate = 0.5;
  List<Map<String, String>> _amharicVoices = []; // Corrected Type
  Map<String, String>? _currentVoice; // Corrected Type

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.historyItem != null) {
      _loadFromHistory();
    } else {
      _performOcr();
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();

    flutterTts.setStartHandler(() => setState(() => _ttsState = TtsState.playing));
    flutterTts.setCompletionHandler(() => setState(() => _ttsState = TtsState.stopped));
    flutterTts.setErrorHandler((msg) => setState(() => _ttsState = TtsState.stopped));

    try {
      var voices = await flutterTts.getVoices as List;
      if (mounted) {
        // Correctly cast the voices to the required type
        _amharicVoices = voices
            .map((voice) => Map<String, String>.from(voice))
            .where((voice) => (voice['locale'] as String).contains('am'))
            .toList();
            
        if (_amharicVoices.isNotEmpty) {
          _currentVoice = _amharicVoices.first;
          await flutterTts.setVoice(_currentVoice!); // THE FIRST FIX IS HERE
        }
      }
    } catch (e) {
      print('Error getting TTS voices: $e');
    }
    
    await flutterTts.setLanguage("am-ET");
    await flutterTts.setSpeechRate(_speechRate);

    if(mounted) setState(() {});
  }

  void _loadFromHistory() {
    setState(() {
      _textController.text = widget.historyItem!.recognizedText;
      _isProcessingOcr = false;
    });
  }

  Future<void> _performOcr() async {
    final fakePath = '/data/user/0/com.example.fidel_listen_final/cache/placeholder.jpg';
    try {
      String text = await FlutterTesseractOcr.extractText(
        widget.imagePath!,
        language: 'amh',
      );
      
      final historyBox = Hive.box<ScanHistory>('scans');
      await historyBox.add(ScanHistory(
        imagePath: fakePath, 
        recognizedText: text,
        timestamp: DateTime.now(),
      ));

      if (mounted) {
        setState(() {
          _textController.text = text;
          _isProcessingOcr = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _textController.text = "Error performing OCR: $e";
          _isProcessingOcr = false;
        });
      }
    }
  }

  Future<void> _speak() async {
    if (_textController.text.isNotEmpty) {
      if (_ttsState == TtsState.paused || _ttsState == TtsState.stopped) {
        await flutterTts.speak(_textController.text);
      }
    }
  }

  Future<void> _pause() async {
    if (_ttsState == TtsState.playing) {
      await flutterTts.pause();
      setState(() => _ttsState = TtsState.paused);
    }
  }

  Future<void> _stop() async {
    await flutterTts.stop();
    setState(() => _ttsState = TtsState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = widget.imagePath != null && File(widget.imagePath!).existsSync()
      ? Image.file(File(widget.imagePath!), fit: BoxFit.contain)
      : Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.history_edu, size: 50, color: Colors.white)));

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: imageWidget,
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isProcessingOcr
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Recognizing Amharic text..."),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Recognized Text (Editable):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTtsControls(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTtsControls() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.stop), onPressed: _stop, iconSize: 30, color: Colors.redAccent),
              IconButton(
                icon: _ttsState == TtsState.playing ? const Icon(Icons.pause_circle) : const Icon(Icons.play_circle),
                iconSize: 50,
                color: Theme.of(context).primaryColor,
                onPressed: _ttsState == TtsState.playing ? _pause : _speak,
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _textController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Text copied to clipboard!')),
                  );
                },
                iconSize: 30,
              ),
            ],
          ),
          TextButton.icon(
            icon: const Icon(Icons.record_voice_over, size: 20),
            label: Text(_currentVoice?['name'] ?? 'Default Voice', style: const TextStyle(fontSize: 12)),
            onPressed: _showVoiceSelectionDialog,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Slow'),
              Expanded(
                child: Slider(
                  value: _speechRate,
                  onChanged: (rate) {
                    setState(() => _speechRate = rate);
                    flutterTts.setSpeechRate(rate);
                  },
                  min: 0.1,
                  max: 1.0,
                ),
              ),
              const Text('Fast'),
            ],
          ),
        ],
      ),
    );
  }

  void _showVoiceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Voice'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _amharicVoices.length,
              itemBuilder: (context, index) {
                final voice = _amharicVoices[index];
                return ListTile(
                  title: Text(voice['name'] ?? 'Unknown Voice'),
                  onTap: () {
                    setState(() {
                      _currentVoice = voice;
                      flutterTts.setVoice(_currentVoice!); // THE SECOND FIX IS HERE
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
