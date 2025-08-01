import 'package:hive/hive.dart';

part 'scan_history.g.dart';

@HiveType(typeId: 0)
class ScanHistory extends HiveObject {
  @HiveField(0)
  late String imagePath;

  @HiveField(1)
  late String recognizedText;

  @HiveField(2)
  late DateTime timestamp;

  ScanHistory({
    required this.imagePath,
    required this.recognizedText,
    required this.timestamp,
  });
}
