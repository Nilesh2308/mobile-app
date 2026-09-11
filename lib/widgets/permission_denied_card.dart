import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/theme.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Styled SaaS permission notice displayed when microphone access is denied.
class PermissionDeniedCard extends StatelessWidget {
  const PermissionDeniedCard({
    super.key,
    required this.onRequestPermission,
  });

  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: AppSpacing.p8,
                decoration: BoxDecoration(
                  color: colors.warningContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.micOff, size: 20, color: colors.warning),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Microphone Permission Required',
                      style: AppTextStyles.headingSmall(color: colors.textPrimary),
                    ),
                    AppSpacing.vGap2,
                    Text(
                      'Voice AI needs microphone access to record queries.',
                      style: AppTextStyles.caption(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGap16,
          Text(
            'To converse with the Voice Assistant, please grant microphone permissions in your device settings.',
            style: AppTextStyles.bodySmall(color: colors.textSecondary),
          ),
          AppSpacing.vGap16,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Open App Settings',
                  leadingIcon: LucideIcons.settings,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  onPressed: () async {
                    await openAppSettings();
                  },
                ),
              ),
              AppSpacing.hGap8,
              AppButton(
                text: 'Try Again',
                leadingIcon: LucideIcons.refreshCw,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                onPressed: onRequestPermission,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
