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

  Map<String, dynamic>? _stats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConfig.baseUrl);
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final res = await _apiClient.getStats();
    if (!mounted) return;
    setState(() {
      _isLoadingStats = false;
      if (res.isSuccess && res.data != null) {
        _stats = res.data;
      } else {
        // Fallback default structure
        _stats = {
          'total_queries': 0,
          'sources': {
            'knowledge_base': 0,
            'llm_general': 0,
            'refused': 0,
          },
        };
      }
    });
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
        boxShadow: AppShadows.card(themeProvider.isDarkMode),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                        size: 18,
                        color: colors.primary,
                      ),
                      AppSpacing.hGap12,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme Mode', style: AppTextStyles.bodyMedium(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                          Text(themeProvider.isDarkMode ? 'Dark Mode active' : 'Light Mode active', style: AppTextStyles.caption(color: colors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  AppButton(
                    text: themeProvider.isDarkMode ? 'To Light' : 'To Dark',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
            ),
            AppSpacing.vGap16,

            // Clear Conversation History
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.messageSquare, size: 18, color: colors.primary),
                      AppSpacing.hGap12,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Conversation History', style: AppTextStyles.bodyMedium(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                          Text('Clear current chat context', style: AppTextStyles.caption(color: colors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  AppButton(
                    text: 'Clear',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.outline,
                    leadingIcon: LucideIcons.trash2,
                    onPressed: () async {
                      await sessionProvider.resetSession();
                      if (context.mounted) {
                        AppToast.show(
                          context,
                          title: 'History Cleared',
                          message: 'Started a fresh conversation.',
                          variant: AppToastVariant.info,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.vGap16,

            // Backend Endpoint Configuration
            AppCard(
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
                        color: _isSuccess ? colors.successContainer : colors.errorContainer,
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

            // Session Analytics Stats Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.barChart2, size: 16, color: colors.primary),
                          AppSpacing.hGap8,
                          Text('Session Stats', style: AppTextStyles.label(color: colors.textPrimary)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _loadStats,
                        child: Row(
                          children: [
                            if (_isLoadingStats)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(LucideIcons.refreshCw, size: 12, color: colors.textMuted),
                            AppSpacing.hGap4,
                            Text('Refresh', style: AppTextStyles.caption(color: colors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGap12,
                  if (_stats != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: AppSpacing.p10,
                            decoration: BoxDecoration(
                              color: colors.surfaceSecondary,
                              borderRadius: AppRadius.borderR8,
                              border: Border.all(color: colors.borderSubtle, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Queries Processed', style: AppTextStyles.caption(color: colors.textSecondary)),
                                AppSpacing.vGap2,
                                Text(
                                  '${_stats!['total_queries'] ?? 0}',
                                  style: AppTextStyles.headingMedium(color: colors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vGap8,
                    Row(
                      children: [
                        _buildStatPill(
                          label: 'From Documents',
                          count: (_stats!['sources'] as Map<String, dynamic>?)?['knowledge_base'] ?? 0,
                          badgeVariant: AppBadgeVariant.brand,
                          colors: colors,
                        ),
                        AppSpacing.hGap8,
                        _buildStatPill(
                          label: 'General',
                          count: (_stats!['sources'] as Map<String, dynamic>?)?['llm_general'] ?? 0,
                          badgeVariant: AppBadgeVariant.warning,
                          colors: colors,
                        ),
                        AppSpacing.hGap8,
                        _buildStatPill(
                          label: 'Refused',
                          count: (_stats!['sources'] as Map<String, dynamic>?)?['refused'] ?? 0,
                          badgeVariant: AppBadgeVariant.error,
                          colors: colors,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.vGap16,

            // Architectural / Backend Restart Notice Card
            Container(
              padding: AppSpacing.p12,
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: AppRadius.borderR10,
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 14, color: colors.textSecondary),
                  AppSpacing.hGap8,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversation history resets when the backend restarts (no database yet).',
                          style: AppTextStyles.caption(color: colors.textSecondary),
                        ),
                        AppSpacing.vGap4,
                        Text(
                          'Voice AI Studio • Local Edge Models',
                          style: AppTextStyles.mono(color: colors.textMuted).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required dynamic count,
    required AppBadgeVariant badgeVariant,
    required AppThemeColors colors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s6),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: AppRadius.borderR8,
          border: Border.all(color: colors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: AppTextStyles.label(color: colors.textPrimary).copyWith(fontWeight: FontWeight.w700),
            ),
            AppSpacing.vGap2,
            Text(
              label,
              style: AppTextStyles.caption(color: colors.textMuted).copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
