class Note {
  String id;
  String title;
  String text;
  String timestamp;
  String? imagePath; // Optional: link to original scanned image

  Note({
    required this.id,
    required this.title,
    required this.text,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "text": text,
    "timestamp": timestamp,
    if (imagePath != null) "imagePath": imagePath,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json["id"],
    title: json["title"],
    text: json["text"],
    timestamp: json["timestamp"],
    imagePath: json["imagePath"],
  );
}
