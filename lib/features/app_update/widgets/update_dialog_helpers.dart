import 'package:flutter/material.dart';
import 'package:equity_tracker/features/app_update/widgets/update_status_dialog.dart';
import 'package:equity_tracker/features/app_update/widgets/update_prompt_dialog.dart';

/// Helper function to show update dialog
Future<void> showUpdateDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UpdatePromptDialog(),
  );
}

/// Helper to show status/checking dialog
Future<void> showUpdateCheckingDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UpdateStatusDialog(
      message: '正在連接 GitHub 伺服器...',
    ),
  );
}
