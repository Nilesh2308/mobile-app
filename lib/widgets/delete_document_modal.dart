import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/document_item.dart';
import '../theme/theme.dart';
import 'app_button.dart';

/// Styled bottom sheet for confirming document deletion.
/// Avoids default Material AlertDialog look.
class DeleteDocumentModal extends StatefulWidget {
  const DeleteDocumentModal({
    super.key,
    required this.document,
    required this.onConfirmDelete,
  });

  final DocumentItem document;
  final Future<bool> Function() onConfirmDelete;

  static Future<bool?> show({
    required BuildContext context,
    required DocumentItem document,
    required Future<bool> Function() onConfirmDelete,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DeleteDocumentModal(
        document: document,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  State<DeleteDocumentModal> createState() => _DeleteDocumentModalState();
}

class _DeleteDocumentModalState extends State<DeleteDocumentModal> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s20,
        right: AppSpacing.s20,
        top: AppSpacing.s16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
        boxShadow: AppShadows.card(isDark),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: AppRadius.borderRFull,
              ),
            ),
          ),
          AppSpacing.vGap20,

          // Warning Header
          Row(
            children: [
              Container(
                padding: AppSpacing.p10,
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: AppRadius.borderR12,
                  border: Border.all(color: colors.error.withValues(alpha: 0.3), width: 1),
                ),
                child: Icon(LucideIcons.alertTriangle, size: 20, color: colors.error),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Knowledge Document?',
                      style: AppTextStyles.headingSmall(color: colors.textPrimary),
                    ),
                    AppSpacing.vGap2,
                    Text(
                      'This action cannot be undone.',
                      style: AppTextStyles.caption(color: colors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGap16,

          // Target document details card
          Container(
            padding: AppSpacing.p12,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: AppRadius.borderR12,
              border: Border.all(color: colors.borderSubtle, width: 1),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.fileText, size: 20, color: colors.primary),
                AppSpacing.hGap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.document.filename,
                        style: AppTextStyles.bodyMedium(color: colors.textPrimary, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.vGap2,
                      Text(
                        '${widget.document.chunkCount} vector points will be removed from Qdrant',
                        style: AppTextStyles.caption(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGap16,
          Text(
            'Deleting this document removes all extracted text chunks and embeddings. The RAG pipeline will no longer cite this document.',
            style: AppTextStyles.bodySmall(color: colors.textSecondary),
          ),
          AppSpacing.vGap24,

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.md,
                  isDisabled: _isDeleting,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: AppButton(
                  text: 'Delete Document',
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.md,
                  isLoading: _isDeleting,
                  onPressed: () async {
                    setState(() => _isDeleting = true);
                    final navigator = Navigator.of(context);
                    final success = await widget.onConfirmDelete();
                    if (mounted) {
                      setState(() => _isDeleting = false);
                      navigator.pop(success);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}
