import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatsTab {
  trend,
  category,
}

class StatsTabNotifier extends Notifier<StatsTab> {
  @override
  StatsTab build() => StatsTab.trend;

  void toggle() {
    state = state == StatsTab.trend ? StatsTab.category : StatsTab.trend;
  }
}

final statsTabProvider = NotifierProvider<StatsTabNotifier, StatsTab>(
  StatsTabNotifier.new,
);
