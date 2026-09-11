class Citation {
  const Citation({
    required this.filename,
    required this.chunkText,
    required this.score,
  });

  final String filename;
  final String chunkText;
  final double score;

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      filename: json['filename'] as String? ?? 'unknown',
      chunkText: json['chunk_text'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'chunk_text': chunkText,
        'score': score,
      };
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.source,
    this.citations = const [],
    this.audioBase64,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? source; // "knowledge_base" | "llm_general" | "refused"
  final List<Citation> citations;
  final String? audioBase64;
}
