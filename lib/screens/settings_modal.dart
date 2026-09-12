import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_client.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsModal(),
    );
  }

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  late final TextEditingController _urlController;
  final ApiClient _apiClient = const ApiClient();
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    await AppConfig.setBaseUrl(_urlController.text);
    const client = ApiClient();
    final health = await client.checkHealth();

    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _isSuccess = health.isSuccess;
      _testResult = health.isSuccess
          ? 'Connected successfully! Models ready.'
          : health.error ?? 'Connection failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final sessionProvider = context.watch<SessionProvider>();
    final isDark = themeProvider.isDarkMode;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 32 : 16,
          sigmaY: isDark ? 32 : 16,
        ),
        child: Container(
          padding: EdgeInsets.only(
            left: AppSpacing.s20,
            right: AppSpacing.s20,
            top: AppSpacing.s16,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? colors.background.withValues(alpha: 0.75)
                : colors.background.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? colors.primary.withValues(alpha: 0.15)
                    : colors.borderSubtle,
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar with gradient
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.4),
                          AppColors.auroraViolet.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: AppRadius.borderRFull,
                    ),
                  ),
                ),
                AppSpacing.vGap16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('App Settings & Network', style: AppTextStyles.headingSmall(color: colors.textPrimary)),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      color: colors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                AppSpacing.vGap16,

                // Theme Toggle Option
                _buildSettingsCard(
                  colors: colors,
                  isDark: isDark,
                  icon: themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                  title: 'Theme Mode',
                  subtitle: themeProvider.isDarkMode ? 'Dark Mode active' : 'Light Mode active',
                  action: AppButton(
                    text: themeProvider.isDarkMode ? 'To Light' : 'To Dark',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ),
                AppSpacing.vGap16,

                // Clear Conversation History
                _buildSettingsCard(
                  colors: colors,
                  isDark: isDark,
                  icon: LucideIcons.messageSquare,
                  title: 'Conversation History',
                  subtitle: 'Clear current chat context',
                  action: AppButton(
                    text: _isClearing ? 'Clearing...' : 'Clear',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.outline,
                    leadingIcon: LucideIcons.trash2,
                    isLoading: _isClearing,
                    onPressed: _isClearing ? null : () async {
                      setState(() => _isClearing = true);
                      try {
                        final currentSessionId = sessionProvider.sessionId;
                        if (currentSessionId.isNotEmpty) {
                          await _apiClient.resetSession(currentSessionId);
                        }
                        await _apiClient.clearAllChats();
                        await sessionProvider.resetSession();
                        await Future.delayed(const Duration(milliseconds: 600));
                      } catch (_) {
                        // ignore error
                      }
                      if (!context.mounted) return;
                      setState(() => _isClearing = false);
                      Navigator.of(context).pop();
                      AppToast.show(
                        context,
                        title: 'Chat Cleared',
                        message: 'Permanently deleted chat history from database.',
                        variant: AppToastVariant.success,
                      );
                    },
                  ),
                ),
                AppSpacing.vGap16,

                // Backend Endpoint Configuration
                AppCard(
                  useGlass: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FastAPI Backend URL', style: AppTextStyles.label(color: colors.textPrimary)),
                      AppSpacing.vGap6,
                      Text(
                        'When testing on a physical phone, set to your computer\'s Wi-Fi IP (e.g. http://192.168.x.x:8000).',
                        style: AppTextStyles.caption(color: colors.textSecondary),
                      ),
                      AppSpacing.vGap12,
                      AppTextField(
                        controller: _urlController,
                        hintText: 'http://192.168.1.100:8000',
                        prefixIcon: LucideIcons.globe,
                      ),
                      if (_testResult != null) ...[
                        AppSpacing.vGap8,
                        Container(
                          padding: AppSpacing.p8,
                          decoration: BoxDecoration(
                            color: _isSuccess
                                ? colors.success.withValues(alpha: 0.1)
                                : colors.error.withValues(alpha: 0.1),
                            borderRadius: AppRadius.borderR8,
                            border: Border.all(
                              color: _isSuccess ? colors.success.withValues(alpha: 0.3) : colors.error.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isSuccess ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                                size: 14,
                                color: _isSuccess ? colors.success : colors.error,
                              ),
                              AppSpacing.hGap8,
                              Expanded(
                                child: Text(
                                  _testResult!,
                                  style: AppTextStyles.caption(color: _isSuccess ? colors.success : colors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      AppSpacing.vGap12,
                      Row(
                        children: [
                          AppButton(
                            text: 'Test & Save',
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.primary,
                            leadingIcon: LucideIcons.radio,
                            isLoading: _isTesting,
                            onPressed: _testConnection,
                          ),
                          AppSpacing.hGap8,
                          AppButton(
                            text: 'Reset Default',
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.ghost,
                            onPressed: () async {
                              await AppConfig.resetToDefault();
                              _urlController.text = AppConfig.baseUrl;
                              setState(() => _testResult = null);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGap16,

              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Consistent settings card with gradient icon container
  Widget _buildSettingsCard({
    required AppThemeColors colors,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget action,
  }) {
    return AppCard(
      useGlass: isDark,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.2),
                        AppColors.auroraViolet.withValues(alpha: 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppRadius.borderR10,
                  ),
                  child: Icon(icon, size: 16, color: colors.primary),
                ),
                AppSpacing.hGap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium(color: colors.textPrimary, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption(color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGap12,
          action,
        ],
      ),
    );
  }
}
