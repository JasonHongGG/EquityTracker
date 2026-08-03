import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_session_controller.dart';
import 'package:equity_tracker/features/ai/usecases/process_expense_usecase.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/ai/presentation/screens/ai_log_viewer_screen.dart';
import 'dart:math' as math;

void showAiInputBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AiInputBottomSheet(),
  );
}

class AiInputBottomSheet extends ConsumerStatefulWidget {
  const AiInputBottomSheet({super.key});

  @override
  ConsumerState<AiInputBottomSheet> createState() => _AiInputBottomSheetState();
}

class _AiInputBottomSheetState extends ConsumerState<AiInputBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final sessionState = ref.read(aiSessionControllerProvider);

    if (sessionState.pendingAction == null) {
      ref.read(aiSessionControllerProvider.notifier).startSession(text);
    } else {
      ref.read(aiSessionControllerProvider.notifier).submitAnswer(text);
    }
    
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(aiSessionControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(aiSessionControllerProvider.select((s) => s.messages.length), (_, __) => _scrollToBottom());

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: Container(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: sessionState.messages.length,
                  itemBuilder: (context, index) {
                    return _buildChatBubble(sessionState.messages[index], isDark);
                  },
                ),
              ),
            ),
            
            if (sessionState.pendingAction != null)
              _buildActionCard(context, sessionState.pendingAction!, isDark),
              
            if (sessionState.isProcessing)
              _buildThinkingBubble(sessionState, isDark),

            _buildInputArea(sessionState, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI 智慧記帳',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.terminal_rounded, color: isDark ? Colors.white54 : Colors.black54),
                tooltip: 'Developer Logs',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiLogViewerScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isDark) {
    final isUser = message.type == ChatMessageType.user;
    final isError = message.type == ChatMessageType.error;
    final isSystem = message.type == ChatMessageType.system;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isError ? Colors.red.withValues(alpha: 0.1) : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Icon(
                isError ? Icons.error_outline : Icons.smart_toy_rounded, 
                size: 16, 
                color: isError ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor 
                    : (isError 
                        ? Colors.red.withValues(alpha: 0.1) 
                        : (isDark ? AppColors.surfaceDark : Colors.white)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: isUser || isError ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isUser 
                      ? Colors.white 
                      : (isError 
                          ? Colors.red 
                          : (isDark ? Colors.white : Colors.black87)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(AISessionState sessionState, bool isDark) {
    if (!sessionState.isProcessing) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Icon(Icons.smart_toy_outlined, size: 16, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlowingThinkingOrbs(baseColor: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'AI 思考中...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (sessionState.thinkingSteps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...sessionState.thinkingSteps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, UseCaseResult action, bool isDark) {
    if (action is RequireStoreSelectionResult) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_rounded, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action.message,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            if (action.options.isNotEmpty) ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: action.options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(option),
                        labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          _controller.text = option;
                          _handleSubmit();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );
    } else if (action is RequireCorrectionResult) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.question,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildInputArea(AISessionState sessionState, bool isDark) {
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: sessionState.pendingAction != null ? '請輸入回答...' : '例如：午餐吃雞腿便當 100 元',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                      onPressed: _handleSubmit,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlowingThinkingOrbs extends StatefulWidget {
  final Color baseColor;
  
  const GlowingThinkingOrbs({super.key, required this.baseColor});

  @override
  State<GlowingThinkingOrbs> createState() => _GlowingThinkingOrbsState();
}

class _GlowingThinkingOrbsState extends State<GlowingThinkingOrbs> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Offset the animation for each dot
            final t = (_controller.value * 2 * math.pi) + (index * (2 * math.pi / 3));
            final scale = 0.8 + 0.4 * (0.5 * (1 + math.sin(t)));
            final opacity = 0.4 + 0.6 * (0.5 * (1 + math.sin(t)));
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.baseColor.withValues(alpha: opacity),
                    boxShadow: [
                      BoxShadow(
                        color: widget.baseColor.withValues(alpha: opacity * 0.8),
                        blurRadius: 8 * scale,
                        spreadRadius: 2 * scale,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
