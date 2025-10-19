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
          ),
          title: Text('Wallet'),
          childrenPadding: EdgeInsets.only(
            left: 40,
          ), // Add left space for all children
          children: <Widget>[
            ListTile(
              leading: Icon(
                FontAwesomeIcons.wallet,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('My Wallet'),
              // onTap: () {
              //   Navigator.pop(
              //     context,
              //   ); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) =>
              //           const WalletHistoryPage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/wallet'),
            ),


            ListTile(
              leading: Icon(
                FontAwesomeIcons.moneyCheck,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Deposit'),
              // onTap: () {
              //   Navigator.pop(
              //     context,
              //   ); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => const DepositPage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/deposit'),
            ),

            ListTile(
              leading: Icon(
                FontAwesomeIcons.arrowDown,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Withdraw'),
              // onTap: () {
              //   Navigator.pop(
              //     context,
              //   ); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => const WithdrawPage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/withdraw'),
            ),
          ],
        ),
        //GrowUp
        ExpansionTile(
          leading: Icon(FontAwesomeIcons.seedling, color: Colors.green),
          title: Text('Growup'),
          childrenPadding: EdgeInsets.only(
            left: 40,
          ), // Add left space for all children
          children: <Widget>[
            ListTile(
              leading: Icon(
                FontAwesomeIcons.folderOpen,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Projects'),
              // onTap: () {
              //   Navigator.pop(
              //     context,
              //   ); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => const AllProjectsPage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/projects'),
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.projectDiagram,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Invested Projects'),
              // onTap: () {
              //   Navigator.pop(
              //     context,
              //   ); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => const MyProjectsPage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/myprojects'),
            ),
          ],
        ),

        // Invoices
        ExpansionTile(
          leading: Icon(FontAwesomeIcons.fileInvoiceDollar, color: Colors.green),
          title: Text('Invoices'),
          childrenPadding: EdgeInsets.only(
            left: 40,
          ), // Add left space for all children
          children: <Widget>[
            ListTile(
              leading: Icon(
                FontAwesomeIcons.fileInvoice,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Growup'),
              // onTap: () {
              //   Navigator.pop(context); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => const InvoiceGrowupPage()),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/invoice_growup'),
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.warehouse,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Property'),
              onTap: () {
                // Navigator.pop(context); // Close the drawer or dialog if needed
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const DepositPage()),
                // );
              },
            ),

            ListTile(
              leading: Icon(
                FontAwesomeIcons.fileInvoiceDollar,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Recharge'),
              // onTap: () {
              //   Navigator.pop(context); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => const InvoiceRechargePage()),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/invoice_recharge'),
            ),

            ListTile(
              leading: Icon(
                FontAwesomeIcons.coins,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('ROI'),
              // onTap: () {
              //   Navigator.pop(context); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => const InvoiceRoiPage()),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/invoice_roi'),
            ),

            ListTile(
              leading: Icon(
                FontAwesomeIcons.handHoldingDollar,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Capital Return'),
              // onTap: () {
              //   Navigator.pop(context); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => const CapitalReturnPage()),
              //   );
              // },
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

        //Properties
        ExpansionTile(
          leading: Icon(FontAwesomeIcons.building, color: Colors.green),
          title: Text('Properties'),
          childrenPadding: EdgeInsets.only(
            left: 40,
          ), // Add left space for all children
          children: <Widget>[
            ListTile(
              leading: Icon(
                FontAwesomeIcons.building,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Package Details'),
              // onTap: () {
              //   Navigator.pop(context); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => const AllPropertiesPage()),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/properties'),
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.shoppingBag,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Ordered Properties'),
              onTap: () {
                // Navigator.pop(context); // Close the drawer or dialog if needed
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const MyProjectsPage()),
                // );
              },
            ),
          ],
        ),
        // Products
        ExpansionTile(
          leading: Icon(FontAwesomeIcons.box, color: Colors.green),
          title: Text('Products'),
          childrenPadding: EdgeInsets.only(
            left: 40,
          ), // Add left space for all children
          children: <Widget>[
            ListTile(
              leading: Icon(
                FontAwesomeIcons.box,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('All Products'),
              // onTap: () {
              //   Navigator.pop(
              //     context,
              //   ); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => const AllProductsPage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/products'),
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.shoppingCart,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('My Cart'),
              onTap: () {
                // Navigator.pop(context); // Close the drawer or dialog if needed
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const DepositPage()),
                // );
              },
            ),

            ListTile(
              leading: Icon(
                FontAwesomeIcons.boxOpen ,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('My Orders'),
              // onTap: () {
              //   Navigator.pop(context); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => const MyOrdersPage()),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/myorders'),
            ),

            ListTile(
              leading: Icon(
                FontAwesomeIcons.truck,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Track My Orders'),
              onTap: () {
                // Navigator.pop(context); // Close the drawer or dialog if needed
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const WithdrawPage()),
                // );
              },
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
          leading: Icon(FontAwesomeIcons.certificate, color: Colors.green),
          title: Text('Certification'),
          childrenPadding: EdgeInsets.only(
            left: 40,
          ), // Add left space for all children
          children: <Widget>[
            ListTile(
              leading: Icon(
                FontAwesomeIcons.fileAlt,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('TAX Certificate'),
              // onTap: () {
              //   Navigator.pop(
              //     context,
              //   ); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => const TaxCertificatePage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/tax_certificate'),
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.coins,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Investment Certificate'),
              // onTap: () {
              //   Navigator.pop(
              //     context,
              //   ); // Close the drawer or dialog if needed
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => const ProjectCertificatePage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/project_certificate'),
            ),
          ],
        ),
        ExpansionTile(
          leading: Icon(FontAwesomeIcons.infoCircle, color: Colors.green),
          title: Text('About'),
          childrenPadding: EdgeInsets.only(
            left: 40,
          ), // Add left space for all children
          children: <Widget>[
            ListTile(
              leading: Icon(
                FontAwesomeIcons.infoCircle ,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('About Us'),
              // onTap: () {
              //   Navigator.pop(context); // close drawer first
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => const AboutUsPage(),
              //     ),
              //   );
              // },
              onTap: () => Navigator.pushNamed(context, '/about_us'),
            ),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.fileAlt,
                size: 28,
                color: Colors.green,
              ), // Bullet point
              title: Text('Certificates'),
              // onTap: () {
                // Navigator.pop(context); // Close the drawer or dialog if needed
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const CertificateWebViewPage()),
                // );

              // },
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
          leading: const Icon(FontAwesomeIcons.rightFromBracket, color: Colors.green),
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
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      onTap: () {
        //Navigator.pop(context); // Close drawer
        Navigator.pushNamed(context, route); // Use named routes or replace with MaterialPageRoute
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
