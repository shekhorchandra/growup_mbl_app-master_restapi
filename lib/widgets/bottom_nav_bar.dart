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
      backgroundColor: const Color(0xFF83AB78),
      selectedItemColor: Colors.white70,
      unselectedItemColor: Colors.white,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed, // Ensure all items are visible
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.bars),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.leaf),
          label: 'Growup',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.houseChimney) ,
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.shoppingCart),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.building),
          label: 'Properties',
        ),
      ],
    );
  }
}