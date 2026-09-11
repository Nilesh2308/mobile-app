import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';
import 'knowledge_base_screen.dart';
import 'settings_modal.dart';
import 'voice_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1; // Default to Chat

  final List<Widget> _screens = const [
    KnowledgeBaseScreen(),
    ChatScreen(),
    VoiceScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      label: 'Knowledge Base',
      icon: LucideIcons.bookOpen,
    ),
    _NavItem(
      label: 'Chat',
      icon: LucideIcons.messageSquare,
    ),
    _NavItem(
      label: 'Voice Assistant',
      icon: LucideIcons.mic,
    ),
  ];

  String get _currentTitle {
    switch (_currentIndex) {
      case 0:
        return 'Knowledge Base';
      case 1:
        return 'Chat';
      case 2:
      default:
        return 'Voice Assistant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppTopBar(
        title: _currentTitle,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: AppRadius.borderR8,
            border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(
            _navItems[_currentIndex].icon,
            size: 18,
            color: colors.primary,
          ),
        ),
        actions: [
          // Theme Toggle Button
          GestureDetector(
            onTap: () => themeProvider.toggleTheme(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: AppRadius.borderR8,
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: Icon(
                themeProvider.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                size: 16,
                color: colors.textPrimary,
              ),
            ),
          ),
          AppSpacing.hGap8,

          // Settings Modal
          GestureDetector(
            onTap: () => SettingsModal.show(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: AppRadius.borderR8,
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: Icon(
                LucideIcons.settings,
                size: 16,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildCustomBottomNav(colors),
    );
  }

  /// Custom SaaS bottom navigation bar replacing default Material look
  Widget _buildCustomBottomNav(AppThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primaryContainer : Colors.transparent,
                      borderRadius: AppRadius.borderR12,
                      border: isSelected
                          ? Border.all(color: colors.primary.withValues(alpha: 0.2), width: 1)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isSelected ? colors.primary : colors.textMuted,
                        ),
                        AppSpacing.vGap4,
                        Text(
                          item.label,
                          style: AppTextStyles.caption(
                            color: isSelected ? colors.primary : colors.textMuted,
                          ).copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
