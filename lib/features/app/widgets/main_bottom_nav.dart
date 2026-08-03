import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/glass_container.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/features/transaction/screens/transaction_list/transaction_list_screen.dart';
import 'package:equity_tracker/features/ai/presentation/screens/ai_input_bottom_sheet.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: GlassContainer(
        opacity: 0.1,
        blur: 20,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, FontAwesomeIcons.wallet, 'Wallet'),
              _buildNavItem(context, 1, FontAwesomeIcons.chartPie, 'Analysis'),
              _buildCenterAddButton(context),
              _buildNavItem(context, 2, FontAwesomeIcons.repeat, 'Recurring'),
              // Empty space to balance the 5 items layout
              const SizedBox(width: 40), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showAddOptions(context);
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          FontAwesomeIcons.plus,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          opacity: 0.15,
          blur: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(FontAwesomeIcons.robot, color: Colors.white, size: 18),
                  ),
                  title: const Text('AI 智慧記帳', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('用一句話自動記錄多筆花費'),
                  onTap: () {
                    Navigator.pop(context);
                    showAiInputBottomSheet(context);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(FontAwesomeIcons.penToSquare, color: Colors.white, size: 18),
                  ),
                  title: const Text('手動記帳', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('開啟詳細的記帳表單'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add-transaction');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: isSelected
            ? BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}
