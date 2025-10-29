import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF2E7D32),
      selectedItemColor: Colors.white70,
      unselectedItemColor: Colors.white,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed, // Ensure all items are visible
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.houseChimney, size: 18) ,
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.leaf, size: 18),
          label: 'Growup',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.shoppingCart, size: 18),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.building, size: 18),
          label: 'Properties',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.bars, size: 18),
          label: 'Menu',
        ),
      ],
    );
  }
}