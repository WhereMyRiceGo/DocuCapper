class ScanHistoryItem {
  String id;
  String imagePath;
  String extractedText;
  String timestamp;

  ScanHistoryItem({
    required this.id,
    required this.imagePath,
    required this.extractedText,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "imagePath": imagePath,
    "extractedText": extractedText,
    "timestamp": timestamp,
  };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) =>
      ScanHistoryItem(
        id: json["id"],
        imagePath: json["imagePath"],
        extractedText: json["extractedText"],
        timestamp: json["timestamp"],
      );
}
