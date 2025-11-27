class Note {
  String id;
  String title;
  String text;
  String timestamp;

  Note({
    required this.id,
    required this.title,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "text": text,
    "timestamp": timestamp,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json["id"],
    title: json["title"],
    text: json["text"],
    timestamp: json["timestamp"],
  );
}
