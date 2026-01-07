import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/transaction_type.dart';
import '../providers/category_provider.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  final TransactionType? initialType;
  final Category? categoryToEdit;

  const AddCategoryScreen({super.key, this.initialType, this.categoryToEdit});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  late TransactionType _selectedType;
  final TextEditingController _nameController = TextEditingController();

  // Selection
  int _selectedIconCode = 0xe52d; // Default: FastFood (Material) or similar
  String? _selectedFontFamily = 'MaterialIcons';
  String? _selectedFontPackage;
  Color _selectedColor = const Color(0xFFFF9500); // Default Orange

  // Predefined Colors (Sorted for visual consistency)
  final List<Color> _colors = [
    const Color(0xFFFF3B30), // Red
    const Color(0xFFFF2D55), // Pink
    const Color(0xFFAF52DE), // Purple
    const Color(0xFF5856D6), // Indigo
    const Color(0xFF007AFF), // Blue
    const Color(0xFF32ADE6), // Light Blue
    const Color(0xFF30B0C7), // Cyan
    const Color(0xFF00C7BE), // Teal
    const Color(0xFF34C759), // Green
    const Color(0xFFFFCC00), // Yellow
    const Color(0xFFFF9500), // Orange
    const Color(0xFFA2845E), // Brown
    const Color(0xFF8E8E93), // Grey
    const Color(0xFF1C1C1E), // Black/Dark
  ];

  // Predefined Icons (Material)
  final List<Map<String, dynamic>> _icons = [
    // Top 12 - Diverse & Common
    {'icon': Icons.fastfood, 'family': 'MaterialIcons', 'pkg': null}, // Food
    {'icon': Icons.train, 'family': 'MaterialIcons', 'pkg': null}, // Transport
    {
      'icon': Icons.shopping_bag,
      'family': 'MaterialIcons',
      'pkg': null,
    }, // Shopping
    {'icon': Icons.house, 'family': 'MaterialIcons', 'pkg': null}, // Housing
    {
      'icon': Icons.sports_esports,
      'family': 'MaterialIcons',
      'pkg': null,
    }, // Fun
    {
      'icon': Icons.medical_services,
      'family': 'MaterialIcons',
      'pkg': null,
    }, // Health
    {'icon': Icons.school, 'family': 'MaterialIcons', 'pkg': null}, // Education
    {'icon': Icons.work, 'family': 'MaterialIcons', 'pkg': null}, // Income
    {'icon': Icons.flight, 'family': 'MaterialIcons', 'pkg': null}, // Travel
    {'icon': Icons.pets, 'family': 'MaterialIcons', 'pkg': null}, // Family
    {'icon': Icons.receipt, 'family': 'MaterialIcons', 'pkg': null}, // Bills
    {'icon': Icons.savings, 'family': 'MaterialIcons', 'pkg': null}, // Savings
    // Food & Drink
    {'icon': Icons.restaurant, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_cafe, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_bar, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_pizza, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.icecream, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.bakery_dining, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.liquor, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.restaurant_menu, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.breakfast_dining, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.brunch_dining, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.dinner_dining, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.lunch_dining, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.takeout_dining, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.kitchen, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.emoji_food_beverage, 'family': 'MaterialIcons', 'pkg': null},

    // Transport
    {'icon': Icons.directions_car, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.directions_bus, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_taxi, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.pedal_bike, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.directions_walk, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_gas_station, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_parking, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.ev_station, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.subway, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.tram, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.moped, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.two_wheeler, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.airport_shuttle, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.commute, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.departure_board, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.directions_boat, 'family': 'MaterialIcons', 'pkg': null},

    // Shopping
    {'icon': Icons.shopping_cart, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_grocery_store, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.card_giftcard, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.credit_card, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.checkroom, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.watch, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.style, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.store, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.storefront, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.redeem, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.loyalty, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_mall, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_offer, 'family': 'MaterialIcons', 'pkg': null},

    // Housing & Utilities
    {'icon': Icons.apartment, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.hotel, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.weekend, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.bed, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.water_drop, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.bolt, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.wifi, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.phone_android, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.build, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.lightbulb, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.electrical_services, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.plumbing, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.cleaning_services, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.yard, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.chair, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.door_sliding, 'family': 'MaterialIcons', 'pkg': null},

    // Health & Wellness
    {'icon': Icons.local_hospital, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.medication, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.fitness_center, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.spa, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.pool, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.healing, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.monitor_heart, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.pregnant_woman, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.sanitizer, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.masks, 'family': 'MaterialIcons', 'pkg': null},

    // Entertainment & Sports
    {'icon': Icons.movie, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.theaters, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.music_note, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.sports_soccer, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.sports_basketball, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.casino, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.camera_alt, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.sports_tennis, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.sports_golf, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.sports_football, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.sports_baseball, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.sports_volleyball, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.surfing, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.skateboarding, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.hiking, 'family': 'MaterialIcons', 'pkg': null},

    // Tech & Gadgets
    {'icon': Icons.headphones, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.headset, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.keyboard, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.mouse, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.monitor, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.tablet, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.smartphone, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.videogame_asset, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.computer, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.speaker, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.memory, 'family': 'MaterialIcons', 'pkg': null},

    // Education & Work
    {'icon': Icons.menu_book, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.laptop_mac, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.attach_money, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.trending_up, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.business_center, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.badge, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.groups, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.article, 'family': 'MaterialIcons', 'pkg': null},

    // Family & Personal
    {'icon': Icons.child_friendly, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.face, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.celebration, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.cake, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.local_florist, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.stroller, 'family': 'MaterialIcons', 'pkg': null},

    // Finance & Misc
    {'icon': Icons.account_balance, 'family': 'MaterialIcons', 'pkg': null},
    {
      'icon': Icons.account_balance_wallet,
      'family': 'MaterialIcons',
      'pkg': null,
    },
    {'icon': Icons.currency_exchange, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.star, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.favorite, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.category, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.map, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.lock, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.settings, 'family': 'MaterialIcons', 'pkg': null},
    {'icon': Icons.notifications, 'family': 'MaterialIcons', 'pkg': null},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      final c = widget.categoryToEdit!;
      _selectedType = c.type;
      _nameController.text = c.name;
      _selectedIconCode = c.iconCodePoint;
      _selectedFontFamily = c.iconFontFamily;
      _selectedFontPackage = c.iconFontPackage;
      _selectedColor = c.color;
    } else {
      _selectedType = widget.initialType ?? TransactionType.expense;
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    // Reuse ID if editing, else new UUID
    final id = widget.categoryToEdit?.id ?? const Uuid().v4();

    final category = Category(
      id: id,
      name: name,
      iconCodePoint: _selectedIconCode,
      iconFontFamily: _selectedFontFamily,
      iconFontPackage: _selectedFontPackage,
      colorValue: _selectedColor.value,
      type: _selectedType,
      isSystem:
          widget.categoryToEdit?.isSystem ?? false, // Preserve system status
      isEnabled: true,
    );

    if (widget.categoryToEdit != null) {
      ref.read(categoryListProvider.notifier).updateCategory(category);
    } else {
      ref.read(categoryListProvider.notifier).addCategory(category);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F111A)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'New Category',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 28),
            tooltip: 'Save Category',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Preview (No Change)
            Container(
              width: 80, // Reduced from 80
              height: 80, // Reduced from 80
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _selectedColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                IconData(
                  _selectedIconCode,
                  fontFamily: _selectedFontFamily,
                  fontPackage: _selectedFontPackage,
                ),
                color: Colors.white,
                size: 32, // Reduced from 40
              ),
            ),
            const SizedBox(height: 16), // Reduced from 32
            // 2. Form Container
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Combined Name & Type Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      12,
                    ), // Tighter padding
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Type Selector
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TYPE',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11, // Reduced font
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 8), // Reduced gap
                              Container(
                                height: 56, // Slightly reduced height
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildTypeTab(
                                        TransactionType.expense,
                                        'Exp',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: _buildTypeTab(
                                        TransactionType.income,
                                        'Inc',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 1. Name Input
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CATEGORY NAME',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Groceries',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: theme.hintColor.withOpacity(0.5),
                                    fontWeight: FontWeight.normal,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey[800]!.withOpacity(0.5)
                                      : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: theme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16, // Tighter input padding
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4), // Reduced spacer
                  // 3. Inline Color Picker header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'COLOR',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Horizontal Color List
                  SizedBox(
                    height: 56, // Reduced from 72
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 12), // Reduced spacing
                      itemBuilder: (context, index) {
                        final color = _colors[index];
                        final isSelected = _selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42, // Reduced from 48
                              height: 42,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Quick Icon Grid header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ICON',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: theme.hintColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showIconPicker(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'See All',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Inline Icon Grid (Top 10)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 12, // Reduced spacing
                      runSpacing: 12,
                      children: _icons.take(12).map((iconData) {
                        final icon = iconData['icon'] as IconData;
                        final isSelected = _selectedIconCode == icon.codePoint;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedIconCode = icon.codePoint;
                            _selectedFontFamily = icon.fontFamily;
                            _selectedFontPackage = icon.fontPackage;
                          }),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _selectedColor.withOpacity(0.2)
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(color: _selectedColor, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? _selectedColor
                                  : (isDark ? Colors.white70 : Colors.black54),
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(TransactionType type, String label) {
    final isSelected = _selectedType == type;
    final color = type == TransactionType.income
        ? const Color(0xFF34C759)
        : const Color(0xFFFF3B30);

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true, // Allow taller sheet
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return divPicker(context, isDark, scrollController);
          },
        );
      },
    );
  }

  Widget divPicker(
    BuildContext context,
    bool isDark,
    ScrollController scrollController,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Icon',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _icons.length,
              itemBuilder: (context, index) {
                final iconData = _icons[index];
                final icon = iconData['icon'] as IconData;
                final isSelected = _selectedIconCode == icon.codePoint;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIconCode = icon.codePoint;
                      _selectedFontFamily = icon.fontFamily;
                      _selectedFontPackage = icon.fontPackage;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withOpacity(0.2)
                          : (isDark ? Colors.white10 : Colors.grey.shade100),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: _selectedColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? _selectedColor
                          : (isDark ? Colors.white70 : Colors.black54),
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
