import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/providers/notification_provider.dart';
import 'package:equity_tracker/core/widgets/premium_toast_widget.dart';

class GlobalNotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalNotificationOverlay({super.key, required this.child});

  @override
  ConsumerState<GlobalNotificationOverlay> createState() => _GlobalNotificationOverlayState();
}

class _GlobalNotificationOverlayState extends ConsumerState<GlobalNotificationOverlay> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<NotificationModel> _currentNotifications = [];

  @override
  Widget build(BuildContext context) {
    ref.listen<List<NotificationModel>>(notificationControllerProvider, (previous, next) {
      final prev = previous ?? [];
      
      // Handle additions (assuming new items are added at index 0)
      for (int i = 0; i < next.length; i++) {
        if (!prev.any((n) => n.id == next[i].id)) {
          _currentNotifications.insert(i, next[i]);
          _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 400));
        }
      }

      // Handle removals
      for (int i = prev.length - 1; i >= 0; i--) {
        if (!next.any((n) => n.id == prev[i].id)) {
          final removedItem = prev[i];
          final removeIndex = _currentNotifications.indexWhere((n) => n.id == removedItem.id);
          if (removeIndex != -1) {
            _currentNotifications.removeAt(removeIndex);
            _listKey.currentState?.removeItem(
              removeIndex,
              (context, animation) => _buildItem(removedItem, animation),
              duration: const Duration(milliseconds: 300),
            );
          }
        }
      }
    });

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 0,
          child: IgnorePointer(
            // Allow touches to pass through if they don't hit a toast
            ignoring: false,
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _currentNotifications.length,
              shrinkWrap: true,
              itemBuilder: (context, index, animation) {
                return _buildItem(_currentNotifications[index], animation);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(NotificationModel notification, Animation<double> animation) {
    return PremiumToastWidget(
      notification: notification,
      animation: animation,
      onDismiss: () {
        ref.read(notificationControllerProvider.notifier).remove(notification.id);
      },
    );
  }
}
