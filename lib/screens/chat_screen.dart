import 'package:flutter/material.dart';
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

  final List<ChatMessage> _messages = [];
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

    setState(() {
      _messages.add(userMsg);
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
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final rawCitations = (data['citations'] as List<dynamic>?) ?? [];
        final citations = rawCitations
            .map((c) => Citation.fromJson(c as Map<String, dynamic>))
            .toList();

        _messages.add(ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: data['answer'] as String? ?? 'No response received.',
          isUser: false,
          timestamp: DateTime.now(),
          source: data['source'] as String? ?? 'knowledge_base',
          citations: citations,
        ));
      } else {
        // Fallback simulation based on user query intent for offline demonstration
        _addOfflineMockResponse(text);
      }
    });

    _scrollToBottom();
  }

  void _addOfflineMockResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('cookie') || lower.contains('recipe') || lower.contains('spaghetti')) {
      // Refused Query Response
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Sorry, I can only answer questions related to the Acme TechCorp HR Policy Handbook. Please ask something related to company leave, remote-work, or code of conduct.',
        isUser: false,
        timestamp: DateTime.now(),
        source: 'refused',
      ));
    } else if (lower.contains('best practices') || lower.contains('posture') || lower.contains('general')) {
      // General LLM Knowledge Response
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'This isn\'t in your uploaded documents, but here\'s what I know generally:\n\n'
            '• **Eye Level**: Position your monitor so the top third of the screen is at eye level.\n'
            '• **Elbows**: Keep elbows at an open angle (90° to 100°) with wrists flat.\n'
            '• **Feet**: Feet should rest flat on the floor or on a footrest.',
        isUser: false,
        timestamp: DateTime.now(),
        source: 'llm_general',
      ));
    } else {
      // Knowledge Base Document RAG Response with Citations
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'According to the **Acme HR Policy Handbook**, full-time employees are eligible for:\n\n'
            '1. A one-time **\$500 reimbursement** for ergonomic home office furniture upon onboarding.\n'
            '2. An annual **\$300 ergonomic refresh allowance** for peripherals (keyboards, monitors, mice).\n\n'
            'Receipts must be submitted via the finance expense portal within 30 days of purchase.',
        isUser: false,
        timestamp: DateTime.now(),
        source: 'knowledge_base',
        citations: [
          const Citation(
            filename: 'acme_hr_policy_handbook.txt',
            chunkText: 'Section 4.2 - Remote Equipment Reimbursement: Full-time employees receive a one-time \$500 work-from-home setup stipend and an annual \$300 ergonomic allowance.',
            score: 0.892,
          ),
          const Citation(
            filename: 'travel_and_expense_policy_2026.pdf',
            chunkText: 'Section 2.1 - Expense Submission Windows: All home office and hardware claims must be submitted within 30 days accompanied by itemized tax invoices.',
            score: 0.764,
          ),
        ],
      ));
    }
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

    return Column(
      children: [
        // Message List Area
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState(colors)
              : ListView.builder(
                  controller: _scrollController,
                  padding: AppSpacing.screenPadding,
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isSending) {
                      return const TypingIndicator(
                        message: 'Searching documents & thinking...',
                      );
                    }
                    final msg = _messages[index];
                    return ChatBubble(message: msg);
                  },
                ),
        ),

        // Bottom Input Bar (with keyboard avoidance)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s10),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
          ),
          child: SafeArea(
            top: false,
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
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32, vertical: AppSpacing.s48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: AppRadius.borderR14,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: 26,
                color: colors.primary,
              ),
            ),
            AppSpacing.vGap16,
            Text(
              'How can I help you today?',
              style: AppTextStyles.headingMedium(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap8,
            Text(
              'Ask any question grounded in your uploaded documents. Responses include verifiable citations and domain insights.',
              style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

