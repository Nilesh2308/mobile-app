import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  bool _isTestingLoading = false;
  bool _showEmptyState = false;
  bool _showErrorState = false;
  final TextEditingController _queryController = TextEditingController();

  final List<String> _tabs = const ['Overview', 'Sessions', 'Documents', 'Design Kit'];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final themeController = AppThemeScope.of(context);
    final isDark = themeController.isDarkMode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppTopBar(
        title: 'VoiceAI Studio',
        subtitle: 'v1.4.0 • Enterprise Edge',
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: AppRadius.borderR8,
            border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(
            LucideIcons.radio,
            size: 18,
            color: colors.primary,
          ),
        ),
        actions: [
          // Theme Toggle Button
          GestureDetector(
            onTap: () => themeController.toggleTheme(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: AppRadius.borderR8,
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: Icon(
                isDark ? LucideIcons.sun : LucideIcons.moon,
                size: 16,
                color: colors.textPrimary,
              ),
            ),
          ),
          AppSpacing.hGap8,
          // Quick Status Pill
          const AppBadge(
            label: 'Ready',
            variant: AppBadgeVariant.success,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-navigation Tabs
          _buildTabBar(colors),
          // Tab Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildCurrentTab(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : colors.surfaceSecondary,
                    borderRadius: AppRadius.borderR8,
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _tabs[index],
                    style: AppTextStyles.label(
                      color: isSelected ? colors.onPrimary : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(AppThemeColors colors) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(colors);
      case 1:
        return _buildSessionsTab(colors);
      case 2:
        return _buildDocumentsTab(colors);
      case 3:
      default:
        return _buildDesignKitTab(colors);
    }
  }

  Widget _buildOverviewTab(AppThemeColors colors) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        AppSpacing.vGap8,
        // Active Status Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: AppSpacing.p8,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: AppRadius.borderR8,
                        ),
                        child: Icon(LucideIcons.cpu, size: 16, color: colors.primary),
                      ),
                      AppSpacing.hGap12,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hybrid Edge Architecture', style: AppTextStyles.headingSmall(color: colors.textPrimary)),
                          Text('Local Audio + Cloud Groq LLM', style: AppTextStyles.caption(color: colors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const AppBadge(label: 'Healthy', variant: AppBadgeVariant.success),
                ],
              ),
              AppSpacing.vGap16,
              Divider(color: colors.borderSubtle),
              AppSpacing.vGap16,
              // Model Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'STT Engine',
                      value: 'Whisper-med',
                      status: 'Local GPU',
                      colors: colors,
                    ),
                  ),
                  AppSpacing.hGap12,
                  Expanded(
                    child: _buildMetricTile(
                      label: 'TTS Synthesis',
                      value: 'Kokoro v1',
                      status: '124ms RTF',
                      colors: colors,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGap12,
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'LLM Model',
                      value: 'Llama-3.3-70b',
                      status: 'Groq Cloud',
                      colors: colors,
                    ),
                  ),
                  AppSpacing.hGap12,
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Vector DB',
                      value: 'Qdrant (Local)',
                      status: '384d BGE',
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.vGap16,

        // Quick Query Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Interactive RAG Prompt', style: AppTextStyles.headingSmall(color: colors.textPrimary)),
              AppSpacing.vGap4,
              Text(
                'Ask questions verified against ingested policy documents with citations.',
                style: AppTextStyles.bodySmall(color: colors.textSecondary),
              ),
              AppSpacing.vGap16,
              AppTextField(
                controller: _queryController,
                hintText: 'e.g. What is the remote work equipment stipend?',
                prefixIcon: LucideIcons.search,
                showClearButton: true,
              ),
              AppSpacing.vGap12,
              Row(
                children: [
                  AppButton(
                    text: 'Record Voice',
                    leadingIcon: LucideIcons.mic,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.md,
                    onPressed: () {},
                  ),
                  AppSpacing.hGap8,
                  Expanded(
                    child: AppButton(
                      text: 'Send Query',
                      leadingIcon: LucideIcons.send,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.vGap16,

        // Recent Inferred Turn Preview
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.messageSquare, size: 16, color: colors.textSecondary),
                      AppSpacing.hGap8,
                      Text('Latest Verified Response', style: AppTextStyles.label(color: colors.textPrimary)),
                    ],
                  ),
                  Text('12s ago', style: AppTextStyles.caption(color: colors.textMuted)),
                ],
              ),
              AppSpacing.vGap12,
              Text(
                '"Full-time employees receive a one-time \$500 work-from-home setup reimbursement upon joining, and an annual \$300 ergonomic refresh allowance."',
                style: AppTextStyles.bodyMedium(color: colors.textPrimary),
              ),
              AppSpacing.vGap12,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: AppRadius.borderR8,
                  border: Border.all(color: colors.borderSubtle, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.fileText, size: 14, color: colors.primary),
                    AppSpacing.hGap8,
                    Expanded(
                      child: Text(
                        'acme_hr_policy_handbook.txt • Score: 0.892',
                        style: AppTextStyles.mono(color: colors.textSecondary),
                      ),
                    ),
                    const AppBadge(label: 'Verified RAG', variant: AppBadgeVariant.brand, showDot: false),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGap24,
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String status,
    required AppThemeColors colors,
  }) {
    return Container(
      padding: AppSpacing.p12,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: AppRadius.borderR8,
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption(color: colors.textMuted)),
          AppSpacing.vGap4,
          Text(value, style: AppTextStyles.bodyMedium(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          AppSpacing.vGap2,
          Text(status, style: AppTextStyles.mono(color: colors.primary)),
        ],
      ),
    );
  }

  Widget _buildSessionsTab(AppThemeColors colors) {
    if (_showEmptyState) {
      return AppEmptyState(
        title: 'No active chat sessions',
        description: 'Start a new text or voice conversation to query your localized knowledge base.',
        icon: LucideIcons.messageSquare,
        actionText: 'Start Session',
        actionLeadingIcon: LucideIcons.plus,
        onActionPressed: () => setState(() => _showEmptyState = false),
      );
    }

    if (_showErrorState) {
      return AppErrorState(
        title: 'Failed to sync sessions',
        message: 'Unable to reach the in-memory session store at localhost:8000. Verify the FastAPI backend is running.',
        onRetry: () => setState(() => _showErrorState = false),
        secondaryActionText: 'Show Empty',
        onSecondaryAction: () => setState(() {
          _showErrorState = false;
          _showEmptyState = true;
        }),
      );
    }

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Conversations', style: AppTextStyles.headingSmall(color: colors.textPrimary)),
            Row(
              children: [
                AppButton(
                  text: 'Simulate Empty',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => setState(() => _showEmptyState = true),
                ),
                AppSpacing.hGap4,
                AppButton(
                  text: 'Simulate Error',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => setState(() => _showErrorState = true),
                ),
              ],
            ),
          ],
        ),
        AppSpacing.vGap16,
        _buildSessionCard(
          title: 'Leave & PTO Entitlement Query',
          time: '10m ago',
          turns: '4 turns',
          snippet: 'Can I carry forward unused annual leave into the next fiscal year?',
          colors: colors,
        ),
        AppSpacing.vGap12,
        _buildSessionCard(
          title: 'Remote Equipment Reimbursement',
          time: '1h ago',
          turns: '2 turns',
          snippet: 'How do I submit an expense claim for the home office monitor?',
          colors: colors,
        ),
        AppSpacing.vGap12,
        _buildSessionCard(
          title: 'IT & Data Security Guidelines',
          time: 'Yesterday',
          turns: '7 turns',
          snippet: 'What are the two-factor authentication requirements for BYOD devices?',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildSessionCard({
    required String title,
    required String time,
    required String turns,
    required String snippet,
    required AppThemeColors colors,
  }) {
    return AppCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium(color: colors.textPrimary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.hGap8,
              AppBadge(label: turns, variant: AppBadgeVariant.neutral, showDot: false),
            ],
          ),
          AppSpacing.vGap8,
          Text(
            snippet,
            style: AppTextStyles.bodySmall(color: colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          AppSpacing.vGap12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time, style: AppTextStyles.caption(color: colors.textMuted)),
              Icon(LucideIcons.chevronRight, size: 14, color: colors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(AppThemeColors colors) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Knowledge Base Ingestion', style: AppTextStyles.headingSmall(color: colors.textPrimary)),
                  const AppBadge(label: 'Qdrant DB', variant: AppBadgeVariant.brand),
                ],
              ),
              AppSpacing.vGap8,
              Text(
                'Upload PDF, TXT, or DOCX documents to chunk and embed with BAAI/bge-small-en-v1.5.',
                style: AppTextStyles.bodySmall(color: colors.textSecondary),
              ),
              AppSpacing.vGap16,
              AppButton(
                text: 'Upload New Document',
                leadingIcon: LucideIcons.cloudUpload,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.md,
                isFullWidth: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
        AppSpacing.vGap16,
        Text('Indexed Knowledge Sources', style: AppTextStyles.label(color: colors.textSecondary)),
        AppSpacing.vGap12,
        _buildDocItem(
          name: 'acme_hr_policy_handbook.txt',
          size: '4.4 KB',
          chunks: '18 chunks',
          status: 'Indexed',
          colors: colors,
        ),
        AppSpacing.vGap12,
        _buildDocItem(
          name: 'travel_and_expense_policy_2026.pdf',
          size: '2.1 MB',
          chunks: '42 chunks',
          status: 'Indexed',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildDocItem({
    required String name,
    required String size,
    required String chunks,
    required String status,
    required AppThemeColors colors,
  }) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: AppSpacing.p12,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: AppRadius.borderR8,
            ),
            child: Icon(LucideIcons.fileText, size: 20, color: colors.primary),
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium(color: colors.textPrimary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.vGap2,
                Text('$size • $chunks', style: AppTextStyles.caption(color: colors.textSecondary)),
              ],
            ),
          ),
          const AppBadge(label: 'Active', variant: AppBadgeVariant.success),
        ],
      ),
    );
  }

  Widget _buildDesignKitTab(AppThemeColors colors) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Text('Design Tokens & Reusable Kit', style: AppTextStyles.headingSmall(color: colors.textPrimary)),
        AppSpacing.vGap4,
        Text(
          'Live interactive showcase of buttons, inputs, cards, badges, and states.',
          style: AppTextStyles.bodySmall(color: colors.textSecondary),
        ),
        AppSpacing.vGap16,

        // Buttons Section
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AppButton Variants', style: AppTextStyles.label(color: colors.textPrimary)),
              AppSpacing.vGap12,
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  AppButton(
                    text: 'Primary',
                    variant: AppButtonVariant.primary,
                    onPressed: () {},
                  ),
                  AppButton(
                    text: 'Secondary',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  AppButton(
                    text: 'Outline',
                    variant: AppButtonVariant.outline,
                    onPressed: () {},
                  ),
                  AppButton(
                    text: 'Ghost',
                    variant: AppButtonVariant.ghost,
                    onPressed: () {},
                  ),
                  AppButton(
                    text: 'Destructive',
                    variant: AppButtonVariant.destructive,
                    onPressed: () {},
                  ),
                ],
              ),
              AppSpacing.vGap16,
              Text('Button States & Sizes', style: AppTextStyles.label(color: colors.textPrimary)),
              AppSpacing.vGap12,
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  AppButton(
                    text: 'Small (32px)',
                    size: AppButtonSize.sm,
                    onPressed: () {},
                  ),
                  AppButton(
                    text: 'Medium (40px)',
                    size: AppButtonSize.md,
                    onPressed: () {},
                  ),
                  AppButton(
                    text: 'Large (48px)',
                    size: AppButtonSize.lg,
                    onPressed: () {},
                  ),
                  AppButton(
                    text: 'Disabled',
                    isDisabled: true,
                    onPressed: () {},
                  ),
                  AppButton(
                    text: 'Loading',
                    isLoading: _isTestingLoading,
                    onPressed: () {
                      setState(() => _isTestingLoading = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _isTestingLoading = false);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.vGap16,

        // Inputs Section
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AppTextField States', style: AppTextStyles.label(color: colors.textPrimary)),
              AppSpacing.vGap12,
              const AppTextField(
                label: 'Standard Input',
                hintText: 'Enter API key or endpoint...',
                prefixIcon: LucideIcons.key,
                helperText: 'Your Groq API key is stored securely in environment variables.',
              ),
              AppSpacing.vGap16,
              const AppTextField(
                label: 'Validation Error State',
                hintText: 'example@company.com',
                prefixIcon: LucideIcons.mail,
                errorText: 'Please provide a valid enterprise email domain.',
              ),
            ],
          ),
        ),
        AppSpacing.vGap16,

        // Badges Section
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AppBadge Variants', style: AppTextStyles.label(color: colors.textPrimary)),
              AppSpacing.vGap12,
              const Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  AppBadge(label: 'Brand Indigo', variant: AppBadgeVariant.brand),
                  AppBadge(label: 'Success Ready', variant: AppBadgeVariant.success),
                  AppBadge(label: 'Warning Degraded', variant: AppBadgeVariant.warning),
                  AppBadge(label: 'Error Failed', variant: AppBadgeVariant.error),
                  AppBadge(label: 'Neutral Draft', variant: AppBadgeVariant.neutral),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.vGap16,

        // Loading State Component Preview
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Designed Loading State (No bare indicators)', style: AppTextStyles.label(color: colors.textPrimary)),
              AppSpacing.vGap12,
              const AppLoadingState(
                message: 'Processing voice pipeline...',
                subMessage: 'Transcribing 16kHz audio using faster-whisper',
              ),
              AppSpacing.vGap16,
              Text('Shimmer Skeleton Placeholders', style: AppTextStyles.caption(color: colors.textMuted)),
              AppSpacing.vGap8,
              const AppSkeleton(width: double.infinity, height: 18),
              AppSpacing.vGap8,
              const AppSkeleton(width: 220, height: 14),
            ],
          ),
        ),
        AppSpacing.vGap24,
      ],
    );
  }
}
