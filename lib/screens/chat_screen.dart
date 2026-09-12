import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiClient _apiClient = const ApiClient();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? promptText]) async {
    final text = promptText ?? _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final sessionProvider = context.read<SessionProvider>();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    sessionProvider.addChatMessage(userMsg);
    setState(() {
      _isSending = true;
    });
    _textController.clear();
    _scrollToBottom();

    final response = await _apiClient.sendChatQuery(
      query: text,
      sessionId: sessionProvider.sessionId,
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final rawCitations = (data['citations'] as List<dynamic>?) ?? [];
      final citations = rawCitations
          .map((c) => Citation.fromJson(c as Map<String, dynamic>))
          .toList();

      sessionProvider.addChatMessage(ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: data['answer'] as String? ?? 'No response received.',
        isUser: false,
        timestamp: DateTime.now(),
        source: data['source'] as String? ?? 'knowledge_base',
        citations: citations,
      ));
    } else {
      sessionProvider.addChatMessage(ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: response.error ?? 'Unable to connect to server. Please verify your backend connection in Settings.',
        isUser: false,
        timestamp: DateTime.now(),
        source: 'error',
      ));
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionProvider = context.watch<SessionProvider>();
    final messages = sessionProvider.chatMessages;

    return Column(
      children: [
        // Message List Area
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState(colors, isDark)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s12,
                  ),
                  itemCount: messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isSending) {
                      return const TypingIndicator(
                        message: 'Searching documents & thinking...',
                      );
                    }
                    final msg = messages[index];
                    return ChatBubble(message: msg);
                  },
                ),
        ),

        // Glassmorphism Bottom Input Bar
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isDark ? 24 : 12,
              sigmaY: isDark ? 24 : 12,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s10),
              decoration: BoxDecoration(
                color: isDark
                    ? colors.background.withValues(alpha: 0.6)
                    : colors.background.withValues(alpha: 0.85),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.borderSubtle,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _textController,
                        hintText: 'Ask anything about your documents...',
                        prefixIcon: LucideIcons.messageSquare,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    AppSpacing.hGap8,
                    // Send button
                    AppButton(
                      text: 'Send',
                      leadingIcon: LucideIcons.send,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      isLoading: _isSending,
                      onPressed: () => _sendMessage(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors colors, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32, vertical: AppSpacing.s48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated sparkle icon with gradient glow
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.auroraViolet.withValues(alpha: isDark ? 0.2 : 0.1),
                    colors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.borderR20,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                  width: 1.0,
                ),
                boxShadow: isDark
                    ? AppShadows.neonGlow(colors.primary, intensity: 0.12, blur: 16)
                    : null,
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: 28,
                color: colors.primary,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 2500.ms, curve: Curves.easeInOut),
            AppSpacing.vGap20,
            Text(
              'How can I help you today?',
              style: AppTextStyles.headingMedium(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap8,
            Text(
              'Ask any question grounded in your uploaded documents.\nResponses include verifiable citations and insights.',
              style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}
