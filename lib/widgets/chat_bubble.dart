import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/chat_message.dart';
import '../theme/theme.dart';
import 'app_badge.dart';
import 'animated_audio_bars.dart';

/// Premium SaaS chat bubble with gradient user messages, glassmorphism bot cards,
/// animated citations, and inline audio waveform visualization.
class ChatBubble extends StatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onPlayAudio,
    this.onStopAudio,
    this.isAudioPlaying = false,
  });

  final ChatMessage message;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onStopAudio;
  final bool isAudioPlaying;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isCitationsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final msg = widget.message;

    // Distinct Visual Style for Refused Queries (centered warning card)
    if (msg.source == 'refused') {
      return _buildRefusedBubble(msg, colors);
    }

    if (msg.isUser) {
      return _buildUserBubble(msg, colors);
    } else {
      return _buildBotBubble(msg, colors);
    }
  }

  /// 1. User Message: Gradient-filled, right-aligned with neon glow
  Widget _buildUserBubble(ChatMessage msg, AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.userBubbleGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.r16),
                        topRight: Radius.circular(AppRadius.r16),
                        bottomLeft: Radius.circular(AppRadius.r16),
                        bottomRight: Radius.circular(AppRadius.r4),
                      ),
                      boxShadow: AppShadows.neonGlow(
                        AppColors.primary500,
                        intensity: 0.2,
                        blur: 16,
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: AppTextStyles.bodyMedium(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  AppSpacing.vGap4,
                  Text(
                    _formatTime(msg.timestamp),
                    style: AppTextStyles.caption(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms, curve: Curves.easeOut)
        .slideX(begin: 0.05, end: 0, duration: 200.ms, curve: Curves.easeOutCubic);
  }

  /// 2. Bot Message: Glassmorphism card with animated avatar
  Widget _buildBotBubble(ChatMessage msg, AppThemeColors colors) {
    final isKnowledgeBase = msg.source == 'knowledge_base';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Avatar with gradient background
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isKnowledgeBase
                    ? [AppColors.auroraViolet, AppColors.primary500]
                    : [colors.surfaceElevated, colors.surfaceSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.borderR10,
              boxShadow: isKnowledgeBase
                  ? AppShadows.neonGlow(AppColors.auroraViolet, intensity: 0.15, blur: 8)
                  : null,
            ),
            child: Icon(
              isKnowledgeBase ? LucideIcons.sparkles : LucideIcons.bot,
              size: 16,
              color: isKnowledgeBase ? Colors.white : colors.textSecondary,
            ),
          ),
          AppSpacing.hGap10,

          // Bubble Content Column
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge based on source
                if (isKnowledgeBase) ...[
                  const AppBadge(
                    label: 'From your documents',
                    variant: AppBadgeVariant.brand,
                    showDot: true,
                  ),
                  AppSpacing.vGap6,
                ] else if (msg.source == 'llm_general') ...[
                  const AppBadge(
                    label: 'General knowledge',
                    variant: AppBadgeVariant.warning,
                    showDot: true,
                  ),
                  AppSpacing.vGap6,
                ],

                // Glassmorphism Card Container with Markdown Body
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.r4),
                    topRight: Radius.circular(AppRadius.r16),
                    bottomLeft: Radius.circular(AppRadius.r16),
                    bottomRight: Radius.circular(AppRadius.r16),
                  ),
                  child: BackdropFilter(
                    filter: isDark
                        ? ImageFilter.blur(sigmaX: 16, sigmaY: 16)
                        : ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : colors.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.r4),
                          topRight: Radius.circular(AppRadius.r16),
                          bottomLeft: Radius.circular(AppRadius.r16),
                          bottomRight: Radius.circular(AppRadius.r16),
                        ),
                        border: Border.all(
                          color: isDark
                              ? colors.glassBorder
                              : colors.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: MarkdownBody(
                        data: msg.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: AppTextStyles.bodyMedium(color: colors.textPrimary),
                          strong: AppTextStyles.bodyMedium(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          em: AppTextStyles.bodyMedium(
                            color: colors.textPrimary,
                          ).copyWith(fontStyle: FontStyle.italic),
                          listBullet: AppTextStyles.bodyMedium(color: colors.primary),
                          code: AppTextStyles.mono(color: colors.primary),
                          codeblockDecoration: BoxDecoration(
                            color: colors.surfaceSecondary,
                            borderRadius: AppRadius.borderR8,
                            border: Border.all(color: colors.borderSubtle, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Expandable Citations Accordion for Knowledge Base Responses
                if (isKnowledgeBase && msg.citations.isNotEmpty) ...[
                  AppSpacing.vGap6,
                  _buildCitationsAccordion(msg.citations, colors),
                ],

                // Audio Playback Bar with animated waveform
                if (msg.audioBase64 != null && widget.onPlayAudio != null) ...[
                  AppSpacing.vGap6,
                  GestureDetector(
                    onTap: widget.isAudioPlaying ? widget.onStopAudio : widget.onPlayAudio,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s8),
                      decoration: BoxDecoration(
                        gradient: widget.isAudioPlaying
                            ? LinearGradient(
                                colors: [
                                  colors.primary.withValues(alpha: 0.15),
                                  AppColors.auroraViolet.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                        color: widget.isAudioPlaying ? null : colors.surfaceSecondary,
                        borderRadius: AppRadius.borderR10,
                        border: Border.all(
                          color: widget.isAudioPlaying
                              ? colors.primary.withValues(alpha: 0.4)
                              : colors.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isAudioPlaying ? LucideIcons.square : LucideIcons.volume2,
                            size: 14,
                            color: widget.isAudioPlaying ? colors.primary : colors.textPrimary,
                          ),
                          AppSpacing.hGap6,
                          if (widget.isAudioPlaying)
                            SizedBox(
                              width: 60,
                              height: 16,
                              child: AnimatedAudioBars(
                                barCount: 12,
                                barWidth: 2,
                                maxBarHeight: 14,
                                minBarHeight: 3,
                                gradientColors: [colors.primary, AppColors.auroraViolet],
                                isActive: true,
                                speed: 1.2,
                              ),
                            )
                          else
                            Text(
                              'Replay Audio',
                              style: AppTextStyles.caption(
                                color: colors.textPrimary,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                AppSpacing.vGap4,
                Text(
                  _formatTime(msg.timestamp),
                  style: AppTextStyles.caption(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  )
      .animate()
        .fadeIn(duration: 200.ms, curve: Curves.easeOut)
        .slideX(begin: -0.05, end: 0, duration: 200.ms, curve: Curves.easeOutCubic);
  }

  /// 3. Refused Query: Animated warning card with pulse border
  Widget _buildRefusedBubble(ChatMessage msg, AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12, horizontal: AppSpacing.s16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s10),
          decoration: BoxDecoration(
            color: colors.warningContainer.withValues(alpha: 0.5),
            borderRadius: AppRadius.borderR12,
            border: Border.all(
              color: colors.warning.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: AppSpacing.p6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.warning.withValues(alpha: 0.2),
                      colors.warning.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.shieldAlert, size: 16, color: colors.warning),
              ),
              AppSpacing.hGap10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Query Refused',
                          style: AppTextStyles.label(color: colors.warning),
                        ),
                        Text(
                          _formatTime(msg.timestamp),
                          style: AppTextStyles.caption(color: colors.warning.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                    AppSpacing.vGap4,
                    Text(
                      msg.text,
                      style: AppTextStyles.bodySmall(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 250.ms, curve: Curves.easeOutCubic);
  }

  /// Expandable Citations Section with gradient accents
  Widget _buildCitationsAccordion(List<Citation> citations, AppThemeColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : colors.surfaceSecondary,
        borderRadius: AppRadius.borderR10,
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header toggle bar
          GestureDetector(
            onTap: () => setState(() => _isCitationsExpanded = !_isCitationsExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s8),
              child: Row(
                children: [
                  Icon(LucideIcons.fileText, size: 14, color: colors.primary),
                  AppSpacing.hGap6,
                  Expanded(
                    child: Text(
                      '${citations.length} Verified Citation${citations.length > 1 ? 's' : ''}',
                      style: AppTextStyles.caption(color: colors.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isCitationsExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(LucideIcons.chevronDown, size: 14, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Animated expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s10, right: AppSpacing.s10, bottom: AppSpacing.s8),
              child: Column(
                children: citations.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(top: AppSpacing.s6),
                    padding: AppSpacing.p8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : colors.surface,
                      borderRadius: AppRadius.borderR8,
                      border: Border.all(color: colors.borderSubtle, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                c.filename,
                                style: AppTextStyles.caption(color: colors.primary).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppSpacing.hGap6,
                            Text(
                              'Score: ${c.score.toStringAsFixed(3)}',
                              style: AppTextStyles.mono(color: colors.textMuted).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        AppSpacing.vGap4,
                        Text(
                          c.chunkText,
                          style: AppTextStyles.caption(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: _isCitationsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
