enum Frequency {
  daily,
  weekly,
  monthly,
  yearly
}

extension FrequencyExtension on Frequency {
  String get label {
    switch (this) {
      case Frequency.daily: return '每天';
      case Frequency.weekly: return '每週';
      case Frequency.monthly: return '每月';
      case Frequency.yearly: return '每年';
    }
  }
}
