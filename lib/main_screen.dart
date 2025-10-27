import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/IntroPage.dart';
import 'package:growup_agro/views/ProfilePage.dart';
import 'package:growup_agro/views/all_products_page.dart';
import 'package:growup_agro/views/all_projects.dart';
import 'package:growup_agro/views/all_properties.dart';
import 'package:growup_agro/views/certificates_web.dart';
import 'package:growup_agro/views/desposit_page.dart';
import 'package:growup_agro/views/investment_history.dart';
import 'package:growup_agro/views/investor_dashboard.dart';
import 'package:growup_agro/views/invoice_capital_return.dart';
import 'package:growup_agro/views/invoice_growup.dart';
import 'package:growup_agro/views/invoice_recharge.dart';
import 'package:growup_agro/views/invoice_roi.dart';
import 'package:growup_agro/views/my_orders_page.dart';
import 'package:growup_agro/views/my_projects.dart';
import 'package:growup_agro/views/project_certificate_page.dart';
import 'package:growup_agro/views/live.dart';
import 'package:growup_agro/views/tax_certificate.dart';
import 'package:growup_agro/views/wallet_history.dart';
import 'package:growup_agro/views/withdraw_page.dart';
import 'package:growup_agro/widgets/bottom_nav_bar.dart';
import 'package:growup_agro/widgets/webview_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:growup_agro/views/about_us_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;
  int _bottomNavIndex = 2;
  late Future<Map<String, dynamic>> _profileFuture;

  final List<Widget> _pages = const [
    AllProjectsPage(), //index 0
    AllProjectsPage(),
    DashboardInvestor(),
    AllProductsPage(),
    AllPropertiesPage(),
    // MyProjectsPage(), //index 4
    // WebTabPage(),//index
    // WalletHistoryPage(),
    // DepositPage(),
    // InvestorProfilePage(),
  ];

  // Add this method here inside the class:
  void _selectPageFromDrawer(int index) {
    Navigator.of(context).pop(); // close drawer
    setState(() {
      _selectedIndex = index; // update the selected page
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() {
        _bottomNavIndex = index;
        _selectedIndex = index; // they match only for nav bar items
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.logout); // use ApiConstants

    // final url = Uri.parse(
    //   'https://growupagro.tech/api/investor/logout',
    // );

    try {
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

  // Future<void> _logoutAndGoToIntro() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('username');
  //   await prefs.remove('password');
  //
  //   Navigator.of(context).pushAndRemoveUntil(
  //     MaterialPageRoute(builder: (_) => const IntroPage()),
  //         (route) => false,
  //   );
  // }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        backgroundColor: const Color(0xFFFFFFFF), // your desired background color here
    child: ListView(

      padding: const EdgeInsets.only(top: 54, left: 0, right: 0, bottom: 0), // Add top padding
      children: [
        // Align(
        //   alignment: Alignment.topLeft,
        //   child: IconButton(
        //     icon: const Icon(
        //       Icons.close,
        //       color: Colors.red,
        //       size: 30, // Bigger size than default (default is 24)
        //     ),
        //     tooltip: 'Close Drawer',
        //     onPressed: () {
        //       Navigator.of(context).pop(); // Close the drawer
        //     },
        //   ),
        // ),

        // _buildDrawerItem(
        //   Icons.dashboard_customize,
        //   'Dashboard',
        //   context,
        //   '/dashboard',
        //
        // ),


        // _buildDrawerItem(
        //   FontAwesomeIcons.tachometerAlt, // <-- just the icon data
        //   'Dashboard',
        //   context,
        //   '/dashboard',
        // ),

        //Wallet
        ExpansionTile(
          leading: Icon(
            FontAwesomeIcons.wallet,
            color: Colors.green,
            size: 20,
          ),
          title: Text(
            'Wallet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 30, top: 0, bottom: 0), // remove top/bottom padding
          dense: true,
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
              visualDensity: const VisualDensity(vertical: -4), // reduce vertical space
              leading: Icon(
                FontAwesomeIcons.wallet,
                size: 16,
                color: Colors.green,
              ),
              title: Text(
                'My Wallet',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () => Navigator.pushNamed(context, '/wallet'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/deposit'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/withdraw'),
            ),
          ],
        ),



        //GrowUp
        ExpansionTile(
          leading: Icon(
            FontAwesomeIcons.seedling,
            color: Colors.green,
            size: 20, // smaller main icon
          ),
          title: Text(
            'Growup',
            style: TextStyle(
              fontSize: 14, // smaller text
              fontWeight: FontWeight.w500,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 30, top: 0, bottom: 0), // reduce top/bottom gap
          dense: true,
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
              visualDensity: const VisualDensity(vertical: -4), // reduce vertical space
              leading: Icon(
                FontAwesomeIcons.folderOpen,
                size: 16, // smaller bullet icon
                color: Colors.green,
              ),
              title: Text(
                'Projects',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () => Navigator.pushNamed(context, '/projects'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/myprojects'),
            ),
          ],
        ),


        // Invoices
        ExpansionTile(
          leading: Icon(
            FontAwesomeIcons.fileInvoiceDollar,
            color: Colors.green,
            size: 20, // smaller main icon
          ),
          title: Text(
            'Invoices',
            style: TextStyle(
              fontSize: 14, // smaller text
              fontWeight: FontWeight.w500,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 30, top: 0, bottom: 0), // reduce top/bottom gap
          dense: true,
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/invoice_growup'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/invoice_recharge'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
              visualDensity: const VisualDensity(vertical: -4),
              leading: Icon(
                FontAwesomeIcons.coins,
                size: 16,
                color: Colors.green,
              ),
              title: Text(
                'ROI',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () => Navigator.pushNamed(context, '/invoice_roi'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/capital_return'),
            ),
          ],
        ),


        // _buildDrawerItem(Icons.work_outline, 'Projects', context, '/projects'),
        // _buildDrawerItem(Icons.account_balance_wallet, 'My Projects', context, '/myprojects'),
        _buildDrawerItem(
          FontAwesomeIcons.history,
          'Investment History',
          context,
          '/investmenthistory',
        ),

        // Properties
        ExpansionTile(
          leading: Icon(
            FontAwesomeIcons.building,
            color: Colors.green,
            size: 20,
          ),
          title: Text(
            'Properties',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 30, top: 0, bottom: 0),
          dense: true,
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/properties'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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

// Products
        ExpansionTile(
          leading: Icon(
            FontAwesomeIcons.box,
            color: Colors.green,
            size: 20,
          ),
          title: Text(
            'Products',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 30, top: 0, bottom: 0),
          dense: true,
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/products'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/myorders'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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


        //_buildDrawerItem(Icons.account_balance_wallet_outlined, 'Wallet', context, '/Wallet'),
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
            size: 20,
          ),
          title: Text(
            'Certification',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 30, top: 0, bottom: 0),
          dense: true,
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/tax_certificate'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
              onTap: () => Navigator.pushNamed(context, '/project_certificate'),
            ),
          ],
        ),

        ExpansionTile(
          leading: Icon(
            FontAwesomeIcons.infoCircle,
            color: Colors.green,
            size: 20,
          ),
          title: Text(
            'About',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 30, top: 0, bottom: 0),
          dense: true,
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
              visualDensity: const VisualDensity(vertical: -4),
              leading: Icon(
                FontAwesomeIcons.infoCircle,
                size: 16,
                color: Colors.green,
              ),
              title: Text(
                'About Us',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () => Navigator.pushNamed(context, '/about_us'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
              visualDensity: const VisualDensity(vertical: -4),
              leading: Icon(
                FontAwesomeIcons.fileAlt,
                size: 16,
                color: Colors.green,
              ),
              title: Text(
                'Certificates',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () => Navigator.pushNamed(context, '/certificate'),
            ),
          ],
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
          dense: true, // makes the tile vertically smaller
          contentPadding: const EdgeInsets.symmetric(horizontal: 16), // reduce horizontal padding
          visualDensity: const VisualDensity(vertical: -4), // reduce vertical spacing
          leading: const Icon(
            FontAwesomeIcons.rightFromBracket,
            color: Colors.green,
            size: 16, // smaller icon
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500, // smaller text
            ),
          ),
          onTap: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false), // Cancel
                    child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true), // Confirm
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (shouldLogout == true) {
              await _logout(); // Handle API + navigation
            }
          },
        ),

      ],
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

  // Sample drawer item builder
  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, String route) {
    return ListTile(
      dense: true, // makes the tile vertically smaller
      contentPadding: const EdgeInsets.symmetric(horizontal: 16), // reduce left/right padding
      visualDensity: const VisualDensity(vertical: -4), // shrink vertical space
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




  // Dummy profile fetcher - replace with your real implementation
  Future<Map<String, dynamic>> fetchInvestorProfile() async {
    await Future.delayed(const Duration(seconds: 1));
    return {'name': 'Investor'};
  }

  // Future<void> _logout() async {
  //   // Your logout logic
  //   Navigator.pushReplacementNamed(context, '/login');
  // }
}
