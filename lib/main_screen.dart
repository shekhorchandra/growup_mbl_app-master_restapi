import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/all_products_page.dart';
import 'package:growup_agro/views/all_projects.dart';
import 'package:growup_agro/views/all_properties.dart';
import 'package:growup_agro/views/investor_dashboard.dart';
import 'package:growup_agro/widgets/bottom_nav_bar.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  late Future<Map<String, dynamic>> _profileFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _bottomNavIndex = 0;

  final List<Widget> _pages = const [
    DashboardInvestor(), // index 0
    AllProjectsPage(),
    AllProductsPage(),
    AllPropertiesPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scaffoldKey.currentState?.hasEndDrawer ?? false) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
      });
    } else {
      setState(() {
        _bottomNavIndex = index;
        _selectedIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _profileFuture = getInvestorProfileFromPrefs();

    // Then refresh data in background
    fetchAndSaveInvestorProfile().then((_) {
      setState(() {
        _profileFuture = getInvestorProfileFromPrefs(); // Load fresh profile
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      endDrawer: Drawer(
        backgroundColor: const Color(0xFFFFFFFF),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text("Error loading profile"));
            } else {
              final profile = snapshot.data!;
              return SafeArea(
                top: false,
                child: Container(
                  color: const Color(0xFFFFFFFF),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // ---------------- HEADER ----------------
                      UserAccountsDrawerHeader(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                        ),
                        margin: EdgeInsets.zero,
                        accountName: Text(
                          profile['name'] ?? 'No Name',
                          style: const TextStyle(color: Colors.white),
                        ),
                        accountEmail: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "${profile['code']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true)
                                        .pushNamed('/myprofile');
                                  }
                                });
                              },
                              child: Image.asset(
                                'assets/icons/edit.png',
                                width: 24,
                                height: 24,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        currentAccountPicture: CircleAvatar(
                          backgroundImage: profile['image'] != null &&
                              profile['image'].toString().isNotEmpty
                              ? NetworkImage(
                            "${ApiConstants.imgBaseUrl}/storage/${profile['image']}",
                          )
                              : const AssetImage('assets/images/img.png')
                          as ImageProvider,
                        ),
                      ),

                      // ---------------- MENU ITEMS ----------------
                      _drawerTile(context, FontAwesomeIcons.gaugeHigh,
                          'Dashboard', '/dashboard'),

                      ExpansionTile(
                        leading: const Icon(FontAwesomeIcons.wallet,
                            color: Colors.green, size: 20),
                        title: const Text('Wallet',
                            style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        childrenPadding: const EdgeInsets.only(left: 30),
                        children: [
                          _drawerTile(context, FontAwesomeIcons.wallet, 'My Wallet',
                              '/wallet'),
                          _drawerTile(context, FontAwesomeIcons.moneyCheck, 'Deposit',
                              '/deposit'),
                          _drawerTile(context, FontAwesomeIcons.arrowDown, 'Withdraw',
                              '/withdraw'),
                        ],
                      ),

                      ExpansionTile(
                        leading: const Icon(FontAwesomeIcons.seedling,
                            color: Colors.green, size: 20),
                        title: const Text('Growup',
                            style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        childrenPadding: const EdgeInsets.only(left: 30),
                        children: [
                          _drawerTile(context, FontAwesomeIcons.folderOpen, 'Projects',
                              '/projects'),
                          _drawerTile(context, FontAwesomeIcons.diagramProject,
                              'Invested Projects', '/myprojects'),
                        ],
                      ),

                      ExpansionTile(
                        leading: const Icon(FontAwesomeIcons.fileInvoiceDollar,
                            color: Colors.green, size: 20),
                        title: const Text('Invoices',
                            style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        childrenPadding: const EdgeInsets.only(left: 30),
                        children: [
                          _drawerTile(context, FontAwesomeIcons.fileInvoice, 'Growup',
                              '/invoice_growup'),
                          _drawerTile(context, FontAwesomeIcons.warehouse, 'Property',
                              '/invoice_property'),
                          _drawerTile(context, FontAwesomeIcons.fileInvoiceDollar,
                              'Recharge', '/invoice_recharge'),
                          _drawerTile(context, FontAwesomeIcons.coins, 'ROI',
                              '/invoice_roi'),
                          _drawerTile(context, FontAwesomeIcons.handHoldingDollar,
                              'Capital Return', '/capital_return'),
                        ],
                      ),

                      _drawerTile(context, FontAwesomeIcons.clockRotateLeft,
                          'Investment History', '/investmenthistory'),

                      ExpansionTile(
                        leading: const Icon(FontAwesomeIcons.building,
                            color: Colors.green, size: 20),
                        title: const Text('Properties',
                            style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        childrenPadding: const EdgeInsets.only(left: 30),
                        children: [
                          _drawerTile(context, FontAwesomeIcons.building,
                              'Package Details', '/properties'),
                          _drawerTile(context, FontAwesomeIcons.bagShopping,
                              'Ordered Properties', '/ordered_properties'),
                        ],
                      ),

                      ExpansionTile(
                        leading: const Icon(FontAwesomeIcons.box,
                            color: Colors.green, size: 20),
                        title: const Text('Products',
                            style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        childrenPadding: const EdgeInsets.only(left: 30),
                        children: [
                          _drawerTile(context, FontAwesomeIcons.box, 'All Products',
                              '/products'),
                          _drawerTile(context, FontAwesomeIcons.cartShopping, 'My Cart',
                              '/cart'),
                          _drawerTile(context, FontAwesomeIcons.boxOpen, 'My Orders',
                              '/myorders'),
                          _drawerTile(context, FontAwesomeIcons.truck, 'Track My Orders',
                              '/track_orders'),
                        ],
                      ),

                      _drawerTile(context, FontAwesomeIcons.user, 'Profile', '/profile'),

                      ExpansionTile(
                        leading: const Icon(FontAwesomeIcons.certificate,
                            color: Colors.green, size: 20),
                        title: const Text('Certification',
                            style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        childrenPadding: const EdgeInsets.only(left: 30),
                        children: [
                          _drawerTile(context, FontAwesomeIcons.fileLines,
                              'TAX Certificate', '/tax_certificate'),
                          _drawerTile(context, FontAwesomeIcons.coins,
                              'Investment Certificate', '/project_certificate'),
                        ],
                      ),

                      _drawerTile(context, FontAwesomeIcons.circleInfo, 'About Us',
                          '/about_us'),
                      _drawerTile(context, FontAwesomeIcons.newspaper, 'News', '/news'),
                      _drawerTile(context, FontAwesomeIcons.blog, 'Blog', '/blogs'),

                      const Divider(height: 20, thickness: 1, color: Colors.green),

                      // ---------------- LOGOUT ----------------
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: CustomButton(
                          text: "Logout",
                          icon: Icons.logout,
                          onPressed: () async {
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Logout'),
                                content: const Text('Are you sure you want to logout?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (shouldLogout == true) {
                              await _logout();
                            }
                          },
                          backgroundColor: Colors.red, // 🔴 same red as before
                          textColor: Colors.white,
                          height: 45, // ✅ same as previous ElevatedButton
                          borderRadius: 10, // ✅ match your logout shape
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          horizontalPadding: 16,
                          verticalPadding: 0,
                          useExtraRoundedCorners: false,
                          isRound: false,
                        ),
                      ),

                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _bottomNavIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    try {
      final url = Uri.parse(ApiConstants.logout);
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {'investor_code': investorCode},
      );

      if (response.statusCode == 200) {
        // Logout successful
        await prefs.clear();

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, 'login');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout successful'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed. Please try again'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<Map<String, dynamic>> getInvestorProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString('investor_name') ?? 'N/A',
      'email': prefs.getString('investor_email') ?? 'N/A',
      'phone': prefs.getString('investor_phone') ?? 'N/A',
      'code': prefs.getString('investor_code') ?? 'N/A', // fix here
      'image': prefs.getString('investor_image') ?? '',
    };
  }

  Future<void> fetchAndSaveInvestorProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    debugPrint('Token: $token');
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.investorProfile(investorCode));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final data = jsonData['data']['investor'];

      await prefs.setString('investor_name', data['name'] ?? '');
      await prefs.setString('investor_email', data['email'] ?? '');
      await prefs.setString('investor_phone', data['phone'] ?? '');
      await prefs.setString('investor_code', data['investor_code'] ?? '');
      await prefs.setString('investor_image', data['image'] ?? '');

      prefs.setString(
        'wallet_balance',
        jsonData['data']['wallet_balance'].toString(),
      );
      //prefs.setString('total_transation', jsonData['data']['total_transation'].toString());
      prefs.setString(
        'total_investment',
        jsonData['data']['total_investment'].toString(),
      );
      prefs.setString(
        'total_income',
        jsonData['data']['total_income'].toString(),
      );
      prefs.setString(
        'todays_income',
        jsonData['data']['todays_income'].toString(),
      );
      prefs.setString(
        'total_projects',
        jsonData['data']['total_projects'].toString(),
      );
    } else {
      debugPrint('Failed to fetch profile: ${response.statusCode}');
    }
  }

  Widget _drawerTile(
      BuildContext context,
      IconData icon,
      String title,
      String route,
      ) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: const VisualDensity(vertical: -4),
      leading: Icon(icon, color: Colors.green, size: 16),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      onTap: () {
        Navigator.pop(context); // close the drawer
        Future.delayed(const Duration(milliseconds: 250), () {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pushNamed(route);
          }
        });
      },
    );
  }

}
