class RecordData {
  String? item;
  int? price;
  String? store;
  String? locationClue;
  int? qty;
  String? categoryId;
  String? date;

  RecordData({
    this.item,
    this.price,
    this.store,
    this.locationClue,
    this.qty,
    this.categoryId,
    this.date,
  });

  factory RecordData.fromMap(Map<String, dynamic> map) {
    return RecordData(
      item: map['item'] as String?,
      price: (map['price'] as num?)?.toInt(),
      store: map['store'] as String?,
      locationClue: map['locationClue'] as String?,
      qty: (map['qty'] as num?)?.toInt(),
      categoryId: map['categoryId'] as String?,
      date: map['date'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'price': price,
      'store': store,
      'locationClue': locationClue,
      'qty': qty,
      'categoryId': categoryId,
      'date': date,
    };
  }

  RecordData copyWith({
    String? item,
    int? price,
    String? store,
    String? locationClue,
    int? qty,
    String? categoryId,
    String? date,
  }) {
    return RecordData(
      item: item ?? this.item,
      price: price ?? this.price,
      store: store ?? this.store,
      locationClue: locationClue ?? this.locationClue,
      qty: qty ?? this.qty,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
    );
  }
}
