class Note {
  final String id;
  final String title;
  final String body;
  final bool hasImage;
  final bool hasAudio;
  final List<String> tags;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.body,
    this.hasImage = false,
    this.hasAudio = false,
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
