import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // VAD (Voice Activity Detection) & Automatic Silence Detection
  Timer? _silenceCheckTimer;
  Timer? _maxRecordingTimer;
  DateTime? _silenceStartTime;
  DateTime? _recordingStartTime;
  double _peakDb = -160.0;
  bool _hasDetectedSpeech = false;
  bool _isAutoEnding = false;
  bool _isProcessingRecording = false;
  int _speechTickCount = 0;

  // Sensitive speech threshold (-48 dB catches regular & soft speaking voice)
  static const double _speechThresholdDb = -48.0;
  static const Duration _silenceAutoStopDuration = Duration(milliseconds: 1350);
  static const Duration _maxRecordingDuration = Duration(seconds: 45);

  // Status subtitle display text
  String get _statusLabel {
    switch (_voiceState) {
      case VoiceRingState.listening:
        if (_isAutoEnding) {
          return 'Processing your question...';
        } else if (_hasDetectedSpeech) {
          return 'Listening...';
        }
        return 'Listening... Speak now';
      case VoiceRingState.transcribing:
        return 'Transcribing voice...';
      case VoiceRingState.thinking:
        return 'Analyzing documents...';
      case VoiceRingState.speaking:
        return 'Speaking response...';
      case VoiceRingState.idle:
        return 'Tap the microphone to speak';
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
    _cancelSilenceDetection();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Request microphone permission
  Future<bool> _checkPermission() async {
    if (kIsWeb) return true;

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
    if (_voiceState == VoiceRingState.speaking) {
      await _stopAudio();
      return;
    }

    if (_voiceState == VoiceRingState.transcribing ||
        _voiceState == VoiceRingState.thinking ||
        _isProcessingRecording) {
      return;
    }

    if (_voiceState == VoiceRingState.listening) {
      await _stopAndProcessRecording();
    } else {
      await _startRecording();
    }
  }

  /// Start capturing audio from microphone with automatic silence detection
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

      _recordingStartTime = DateTime.now();
      _silenceStartTime = null;
      _peakDb = -160.0;
      _speechTickCount = 0;
      _hasDetectedSpeech = false;
      _isAutoEnding = false;
      _isProcessingRecording = false;

      setState(() {
        _voiceState = VoiceRingState.listening;
      });

      _startSilenceDetector();
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

  /// Starts periodic direct native amplitude polling and auto-stops on 3-second silence
  void _startSilenceDetector() {
    _cancelSilenceDetection();

    _peakDb = -160.0;
    _speechTickCount = 0;
    _silenceStartTime = null;

    _silenceCheckTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) async {
      if (_voiceState != VoiceRingState.listening || _isProcessingRecording) {
        return;
      }

      try {
        final amp = await _audioRecorder.getAmplitude();
        final currentDb = (amp.current > -150.0) ? amp.current : amp.max;

        if (currentDb > _peakDb) {
          _peakDb = currentDb;
        }

        final isSpeaking = currentDb >= _speechThresholdDb &&
            (currentDb >= _peakDb - 9.0 || _peakDb <= -42.0);

        if (isSpeaking) {
          _speechTickCount++;
          if (_speechTickCount >= 2) {
            _hasDetectedSpeech = true;
          }
          _silenceStartTime = null;
          if (_isAutoEnding && mounted) {
            setState(() {
              _isAutoEnding = false;
            });
          }
        } else {
          if (_hasDetectedSpeech) {
            _silenceStartTime ??= DateTime.now();
            final silenceElapsed = DateTime.now().difference(_silenceStartTime!);

            if (silenceElapsed >= _silenceAutoStopDuration) {
              _isAutoEnding = true;
              if (mounted) setState(() {});
              _stopAndProcessRecording();
              return;
            } else if (silenceElapsed.inMilliseconds >= 700 && !_isAutoEnding) {
              if (mounted) {
                setState(() {
                  _isAutoEnding = true;
                });
              }
            }
          } else {
            if (_recordingStartTime != null &&
                DateTime.now().difference(_recordingStartTime!) >= const Duration(seconds: 12)) {
              _stopRecordingWithoutProcessing();
            }
          }
        }
      } catch (_) {
        if (_recordingStartTime != null && _hasDetectedSpeech) {
          final elapsed = DateTime.now().difference(_recordingStartTime!);
          if (elapsed >= const Duration(seconds: 10)) {
            _stopAndProcessRecording();
          }
        }
      }
    });

    _maxRecordingTimer = Timer(_maxRecordingDuration, () {
      if (_voiceState == VoiceRingState.listening && !_isProcessingRecording) {
        _stopAndProcessRecording();
      }
    });
  }

  void _cancelSilenceDetection() {
    _silenceCheckTimer?.cancel();
    _silenceCheckTimer = null;
    _maxRecordingTimer?.cancel();
    _maxRecordingTimer = null;
  }

  Future<void> _stopRecordingWithoutProcessing() async {
    _cancelSilenceDetection();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _voiceState = VoiceRingState.idle;
        _isAutoEnding = false;
        _isProcessingRecording = false;
      });
      AppToast.show(
        context,
        title: 'Listening Cancelled',
        message: 'No speech detected after 12 seconds.',
        variant: AppToastVariant.info,
      );
    }
  }

  /// Stop recording and send audio to backend
  Future<void> _stopAndProcessRecording() async {
    if (_isProcessingRecording) return;
    _isProcessingRecording = true;
    _cancelSilenceDetection();

    try {
      final path = await _audioRecorder.stop();
      if (path == null && !kIsWeb) {
        setState(() {
          _voiceState = VoiceRingState.idle;
          _isProcessingRecording = false;
          _isAutoEnding = false;
        });
        return;
      }

      setState(() {
        _voiceState = VoiceRingState.transcribing;
        _isAutoEnding = false;
      });

      if (!mounted) {
        _isProcessingRecording = false;
        return;
      }
      final sessionProvider = context.read<SessionProvider>();

      List<int>? fileBytes;
      if (path != null && !kIsWeb) {
        final file = File(path);
        if (await file.exists()) {
          fileBytes = await file.readAsBytes();
        }
      }

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

      if (!mounted) {
        _isProcessingRecording = false;
        return;
      }

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

        sessionProvider.addVoiceMessage(ChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          text: queryText,
          isUser: true,
          timestamp: DateTime.now(),
        ));

        sessionProvider.addVoiceMessage(ChatMessage(
          id: botMsgId,
          text: answerText,
          isUser: false,
          timestamp: DateTime.now(),
          source: source,
          citations: citationsList,
          audioBase64: audioBase64,
        ));

        _scrollToBottom();
        _isProcessingRecording = false;

        if (audioBase64 != null && audioBase64.isNotEmpty) {
          await _playAudio(audioBase64, botMsgId);
        } else {
          setState(() => _voiceState = VoiceRingState.idle);
        }
      } else {
        _isProcessingRecording = false;
        setState(() => _voiceState = VoiceRingState.idle);
        if (mounted) {
          AppToast.show(
            context,
            title: 'Voice Error',
            message: response.error ?? 'Could not process voice query. Please verify backend connection.',
            variant: AppToastVariant.error,
          );
        }
      }
    } catch (e) {
      _isProcessingRecording = false;
      if (mounted) {
        setState(() => _voiceState = VoiceRingState.idle);
        AppToast.show(
          context,
          title: 'Voice Error',
          message: 'Error processing voice: $e',
          variant: AppToastVariant.error,
        );
      }
    }
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

  Color _getStateColor(AppThemeColors colors) {
    switch (_voiceState) {
      case VoiceRingState.listening:
        return AppColors.neonMagenta;
      case VoiceRingState.transcribing:
        return AppColors.neonOrange;
      case VoiceRingState.thinking:
        return AppColors.neonCyan;
      case VoiceRingState.speaking:
        return AppColors.neonGreen;
      case VoiceRingState.idle:
        return colors.primary;
    }
  }

  List<Color> _getOrbGradient() {
    switch (_voiceState) {
      case VoiceRingState.listening:
        return AppColors.voiceListeningGradient;
      case VoiceRingState.transcribing:
        return AppColors.voiceTranscribingGradient;
      case VoiceRingState.thinking:
        return AppColors.voiceThinkingGradient;
      case VoiceRingState.speaking:
        return AppColors.voiceSpeakingGradient;
      case VoiceRingState.idle:
        return AppColors.voiceIdleGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final sessionProvider = context.watch<SessionProvider>();
    final messages = sessionProvider.voiceMessages;
    final stateColor = _getStateColor(colors);
    final orbGradient = _getOrbGradient();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 720;
    final orbDiameter = isCompact ? 80.0 : 92.0;
    final orbIconSize = isCompact ? 32.0 : 36.0;

    return Column(
      children: [
        // Permission Denied Warning Card
        if (_isMicPermissionDenied)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
            child: PermissionDeniedCard(
              onRequestPermission: _checkPermission,
            ),
          ),

        // Focal Mic Button & Premium Animated Voice Orb
        Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? AppSpacing.s6 : AppSpacing.s10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceWaveformRing(
                state: _voiceState,
                diameter: orbDiameter,
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: orbDiameter,
                    height: orbDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: orbGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: AppShadows.neonGlow(
                        stateColor,
                        intensity: _voiceState == VoiceRingState.idle ? 0.2 : 0.45,
                        blur: _voiceState == VoiceRingState.idle ? 14 : 24,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _voiceState == VoiceRingState.listening
                              ? LucideIcons.square
                              : (_voiceState == VoiceRingState.speaking
                                  ? LucideIcons.volume2
                                  : (_voiceState == VoiceRingState.transcribing || _voiceState == VoiceRingState.thinking
                                      ? LucideIcons.loader2
                                      : LucideIcons.mic)),
                          key: ValueKey(_voiceState),
                          size: orbIconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 6 : 10),

              // Animated status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  key: ValueKey(_statusLabel),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
                  child: Text(
                    _statusLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(
                      color: stateColor,
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: isCompact ? 12.5 : 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Gradient divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                stateColor.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Conversation Message List Area
        Expanded(
          child: messages.isEmpty
              ? _buildVoiceEmptyState(colors)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.audioWaveform,
                      size: 28,
                      color: colors.primary.withValues(alpha: 0.5),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                          duration: 2000.ms,
                          curve: Curves.easeInOut,
                        )
                        .fade(begin: 0.5, end: 1.0, duration: 2000.ms),
                    AppSpacing.vGap12,
                    Text(
                      'Voice Assistant Ready',
                      style: AppTextStyles.headingMedium(color: colors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.vGap6,
                    Text(
                      'Tap the microphone above to speak your question.\nThe assistant auto-detects when you pause.',
                      style: AppTextStyles.bodySmall(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
