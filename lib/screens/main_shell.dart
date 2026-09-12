import 'dart:ui';
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
      label: 'Knowledge',
      icon: LucideIcons.bookOpen,
    ),
    _NavItem(
      label: 'Chat',
      icon: LucideIcons.messageSquare,
    ),
    _NavItem(
      label: 'Voice',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGradientBg(
      intensity: 0.8,
      child: Scaffold(
        extendBody: false,
        extendBodyBehindAppBar: false,
        backgroundColor: Colors.transparent,
        appBar: AppTopBar(
          title: _currentTitle,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.2),
                  AppColors.auroraViolet.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : colors.surfaceSecondary,
                  borderRadius: AppRadius.borderR8,
                  border: Border.all(
                    color: isDark ? colors.glassBorder : colors.borderSubtle,
                    width: 1,
                  ),
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
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : colors.surfaceSecondary,
                  borderRadius: AppRadius.borderR8,
                  border: Border.all(
                    color: isDark ? colors.glassBorder : colors.borderSubtle,
                    width: 1,
                  ),
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
        bottomNavigationBar: _buildGlassBottomNav(colors, isDark),
      ),
    );
  }

  /// Glassmorphism bottom navigation bar with frosted blur, active glow indicator
  Widget _buildGlassBottomNav(AppThemeColors colors, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? colors.background.withValues(alpha: 0.75)
                : colors.background.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? colors.primary.withValues(alpha: 0.15)
                    : colors.borderSubtle,
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Padding(
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
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    colors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                                    AppColors.auroraViolet.withValues(alpha: isDark ? 0.10 : 0.06),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                          borderRadius: AppRadius.borderR14,
                          border: isSelected
                              ? Border.all(
                                  color: colors.primary.withValues(alpha: 0.3),
                                  width: 1.2,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Neon dot indicator
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: isSelected ? 4 : 0,
                              height: isSelected ? 4 : 0,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colors.primary.withValues(alpha: 0.7),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            AnimatedScale(
                              scale: isSelected ? 1.08 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                item.icon,
                                size: 21,
                                color: isSelected ? colors.primary : colors.textMuted,
                              ),
                            ),
                            AppSpacing.vGap4,
                            Text(
                              item.label,
                              style: AppTextStyles.caption(
                                color: isSelected ? colors.primary : colors.textMuted,
                              ).copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 11,
                                height: 1.2,
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
