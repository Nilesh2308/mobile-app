import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/document_item.dart';
import '../services/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

enum FileUploadStatus {
  uploading,
  processing,
  done,
  error,
}

class FileUploadTask {
  FileUploadTask({
    required this.name,
    required this.size,
    this.status = FileUploadStatus.uploading,
    this.progress = 0.0,
    this.errorMessage,
    this.chunksCount,
  });

  final String name;
  final int size;
  FileUploadStatus status;
  double progress;
  String? errorMessage;
  int? chunksCount;
}

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final ApiClient _apiClient = const ApiClient();

  bool _isLoading = false;
  List<DocumentItem> _documents = [];
  final List<FileUploadTask> _activeUploads = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final docRes = await _apiClient.listDocuments();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (docRes.isSuccess && docRes.data != null) {
        _documents = docRes.data!;
      } else {
        _documents = [];
        if (mounted) {
          AppToast.show(
            context,
            title: 'Connection Error',
            message: 'Could not load documents from backend. Check your server connection.',
            variant: AppToastVariant.error,
          );
        }
      }
    });
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      final pickedFiles = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );

      if (pickedFiles.isEmpty) return;

      final tasks = pickedFiles.map((f) {
        return FileUploadTask(
          name: f.name,
          size: 0,
          status: FileUploadStatus.uploading,
          progress: 0.15,
        );
      }).toList();

      setState(() {
        _activeUploads.insertAll(0, tasks);
      });

      final filePaths = <String>[];
      final inMemoryFiles = <Map<String, dynamic>>[];

      for (final f in pickedFiles) {
        if (f.path != null && f.path!.isNotEmpty) {
          filePaths.add(f.path!);
        } else {
          final bytes = await f.readAsBytes();
          inMemoryFiles.add({'name': f.name, 'bytes': bytes});
        }
      }

      for (final t in tasks) {
        setState(() {
          t.status = FileUploadStatus.processing;
          t.progress = 0.65;
        });
      }

      final response = await _apiClient.uploadDocuments(
        filePaths: filePaths,
        inMemoryFiles: inMemoryFiles,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        for (final t in tasks) {
          setState(() {
            t.status = FileUploadStatus.done;
            t.progress = 1.0;
            t.chunksCount = 18;
          });
        }

        AppToast.show(
          context,
          title: 'Documents Uploaded',
          message: '${pickedFiles.length} document(s) embedded and indexed into Qdrant.',
          variant: AppToastVariant.success,
        );

        await _loadData();

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _activeUploads.removeWhere((t) => tasks.contains(t));
            });
          }
        });
      } else {
        for (final t in tasks) {
          setState(() {
            t.status = FileUploadStatus.error;
            t.errorMessage = response.error ?? 'Upload failed';
          });
        }

        AppToast.show(
          context,
          title: 'Upload Notice',
          message: response.error ?? 'Failed to upload documents. Check backend connection.',
          variant: AppToastVariant.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        title: 'Upload Error',
        message: e.toString(),
        variant: AppToastVariant.error,
      );
    }
  }

  Future<void> _openDocument(DocumentItem doc) async {
    final rawUrl = '${AppConfig.baseUrl}/api/kb/documents/${doc.docId}/download';
    final uri = Uri.parse(rawUrl);

    try {
      // 1. Try external browser or viewer app
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      // 2. Fallback to in-app browser view
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {}
      }

      // 3. Fallback to platform default
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched && mounted) {
        AppToast.show(
          context,
          title: 'Cannot Open Document',
          message: 'Could not launch browser or PDF viewer on this device.',
          variant: AppToastVariant.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Cannot Open Document',
          message: 'Error launching document: $e',
          variant: AppToastVariant.error,
        );
      }
    }
  }

  Future<void> _handleDelete(DocumentItem doc) async {
    final confirmed = await DeleteDocumentModal.show(
      context: context,
      document: doc,
      onConfirmDelete: () async {
        final res = await _apiClient.deleteDocument(doc.docId);
        return res.isSuccess;
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _documents.removeWhere((d) => d.docId == doc.docId);
      });

      AppToast.show(
        context,
        title: 'Document Deleted',
        message: '${doc.filename} and associated vector points removed.',
        variant: AppToastVariant.info,
      );

      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading && _documents.isEmpty) {
      return const AppLoadingState(
        message: 'Synchronizing Knowledge Base...',
        subMessage: 'Connecting to Qdrant vector index and domain summary',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: colors.primary,
      backgroundColor: colors.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        children: [
          // 1. Animated Upload Area Card
          _buildUploadDropZone(colors, isDark),
          AppSpacing.vGap20,

          // 2. Active Uploads Progress Tracking (if any)
          if (_activeUploads.isNotEmpty) ...[
            _buildActiveUploadsList(colors, isDark),
            AppSpacing.vGap20,
          ],

          // 3. Document List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Indexed Documents',
                        style: AppTextStyles.headingSmall(color: colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.hGap8,
                    AppBadge(
                      label: '${_documents.length}',
                      variant: AppBadgeVariant.neutral,
                      showDot: false,
                    ),
                  ],
                ),
              ),
              if (_documents.isNotEmpty) ...[
                AppSpacing.hGap8,
                AppBadge(
                  label: '${_documents.fold(0, (acc, d) => acc + d.chunkCount)} chunks',
                  variant: AppBadgeVariant.brand,
                  showDot: false,
                ),
              ],
            ],
          ),
          AppSpacing.vGap12,

          // 4. Document List / Empty State
          if (_documents.isEmpty && _activeUploads.isEmpty)
            AppEmptyState(
              title: 'No documents yet',
              description: 'Upload company policies, technical specifications, or handbooks to empower your AI with verifiable citations.',
              icon: LucideIcons.fileQuestion,
              actionText: 'Upload Document',
              actionLeadingIcon: LucideIcons.plus,
              onActionPressed: _pickAndUploadFiles,
            )
          else
            ..._documents.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: _buildDocumentCard(entry.value, colors, isDark)
                      .animate()
                      .fadeIn(
                        duration: 200.ms,
                        delay: Duration(milliseconds: entry.key * 60),
                      )
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 200.ms,
                        delay: Duration(milliseconds: entry.key * 60),
                        curve: Curves.easeOutCubic,
                      ),
                )),

          AppSpacing.vGap32,
        ],
      ),
    );
  }

  /// Premium animated Upload Area with gradient border and floating cloud icon
  Widget _buildUploadDropZone(AppThemeColors colors, bool isDark) {
    return GestureDetector(
      onTap: _pickAndUploadFiles,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20, vertical: AppSpacing.s24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    colors.primary.withValues(alpha: 0.06),
                    AppColors.auroraViolet.withValues(alpha: 0.04),
                  ]
                : [
                    colors.primaryContainer.withValues(alpha: 0.5),
                    colors.surface,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.borderR16,
          border: Border.all(
            color: colors.primary.withValues(alpha: isDark ? 0.25 : 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Animated floating cloud icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.2),
                    AppColors.auroraViolet.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.borderR16,
                boxShadow: isDark
                    ? AppShadows.neonGlow(colors.primary, intensity: 0.1, blur: 12)
                    : null,
              ),
              child: Icon(
                LucideIcons.cloudUpload,
                size: 26,
                color: colors.primary,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -4, duration: 1800.ms, curve: Curves.easeInOut),
            AppSpacing.vGap12,
            Text(
              'Tap to upload documents',
              style: AppTextStyles.headingSmall(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap4,
            Text(
              'Supports multi-select .pdf, .docx, and .txt files',
              style: AppTextStyles.caption(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap16,
            Wrap(
              spacing: AppSpacing.s6,
              runSpacing: AppSpacing.s6,
              alignment: WrapAlignment.center,
              children: const [
                AppBadge(label: 'PDF', variant: AppBadgeVariant.neutral, showDot: false),
                AppBadge(label: 'DOCX', variant: AppBadgeVariant.neutral, showDot: false),
                AppBadge(label: 'TXT', variant: AppBadgeVariant.neutral, showDot: false),
                AppBadge(label: 'Up to 10 files', variant: AppBadgeVariant.neutral, showDot: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Active Uploads Progress Card Group with gradient progress bars
  Widget _buildActiveUploadsList(AppThemeColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Uploads (${_activeUploads.length})',
          style: AppTextStyles.label(color: colors.textSecondary),
        ),
        AppSpacing.vGap8,
        ..._activeUploads.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Container(
                padding: AppSpacing.p12,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : colors.surfaceSecondary,
                  borderRadius: AppRadius.borderR12,
                  border: Border.all(
                    color: isDark ? colors.glassBorder : colors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildFileIcon(task.name, colors, size: 16),
                              AppSpacing.hGap8,
                              Expanded(
                                child: Text(
                                  task.name,
                                  style: AppTextStyles.bodyMedium(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.hGap8,
                        _buildStatusBadge(task, colors),
                      ],
                    ),
                    AppSpacing.vGap8,
                    // Gradient progress bar
                    ClipRRect(
                      borderRadius: AppRadius.borderRFull,
                      child: SizedBox(
                        height: 4,
                        child: task.status == FileUploadStatus.processing
                            ? LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: colors.borderSubtle,
                                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                              )
                            : Stack(
                                children: [
                                  Container(
                                    height: 4,
                                    color: colors.borderSubtle,
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: task.status == FileUploadStatus.done
                                        ? 1.0
                                        : task.progress,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: task.status == FileUploadStatus.error
                                              ? [colors.error, colors.error]
                                              : task.status == FileUploadStatus.done
                                                  ? [colors.success, AppColors.auroraTeal]
                                                  : [colors.primary, AppColors.auroraViolet],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildStatusBadge(FileUploadTask task, AppThemeColors colors) {
    switch (task.status) {
      case FileUploadStatus.uploading:
        return const AppBadge(label: 'Uploading...', variant: AppBadgeVariant.neutral);
      case FileUploadStatus.processing:
        return const AppBadge(label: 'Indexing...', variant: AppBadgeVariant.brand);
      case FileUploadStatus.done:
        return const AppBadge(label: 'Indexed', variant: AppBadgeVariant.success);
      case FileUploadStatus.error:
        return const AppBadge(label: 'Failed', variant: AppBadgeVariant.error);
    }
  }

  /// Document Card with glassmorphism styling
  Widget _buildDocumentCard(DocumentItem doc, AppThemeColors colors, bool isDark) {
    return InkWell(
      onTap: () => _openDocument(doc),
      borderRadius: AppRadius.borderR16,
      child: AppCard(
        useGlass: isDark,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s10),
        child: Row(
          children: [
            _buildFileIcon(doc.filename, colors, size: 20),
            AppSpacing.hGap10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    doc.filename,
                    style: AppTextStyles.bodyMedium(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vGap4,
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        _formatDate(doc.uploadedAt),
                        style: AppTextStyles.caption(color: colors.textSecondary),
                      ),
                      Text('•', style: AppTextStyles.caption(color: colors.textMuted)),
                      Text(
                        '${doc.chunkCount} chunks',
                        style: AppTextStyles.mono(color: colors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16),
              color: colors.textMuted,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _handleDelete(doc),
            ),
          ],
        ),
      ),
    );
  }

  /// Differentiates PDF, DOCX, and TXT icons with gradient containers
  Widget _buildFileIcon(String filename, AppThemeColors colors, {double size = 20}) {
    final ext = filename.split('.').last.toLowerCase();

    List<Color> gradientColors;
    IconData icon;

    switch (ext) {
      case 'pdf':
        gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
        icon = LucideIcons.fileText;
        break;
      case 'docx':
      case 'doc':
        gradientColors = [const Color(0xFF2563EB), const Color(0xFF3B82F6)];
        icon = LucideIcons.fileCode2;
        break;
      case 'txt':
      default:
        gradientColors = [colors.primary, AppColors.auroraViolet];
        icon = LucideIcons.fileText;
        break;
    }

    return Container(
      padding: AppSpacing.p10,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors.map((c) => c.withValues(alpha: 0.15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderR10,
        border: Border.all(
          color: gradientColors.first.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(icon, size: size, color: gradientColors.first),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
