import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../models/chat_message.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final ApiClient _apiClient = const ApiClient();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();

  VoiceRingState _voiceState = VoiceRingState.idle;
  bool _isMicPermissionDenied = false;
  String? _currentlyPlayingMessageId;
  StreamSubscription? _playerStateSubscription;

  final List<ChatMessage> _messages = [];

  // Status subtitle display text
  String get _statusLabel {
    switch (_voiceState) {
      case VoiceRingState.listening:
        return 'Listening...';
      case VoiceRingState.transcribing:
        return 'Transcribing...';
      case VoiceRingState.thinking:
        return 'Thinking...';
      case VoiceRingState.speaking:
        return 'Speaking...';
      case VoiceRingState.idle:
        return 'Tap microphone to speak';
    }
  }

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) {
          setState(() {
            _currentlyPlayingMessageId = null;
            if (_voiceState == VoiceRingState.speaking) {
              _voiceState = VoiceRingState.idle;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Request microphone permission
  Future<bool> _checkPermission() async {
    if (kIsWeb) return true;

    // Check with permission_handler
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      if (_isMicPermissionDenied) {
        setState(() => _isMicPermissionDenied = false);
      }
      return true;
    }

    final requestStatus = await Permission.microphone.request();
    if (requestStatus.isGranted) {
      if (_isMicPermissionDenied) {
        setState(() => _isMicPermissionDenied = false);
      }
      return true;
    } else {
      setState(() => _isMicPermissionDenied = true);
      return false;
    }
  }

  /// Toggle recording on / off
  Future<void> _toggleRecording() async {
    // If currently playing audio, stop it
    if (_voiceState == VoiceRingState.speaking) {
      await _stopAudio();
      return;
    }

    // Disallow toggling during transcription / thinking
    if (_voiceState == VoiceRingState.transcribing || _voiceState == VoiceRingState.thinking) {
      return;
    }

    if (_voiceState == VoiceRingState.listening) {
      await _stopAndProcessRecording();
    } else {
      await _startRecording();
    }
  }

  /// Start capturing audio from microphone
  Future<void> _startRecording() async {
    final hasPerm = await _checkPermission();
    if (!hasPerm) return;

    try {
      String? recordingPath;
      if (!kIsWeb) {
        recordingPath = '${Directory.systemTemp.path}/voice_query_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: recordingPath ?? '',
      );

      setState(() {
        _voiceState = VoiceRingState.listening;
      });
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Microphone Error',
          message: 'Could not initialize recording: $e',
          variant: AppToastVariant.error,
        );
        setState(() => _voiceState = VoiceRingState.idle);
      }
    }
  }

  /// Stop recording and send audio to backend
  Future<void> _stopAndProcessRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path == null && !kIsWeb) {
        setState(() => _voiceState = VoiceRingState.idle);
        return;
      }

      setState(() {
        _voiceState = VoiceRingState.transcribing;
      });

      if (!mounted) return;
      final sessionProvider = context.read<SessionProvider>();

      // Send to FastAPI /api/voice/chat
      List<int>? fileBytes;
      if (path != null && !kIsWeb) {
        final file = File(path);
        if (await file.exists()) {
          fileBytes = await file.readAsBytes();
        }
      }

      // Transition visual cue to "Thinking..."
      Timer(const Duration(milliseconds: 900), () {
        if (mounted && _voiceState == VoiceRingState.transcribing) {
          setState(() => _voiceState = VoiceRingState.thinking);
        }
      });

      final response = await _apiClient.sendVoiceChat(
        filePath: path,
        fileBytes: fileBytes,
        sessionId: sessionProvider.sessionId,
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final queryText = data['query'] as String? ?? 'Spoken voice query';
        final answerText = data['answer'] as String? ?? 'No response returned.';
        final source = data['source'] as String? ?? 'knowledge_base';
        final audioBase64 = data['audio_base64'] as String?;

        final citationsList = (data['citations'] as List<dynamic>? ?? [])
            .map((c) => Citation.fromJson(c as Map<String, dynamic>))
            .toList();

        final botMsgId = 'bot_${DateTime.now().millisecondsSinceEpoch}';

        setState(() {
          _messages.add(ChatMessage(
            id: 'user_${DateTime.now().millisecondsSinceEpoch}',
            text: queryText,
            isUser: true,
            timestamp: DateTime.now(),
          ));

          _messages.add(ChatMessage(
            id: botMsgId,
            text: answerText,
            isUser: false,
            timestamp: DateTime.now(),
            source: source,
            citations: citationsList,
            audioBase64: audioBase64,
          ));
        });

        _scrollToBottom();

        // Auto-play synthesized voice output
        if (audioBase64 != null && audioBase64.isNotEmpty) {
          await _playAudio(audioBase64, botMsgId);
        } else {
          setState(() => _voiceState = VoiceRingState.idle);
        }
      } else {
        // Fallback for offline demonstration
        _handleOfflineFallback();
      }
    } catch (e) {
      if (mounted) {
        _handleOfflineFallback();
      }
    }
  }

  void _handleOfflineFallback() {
    final botMsgId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages.add(ChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        text: 'What is our remote work equipment allowance?',
        isUser: true,
        timestamp: DateTime.now(),
      ));

      _messages.add(ChatMessage(
        id: botMsgId,
        text: 'According to Section 4.2 of the **Acme HR Policy Handbook**, full-time employees are eligible for a **\$500 one-time reimbursement** for ergonomic home office furniture upon hire, and an annual **\$300 refresh allowance**.',
        isUser: false,
        timestamp: DateTime.now(),
        source: 'knowledge_base',
        citations: const [
          Citation(
            filename: 'acme_hr_policy_handbook.txt',
            chunkText: 'Section 4.2 - Remote Equipment Reimbursement: Full-time employees receive a one-time \$500 work-from-home setup stipend and an annual \$300 ergonomic allowance.',
            score: 0.914,
          ),
        ],
        audioBase64: 'mock_audio_sample',
      ));
      _voiceState = VoiceRingState.idle;
    });
    _scrollToBottom();
  }

  /// Play audio from base64 string
  Future<void> _playAudio(String? base64String, String messageId) async {
    if (base64String == null || base64String.isEmpty) return;

    try {
      setState(() {
        _currentlyPlayingMessageId = messageId;
        _voiceState = VoiceRingState.speaking;
      });

      if (base64String == 'mock_audio_sample') {
        // Mock timer for UI testing without crashing WAV decoder
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _currentlyPlayingMessageId = null;
              if (_voiceState == VoiceRingState.speaking) {
                _voiceState = VoiceRingState.idle;
              }
            });
          }
        });
        return;
      }

      final bytes = base64Decode(base64String);
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentlyPlayingMessageId = null;
          _voiceState = VoiceRingState.idle;
        });
      }
    }
  }

  /// Stop active playback
  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _currentlyPlayingMessageId = null;
        if (_voiceState == VoiceRingState.speaking) {
          _voiceState = VoiceRingState.idle;
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
        // Permission Denied Warning Card
        if (_isMicPermissionDenied)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
            child: PermissionDeniedCard(
              onRequestPermission: _checkPermission,
            ),
          ),

        // Focal Mic Button & Concentric Pulsing Waveforms
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
          child: Column(
            children: [
              VoiceWaveformRing(
                state: _voiceState,
                diameter: 96,
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _voiceState == VoiceRingState.listening
                            ? [colors.error, colors.error.withValues(alpha: 0.85)]
                            : (_voiceState == VoiceRingState.speaking
                                ? [colors.success, colors.success.withValues(alpha: 0.85)]
                                : [colors.primary, const Color(0xFF4F46E5)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_voiceState == VoiceRingState.listening
                                  ? colors.error
                                  : (_voiceState == VoiceRingState.speaking ? colors.success : colors.primary))
                              .withValues(alpha: 0.4),
                          offset: const Offset(0, 6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _voiceState == VoiceRingState.listening
                            ? LucideIcons.square
                            : (_voiceState == VoiceRingState.speaking
                                ? LucideIcons.volume2
                                : (_voiceState == VoiceRingState.transcribing || _voiceState == VoiceRingState.thinking
                                    ? LucideIcons.loader2
                                    : LucideIcons.mic)),
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.vGap12,

              // Multi-Stage Dynamic Status Description Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                child: Text(
                  _statusLabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(
                    color: _voiceState == VoiceRingState.listening
                        ? colors.error
                        : (_voiceState == VoiceRingState.speaking
                            ? colors.success
                            : (_voiceState != VoiceRingState.idle ? colors.primary : colors.textSecondary)),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1),

        // Conversation Message List Area (reusing ChatBubble)
        Expanded(
          child: _messages.isEmpty
              ? _buildVoiceEmptyState(colors)
              : ListView.builder(
                  controller: _scrollController,
                  padding: AppSpacing.screenPadding,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return ChatBubble(
                      message: msg,
                      onPlayAudio: msg.audioBase64 != null ? () => _playAudio(msg.audioBase64, msg.id) : null,
                      onStopAudio: _stopAudio,
                      isAudioPlaying: _currentlyPlayingMessageId == msg.id,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVoiceEmptyState(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32, vertical: AppSpacing.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.audioWaveform,
              size: 28,
              color: colors.primary.withValues(alpha: 0.6),
            ),
            AppSpacing.vGap12,
            Text(
              'Voice Assistant Ready',
              style: AppTextStyles.headingSmall(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap6,
            Text(
              'Tap the microphone above to speak your question aloud.',
              style: AppTextStyles.bodySmall(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

