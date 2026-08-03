import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_session_controller.dart';
import 'package:equity_tracker/features/ai/usecases/process_expense_usecase.dart';

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
  bool _isSessionStarted = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!_isSessionStarted) {
      _isSessionStarted = true;
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

    // Auto-scroll when logs update
    ref.listen(aiSessionControllerProvider.select((s) => s.logs.length), (_, __) => _scrollToBottom());

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              '✨ AI 智慧記帳',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Console / Progress Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: sessionState.logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        sessionState.logs[index],
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Interactive UI based on state
            if (sessionState.pendingAction != null)
              _buildActionUI(context, sessionState.pendingAction!),
              
            if (sessionState.isProcessing)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),

            const SizedBox(height: 16),

            // Input Area
            if (sessionState.pendingAction == null && !sessionState.isProcessing && _isSessionStarted)
              const SizedBox() // Session is done or error
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: _isSessionStarted ? '請輸入回答...' : '例如：午餐吃雞腿便當 100 元',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.send),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionUI(BuildContext context, UseCaseResult action) {
    if (action is RequireStoreSelectionResult) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            action.message,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          if (action.options.isNotEmpty)
            Wrap(
              spacing: 8,
              children: action.options.map((option) {
                return ActionChip(
                  label: Text(option),
                  onPressed: () {
                    _controller.text = option;
                    _handleSubmit();
                  },
                );
              }).toList(),
            ),
        ],
      );
    } else if (action is RequireCorrectionResult) {
      return Text(
        '❓ \${action.question}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      );
    }
    return const SizedBox();
  }
}
