class DocumentItem {
  const DocumentItem({
    required this.docId,
    required this.filename,
    required this.uploadTimestamp,
    required this.chunkCount,
  });

  final String docId;
  final String filename;
  final int uploadTimestamp;
  final int chunkCount;

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      docId: json['doc_id'] as String? ?? '',
      filename: json['filename'] as String? ?? 'Untitled',
      uploadTimestamp: (json['upload_timestamp'] as num?)?.toInt() ?? 0,
      chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime get uploadedAt => DateTime.fromMillisecondsSinceEpoch(uploadTimestamp * 1000);
}
