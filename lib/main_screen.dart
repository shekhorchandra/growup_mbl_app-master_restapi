import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/all_products_page.dart';
import 'package:growup_agro/views/all_projects.dart';
import 'package:growup_agro/views/all_properties.dart';
import 'package:growup_agro/views/investor_dashboard.dart';
import 'package:growup_agro/widgets/bottom_nav_bar.dart';
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
                      UserAccountsDrawerHeader(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                        ),
                        margin: EdgeInsets.zero,
                        accountName: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              profile['name'] ?? 'No Name',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 16), // minimal space
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/myprofile');
                              },
                              child: Image.asset(
                                'assets/icons/edit.png',
                                width: 24,
                                height: 24,
                                color: Colors.white,
                                // Optional: apply color filter
                              ),
                            ),
                          ],
                        ),
                        accountEmail: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${profile['code']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        currentAccountPicture: CircleAvatar(
                          backgroundImage:
                          profile['image'] != null &&
                              profile['image'].toString().isNotEmpty
                              ? NetworkImage(
                            "${ApiConstants.imgBaseUrl}/storage/${profile['image']}",
                          )
                              : const AssetImage('assets/images/img.png')
                          as ImageProvider,
                        ),
                      ),

                      _buildDrawerItem(
                        FontAwesomeIcons
                            .tachometerAlt, // <-- just the icon data
                        'Dashboard',
                        context,
                        '/dashboard',
                      ),

                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.wallet,
                          color: Colors.green,
                          size: 20, // smaller main icon
                        ),
                        title: Text(
                          'Wallet',
                          style: TextStyle(
                            fontSize: 14, // smaller text
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.only(
                          left: 30,
                          top: 0,
                          bottom: 0,
                        ),
                        // remove top/bottom padding
                        dense: true,
                        children: <Widget>[
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            // compact vertical space
                            leading: Icon(
                              FontAwesomeIcons.wallet,
                              size: 16, // smaller child icon
                              color: Colors.green,
                            ),
                            title: Text(
                              'My Wallet',
                              style: TextStyle(
                                fontSize: 13,
                              ), // smaller child text
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/wallet'),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.moneyCheck,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Deposit',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/deposit'),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.arrowDown,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Withdraw',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/withdraw'),
                          ),
                        ],
                      ),

                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.seedling,
                          color: Colors.green,
                          size: 20, // smaller main icon
                        ),
                        title: Text(
                          'Growup',
                          style: TextStyle(
                            fontSize: 14, // smaller main text
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.only(
                          left: 30,
                          top: 0,
                          bottom: 0,
                        ),
                        dense: true,
                        children: <Widget>[
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.folderOpen,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Projects',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/projects'),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.projectDiagram,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Invested Projects',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/myprojects'),
                          ),
                        ],
                      ),

                      //invoice
                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.fileInvoiceDollar,
                          color: Colors.green,
                          size: 20, // main icon size
                        ),
                        title: Text(
                          'Invoices',
                          style: TextStyle(
                            fontSize: 14, // main title size
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.only(
                          left: 30,
                          top: 0,
                          bottom: 0,
                        ),
                        // compact padding
                        dense: true,
                        children: <Widget>[
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.fileInvoice,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Growup',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/invoice_growup'),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.warehouse,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Property',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () {},
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.fileInvoiceDollar,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Recharge',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/invoice_recharge',
                            ),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.coins,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text('ROI', style: TextStyle(fontSize: 13)),
                            onTap: () =>
                                Navigator.pushNamed(context, '/invoice_roi'),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.handHoldingDollar,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Capital Return',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/capital_return'),
                          ),
                        ],
                      ),

                      _buildDrawerItem(
                        FontAwesomeIcons.history,
                        'Investment History',
                        context,
                        '/investmenthistory',
                      ),

                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.building,
                          color: Colors.green,
                          size: 20, // smaller main icon
                        ),
                        title: Text(
                          'Properties',
                          style: TextStyle(
                            fontSize: 14, // main text size
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.only(
                          left: 30,
                          top: 0,
                          bottom: 0,
                        ),
                        // compact padding
                        dense: true,
                        children: <Widget>[
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.building,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Package Details',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/properties'),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.shoppingBag,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Ordered Properties',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),

                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.box,
                          color: Colors.green,
                          size: 20, // main icon size
                        ),
                        title: Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 14, // main title text size
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.only(
                          left: 30,
                          top: 0,
                          bottom: 0,
                        ),
                        // compact padding
                        dense: true,
                        children: <Widget>[
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.box,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'All Products',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/products'),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.shoppingCart,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'My Cart',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () {},
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.boxOpen,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'My Orders',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/myorders'),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.truck,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Track My Orders',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),

                      _buildDrawerItem(
                        FontAwesomeIcons.user,
                        'Profile',
                        context,
                        '/profile',
                      ),

                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.certificate,
                          color: Colors.green,
                          size: 20, // main icon size
                        ),
                        title: Text(
                          'Certification',
                          style: TextStyle(
                            fontSize: 14, // main title size
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.only(
                          left: 30,
                          top: 0,
                          bottom: 0,
                        ),
                        // compact padding
                        dense: true,
                        children: <Widget>[
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.fileAlt,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'TAX Certificate',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/tax_certificate',
                            ),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            visualDensity: const VisualDensity(vertical: -4),
                            leading: Icon(
                              FontAwesomeIcons.coins,
                              size: 16,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Investment Certificate',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/project_certificate',
                            ),
                          ),
                        ],
                      ),

                      _buildDrawerItem(
                        FontAwesomeIcons.infoCircle,
                        'About Us',
                        context,
                        '/about_us',
                      ),

                      _buildDrawerItem(
                        FontAwesomeIcons.newspaper,
                        'News',
                        context,
                        '/news',
                      ),

                      _buildDrawerItem(
                        FontAwesomeIcons.blog,
                        'Blog',
                        context,
                        '/blogs',
                      ),

                      ListTile(
                        leading: const Icon(
                          FontAwesomeIcons.rightFromBracket,
                          color: Colors.green,
                        ),
                        title: const Text('Logout'),
                        onTap: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pop(false), // Cancel
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pop(true), // Confirm
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            await _logout(); // This handles API + navigation
                          }
                        },
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

  Widget _buildDrawerItem(
      IconData icon,
      String title,
      BuildContext context,
      String route,
      ) {
    return ListTile(
      dense: true,
      // makes the tile vertically smaller
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      // reduce left/right padding
      visualDensity: const VisualDensity(vertical: -4),
      // shrink vertical space
      leading: Icon(
        icon,
        color: Colors.green,
        size: 18, // smaller icon
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500, // smaller text
        ),
      ),
      onTap: () {
        Navigator.pushNamed(context, route); // navigate to route
      },
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
}
