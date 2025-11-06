import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:growup_agro/generated/assets.dart';
import 'package:growup_agro/models/live_project_model.dart';
import 'package:growup_agro/models/wallet_history_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/NotificationPage.dart';
import 'package:growup_agro/views/all_projects.dart';
import 'package:growup_agro/views/all_properties.dart';
import 'package:growup_agro/views/auto_slider_card.dart';
import 'package:growup_agro/views/commercial_city.dart';
import 'package:growup_agro/views/residencial_city_page.dart';
import 'package:growup_agro/views/rosa_health.dart';
import 'package:growup_agro/views/rosa_hitech.dart';
import 'package:growup_agro/views/royal_eco_city.dart';
import 'package:growup_agro/views/royal_eco_tourism.dart';
import 'package:growup_agro/views/royal_north_bengal_club.dart';
import 'package:growup_agro/views/royal_palace.dart';
import 'package:growup_agro/views/live.dart';
import 'package:growup_agro/views/short_duration.dart';
import 'package:growup_agro/views/wallet_history.dart';
import 'package:growup_agro/widgets/advertisement_slider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_properties.model.dart';
import '../widgets/achievement_card.dart';
import '../widgets/appbar_content.dart';
import '../widgets/category_item.dart';
import '../widgets/home_image_slider.dart';
import '../widgets/status_test.dart';
import '../widgets/summary_item.dart';
import 'IntroPage.dart';
import 'completed_projects.dart';
import 'long_duration.dart'; // For SystemNavigator.pop()
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DashboardInvestor(),
    );
  }
}

class DashboardInvestor extends StatefulWidget {
  const DashboardInvestor({super.key});

  @override
  State<DashboardInvestor> createState() => _DashboardInvestorState();
}

class _DashboardInvestorState extends State<DashboardInvestor> {
  int _selectedIndex = 0;
  double totalIncome = 0.0;
  double todaysIncome = 0.0;
  int totalProjects = 0;
  String totalwallet_balance = '0';
  String totalInvestment = '0';
  String _walletBalance = '0';
  int _loyaltyPoints = 78;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchKey = GlobalKey();

  List<String> imageUrls = [];
  bool isLoading = true;

  List<Map<String, dynamic>> _walletTransactions = [];
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    fetchSliderImages();

    // Initialize immediately to avoid LateInitializationError
    _profileFuture = getInvestorProfileFromPrefs();

    // Then refresh data in background
    fetchAndSaveInvestorProfile().then((_) {
      setState(() {
        _profileFuture = getInvestorProfileFromPrefs(); // Load fresh profile
      });
    });

    fetchWalletBalance().then((_) {
      _loadDashboardData();
    });

    fetchWalletHistory().then((list) {
      setState(() {
        _walletTransactions = list
            .map(
              (e) => {
                'type': e.type,
                'date': e.date,
                'amount': e.amount,
                'status': e.status ?? 'N/A',
                'trx_id': e.trxId,
              },
            )
            .toList();
      });
    });
  }

  //slider api
  Future<void> fetchSliderImages() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      debugPrint('Token not found');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse(ApiConstants.sliderImages());

    // final url = Uri.parse(
    //   'https://growupagro.tech/api/investor/sliders',
    // );

    try {
      // Send token in headers instead of query param
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Use Bearer token if API requires
          'Accept': 'application/json',
        },
      );

      // debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          // Use full URLs if API returns them, otherwise prepend domain
          final urls = List<String>.from(
            data['data'].map((item) {
              final image = item['image_url'] ?? '';
              if (image.startsWith('http')) {
                return image;
              } else {
                return 'https://growupagro.tech$image';
              }
            }),
          );

          debugPrint('Extracted URLs: $urls');

          setState(() {
            imageUrls = urls;
            isLoading = false;
          });
        } else {
          debugPrint('API returned failure status or empty data');
          setState(() {
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized: Invalid or expired token');
        setState(() {
          isLoading = false;
        });
      } else {
        debugPrint(
          'Failed to fetch slider images. Status code: ${response.statusCode}',
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching slider images: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAndSaveInvestorProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    debugPrint('Token: $token');
    final investorCode = prefs.getString('investor_code') ?? '';

    // final response = await http.get(
    //   Uri.parse(
    //     'https://admin-growup.onebitstore.site/api/investor/profile?investor_code=$investorCode',
    //   ),
    //   headers: {
    //     'Authorization': 'Bearer $token',
    //     'Content-Type': 'application/json',
    //   },
    // );
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

  //wallet balance
  Future<void> fetchWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    try {
      final url = Uri.parse(ApiConstants.investorProfile(investorCode));
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final balanceRaw =
            jsonData['data']['investor']['wallet']['balance'] ?? '0';
        final parsedBalance = double.tryParse(balanceRaw.toString()) ?? 0.0;

        // Save raw value (without formatting) for calculations if needed
        await prefs.setString('wallet_balance_raw', parsedBalance.toString());

        final formattedBalance = NumberFormat('#,##0.00').format(parsedBalance);

        // Save formatted version for UI
        await prefs.setString('wallet_balance', formattedBalance);

        if (mounted) {
          setState(() {
            _walletBalance = formattedBalance;
          });
        }
      } else {
        print(
          "Failed to fetch wallet balance, status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error fetching wallet balance: $e");
    }
  }

  //counter
  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      totalwallet_balance = prefs.getString('wallet_balance') ?? '0';
      totalInvestment = prefs.getString('total_investment') ?? '0';
      totalIncome =
          double.tryParse(prefs.getString('total_income') ?? '0') ?? 0.0;
      todaysIncome =
          double.tryParse(prefs.getString('todays_income') ?? '0') ?? 0.0;
      totalProjects =
          int.tryParse(prefs.getString('total_projects') ?? '0') ?? 0;
      print(
        'Updated: $totalwallet_balance, $totalInvestment, $totalIncome, $todaysIncome, $totalProjects',
      );
    });
  }

  //fetchUserName() function
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

  Future<AllPropertiesResponse> fetchProperties() async {
    final response = await http.get(Uri.parse(ApiConstants.allProperties));

    if (response.statusCode == 200) {
      return AllPropertiesResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load properties");
    }
  }

  //transaction
  Future<List<WalletHistoryModel>> fetchWalletHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final investorCode = prefs.getString('investor_code');

    final url = Uri.parse(ApiConstants.walletHistory(investorCode!));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => WalletHistoryModel.fromJson(item))
            .toList();
      } else {
        throw Exception('No wallet history found');
      }
    } else {
      throw Exception('Failed to load wallet history');
    }
  }

  // transaction end

  //Projects you may invest start
  Future<List<LiveProject>> fetchShariahProjects() async {
    final url = Uri.parse(ApiConstants.allProjects());
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No auth token found. Please login again.');
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['projects'] == null ||
            jsonData['projects']['Live Projects'] == null) {
          throw Exception('Live Projects section missing in API response.');
        }

        final List<dynamic> shariahProjects =
            jsonData['projects']['Live Projects'];

        return shariahProjects
            .map((json) => LiveProject.fromJson(json))
            .take(3)
            .toList();
      } else {
        throw Exception(
          'Failed to load Live Projects - status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Exception in fetchLive Projects(): $e');
      throw Exception('Failed to load Live Projects');
    }
  }

  //Projects you may invest end

  // by default back button
  Future<void> _logoutAndGoToIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const IntroPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // by default back button
    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Exit'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          await _logoutAndGoToIntro();
          return false; // Prevents default pop
        }
        return false; // Cancel back navigation
      },
      child: Scaffold(
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
                              // const SizedBox(width: 16), // minimal space
                              // GestureDetector(
                              //   onTap: () {
                              //     Navigator.pushNamed(context, '/myprofile');
                              //   },
                              //   child: Image.asset(
                              //     'assets/icons/edit.png',
                              //     width: 24,
                              //     height: 24,
                              //     color: Colors.white,
                              //     // Optional: apply color filter
                              //   ),
                              // ),
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
                              const SizedBox(width: 16),
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
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
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
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
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
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
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
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/invoice_growup',
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
                              title: Text(
                                'ROI',
                                style: TextStyle(fontSize: 13),
                              ),
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
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/capital_return',
                              ),
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
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
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
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
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
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
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

                        const Divider(height: 50),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () async {
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Logout'),
                                    content: const Text(
                                      'Are you sure you want to logout?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
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
                            ),
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

        backgroundColor: Colors.white,

        appBar: _selectedIndex == 4
            ? null
            : AppBar(
                backgroundColor: const Color(0xFF2E7D32),
                centerTitle: true,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                toolbarHeight: 60,
                elevation: 0,

                // Drawer avatar at the left
                leading: Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => {Scaffold.of(context).openEndDrawer()},
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 16),
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          Widget avatar;

                          if (!snapshot.hasData) {
                            avatar = ClipOval(
                              child: Image.asset(
                                'assets/images/img.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            final profile = snapshot.data!;

                            final imageUrl =
                                profile['image'] != null &&
                                    profile['image'].toString().isNotEmpty
                                ? ApiConstants.getImageUrl(profile['image'])
                                : null;

                            avatar = ClipOval(
                              child: Image(
                                image: imageUrl != null
                                    ? NetworkImage(imageUrl)
                                    : const AssetImage('assets/images/img.png')
                                          as ImageProvider,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          }

                          return Transform.translate(
                            offset: const Offset(0, 2),
                            child: AspectRatio(
                              aspectRatio:
                                  1, // Ensure the widget is always square
                              child: avatar,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Main content (name + balance)
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Search...",
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          // Handle search here
                          print("Searching: $value");
                        },
                      )
                    : AppbarContent(
                        profileFuture: _profileFuture,
                        loyaltyPoints: _loyaltyPoints,
                        walletBalance: _walletBalance,
                      ),

                // Notification bell on the right

                // Normal title
                actions: [
                  // Search Icon
                  IconButton(
                    key: _searchKey,
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      final RenderBox renderBox =
                          _searchKey.currentContext!.findRenderObject()
                              as RenderBox;
                      final Offset position = renderBox.localToGlobal(
                        Offset.zero,
                      );

                      // Move bar upward (subtract 10 px for example)
                      final double popupTop =
                          position.dy + renderBox.size.height - 30;

                      showDialog(
                        context: context,
                        barrierColor: Colors.transparent, // no dark overlay
                        builder: (context) {
                          return Stack(
                            children: [
                              Positioned(
                                top: popupTop,
                                left: 0,
                                right: 0,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ), // white shadow
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Search...',
                                          prefixIcon: const Icon(Icons.search),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // Notification Bell
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 0), // optional spacing at the end
                ],
              ),

        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Insert your image carousel here
                // Inside your Column or wherever you are adding the slider
                if (isLoading)
                  const SizedBox(
                    // height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (imageUrls.isEmpty)
                  const SizedBox(
                    // height: 220,
                    child: Center(child: Text('No images available')),
                  )
                else
                  HomeImageSlider(imageUrls: imageUrls),

                DashboardSummaryCard(
                  bgColor: Color(0xFFF1FBF1),
                  items: [
                    SummaryItem(
                      icon: SvgPicture.asset(
                        Assets.iconsTotalInvestment,
                        colorFilter: const ColorFilter.mode(
                          Colors.green,
                          BlendMode.srcIn,
                        ),
                      ),
                      value: totalInvestment.toString(),
                      label: 'Total Investment',
                    ),
                    SummaryItem(
                      icon: SvgPicture.asset(
                        Assets.iconsTotalIncome,
                        colorFilter: const ColorFilter.mode(
                          Colors.green,
                          BlendMode.srcIn,
                        ),
                      ),
                      value: totalIncome.toString(),
                      label: 'Total Income',
                    ),
                    SummaryItem(
                      icon: SvgPicture.asset(
                        Assets.iconsTodaysIncome,
                        colorFilter: const ColorFilter.mode(
                          Colors.green,
                          BlendMode.srcIn,
                        ),
                      ),
                      value: todaysIncome.toString(),
                      label: "Today's Income",
                    ),
                  ],
                ),

                SizedBox(height: 8),

                DashboardSummaryCard(
                  bgColor: Color(0xFFF1FBF1),
                  items: [
                    SummaryItem(
                      icon: SvgPicture.asset(
                        Assets.iconsTodaysIncome,
                        colorFilter: const ColorFilter.mode(
                          Colors.green,
                          BlendMode.srcIn,
                        ),
                      ),
                      value: totalProjects.toString(),
                      label: 'My Grow Up Projects',
                    ),
                    SummaryItem(
                      icon: SvgPicture.asset(
                        Assets.iconsGrowUpPropertis,
                        colorFilter: const ColorFilter.mode(
                          Colors.green,
                          BlendMode.srcIn,
                        ),
                      ),
                      value: '0',
                      label: 'Ordered Properties',
                    ),
                  ],
                ),

                SizedBox(height: 8),

                const CertificationsSection(),

                // SizedBox(height: 8,),

                // The single container holding all four counter items.
                // The new parent Container adds the margin.
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 14),
                  child: Text(
                    "ACHIEVEMENT",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 8),

                AchievementCard(),

                SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/images/GrowupLogo.png',
                                  width: 70,
                                ),
                                // const SizedBox(height: 2), // smaller gap (can make 0 or remove)
                                const Text(
                                  "INVESTMENT BY CATEGORY",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                    height:
                                        1.0, //  tighten line height slightly
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                              ), // adjust value as needed
                              child: Image.asset(
                                'assets/icons/Shariah.png',
                                width: 70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // First row (3 cards)
                            CategoryGridCard(
                              minCrossAxisCount: 3,
                              maxCrossAxisCount: 3,
                              aspectRatio: 1.6,
                              //  same ratio for consistent height
                              items: [
                                CategoryItem(
                                  icon: SvgPicture.asset(
                                    Assets.iconsLiveProject,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.green,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  title: 'Live Projects',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LiveProjectsPage(),
                                      ),
                                    );
                                  },
                                ),
                                CategoryItem(
                                  icon: SvgPicture.asset(
                                    Assets.iconsTotalInvestment,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.green,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  title: 'Long Duration',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LongProjectsPage(),
                                      ),
                                    );
                                  },
                                ),
                                CategoryItem(
                                  icon: SvgPicture.asset(
                                    Assets.iconsSort,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.green,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  title: 'Short Duration',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ShortProjectsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // ✅ Second row (2 cards, same height as first row)
                            CategoryGridCard(
                              minCrossAxisCount: 2,
                              maxCrossAxisCount: 2,
                              aspectRatio: 2.5, //  same as above
                              items: [
                                CategoryItem(
                                  icon: SvgPicture.asset(
                                    Assets.iconsMach,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.green,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  title: 'Matured Projects',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CompletedProjectsPage(),
                                      ),
                                    );
                                  },
                                ),
                                CategoryItem(
                                  icon: SvgPicture.asset(
                                    Assets.iconsEarning,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.green,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  title: 'All GrowUp Projects',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AllProjectsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Projects you may invest
                Padding(
                  padding: const EdgeInsets.only(
                    top: 0,
                    bottom: 10,
                    left: 8,
                    right: 8,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // shrink to fit
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: const Text(
                                'PROJECTS YOU MAY INVEST',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AllProjectsPage(),
                                  ),
                                );
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    'See All',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // const Divider(thickness: 1.2),
                        FutureBuilder<List<LiveProject>>(
                          future: fetchShariahProjects(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('No projects available.'),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text('No projects available.'),
                              );
                            }

                            final projects = snapshot.data!;
                            // Use CarouselSlider instead of SingleChildScrollView + Row
                            return SizedBox(
                              height: 180,
                              child: CarouselSlider(
                                options: CarouselOptions(
                                  height:
                                      MediaQuery.of(context).size.height * 0.20,
                                  autoPlay: true,
                                  autoPlayInterval: const Duration(seconds: 5),
                                  enlargeCenterPage: true,
                                  viewportFraction: 1.0,
                                  enableInfiniteScroll: true,
                                ),
                                items: projects.map((project) {
                                  return Builder(
                                    builder: (BuildContext context) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFF2E7D32),
                                            // deep green border
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: _buildProjectCard(
                                          context: context,
                                          imageUrl: project.imageUrl ?? '',
                                          projectId:
                                              project.id?.toString() ?? '',
                                          name: project.projectName ?? 'N/A',
                                          type:
                                              project.investmentType_name ??
                                              "N/A",
                                          goal:
                                              '${project.investmentGoal ?? '0'} Tk',
                                          duration:
                                              project.project_duration_viewer ??
                                              'N/A',
                                          minInvestment:
                                              '${project.min_investment_amount ?? '0'} Tk',
                                          time:
                                              '${project.remaining_opportunity_days ?? 0} Days',
                                          roi: '${project.annualRoi ?? 0}%',
                                          isTablet:
                                              MediaQuery.of(
                                                context,
                                              ).size.width >=
                                              600,
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Properties Investment by category
                // Padding(
                //   padding: const EdgeInsets.only(left: 16, top: 16),
                //   child: Text(
                //     "INVESTMENT BY CATEGORY",
                //     style: TextStyle(
                //       fontSize: 14,
                //       color: Color(0xFF2E7D32),
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 8),
                Container(
                  // CHANGED: Set the color to transparent to remove the white background
                  color: Colors.green.withValues(alpha: .03),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with static icon on the right
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // CHANGED: Wrapped the Text widget in a Container for highlighting
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors
                                          .green
                                          .shade100, // The highlight color
                                      borderRadius: BorderRadius.circular(
                                        4,
                                      ), // Soft, rounded corners
                                    ),
                                    child: const Text(
                                      'PROPERTIES',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'INVESTMENT BY CATEGORY',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Image.asset(
                                'assets/icons/Secure.png',
                                width: 60,
                                height: 60,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // This is the section with your buttons, it remains unchanged.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildCategoryButton6(
                                      'Residential ',
                                      FontAwesomeIcons.city,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCategoryButton7(
                                      'Commercial ',
                                      FontAwesomeIcons.handshake,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Row 3: ROSA HiTech City + ROSA Health (No change)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCategoryButton8(
                                      'ROSA HiTech City',
                                      FontAwesomeIcons.microchip,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCategoryButton9(
                                      'ROSA Health',
                                      FontAwesomeIcons.heartbeat,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // --- NEW SECTION FOR THE ROYAL CLUB AND ITS CHILDREN ---
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 1. The Parent Button (remains the same)
                                  _buildCategoryButton20(
                                    'The Royal Eco City',
                                    FontAwesomeIcons.crown,
                                  ),
                                  const SizedBox(height: 20),
                                  // 2. The new Tree List for Sub-Children
                                  _buildTreeListItem(
                                    child: _buildCategoryButton22(
                                      'The Royal Agro Eco Tourism',
                                      FontAwesomeIcons.seedling,
                                    ),
                                    isLast: false,
                                  ),
                                  _buildTreeListItem(
                                    child: _buildCategoryButton23(
                                      'The Royal Palace',
                                      FontAwesomeIcons.landmark,
                                    ),
                                    isLast: false,
                                  ),
                                  _buildTreeListItem(
                                    child: _buildCategoryButton24(
                                      'The Royal North-Bengal Club',
                                      FontAwesomeIcons.users,
                                    ),
                                    isLast: true, // Mark the last item
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                //  Properties For You (Static cards)
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 16),
                            child: Text(
                              "PROPERTIES YOU MAY INVEST",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextButton(
                            onPressed: () {
                              //Navigator.pop(context); // Close the drawer or dialog if needed
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AllPropertiesPage(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  'See All',
                                  style: TextStyle(color: Colors.orange),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.32,
                        child: FutureBuilder<AllPropertiesResponse>(
                          future: fetchProperties(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data!.propertyPackages.isEmpty) {
                              // Combined error and no-data checks for brevity
                              return const Center(
                                child: Text("No properties found"),
                              );
                            }

                            final propertyPackages =
                                snapshot.data!.propertyPackages;

                            // Ensure you have enough data to display 2 items
                            // If you have less than 2, the viewportFraction might look odd.
                            final displayPackages = propertyPackages.take(
                              propertyPackages.length,
                            );

                            return CarouselSlider(
                              options: CarouselOptions(
                                height: double.infinity,
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 5),

                                // 🏆 KEY CHANGE 1: Show two items simultaneously
                                viewportFraction: 0.5,

                                // 🏆 KEY CHANGE 2: Disable center enlargement since we show multiple
                                enlargeCenterPage: true,

                                enableInfiniteScroll: true,

                                // Add a little padding to the carousel itself for spacing (optional but recommended)
                                pageSnapping:
                                    true, // Optional: ensures snapping to whole pages (items)
                                // The sliding step remains 1 by default, which is exactly what you need.
                              ),

                              // You should use the full list here, not just .take(3), to ensure infinite scroll works well.
                              items: displayPackages.map((package) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      // Add padding between cards
                                      child: _buildPropertyCard(
                                        context: context,
                                        imageUrl:
                                            "https://growupagro.tech${package.imageUrl}",
                                        propertyName: package.propertyName,
                                        packageName: package.packageName,
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Transactions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 16),
                          child: Text(
                            "TRANSACTION",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WalletHistoryPage(),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Text(
                                'See All',
                                style: TextStyle(color: Colors.orange),
                              ),
                              Icon(Icons.arrow_forward, color: Colors.orange),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1, color: Colors.grey),

                    if (_walletTransactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('No recent transactions.'),
                      )
                    else
                      ..._walletTransactions.take(3).map((tx) {
                        final String type =
                            tx['type']?.toString().toLowerCase() ?? '';
                        IconData icon;

                        if (type == 'withdraw') {
                          icon = Icons.arrow_downward;
                        } else if (type == 'deposit') {
                          icon = Icons.arrow_upward;
                        } else if (type == 'investment') {
                          icon = Icons.bar_chart;
                        } else if (type == 'recharge') {
                          icon = Icons.bolt;
                        } else {
                          icon = Icons.help_outline;
                        }

                        return _buildTransactionItem(
                          icon,
                          tx['type'].toString().toUpperCase(),
                          tx['date'] ?? '', // <- use 'date' not 'created_at'
                          '${tx['amount']} Tk',
                          tx['status'] ?? 'N/A',
                        );
                      }).toList(),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16),
                      child: Text(
                        "GrowUp Recent Activities",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 0, top: 0, bottom: 8, right: 0),
                      child: AdvertisementSlider(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // left drawer
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

  // residential
  Widget _buildCategoryButton6(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5, // make a bit wider for icon+text
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResidencialCityPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.green), // 👈 icon
            const SizedBox(width: 8), // space between icon & text
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: size,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //Commercial
  Widget _buildCategoryButton7(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5, // make a bit wider for icon+text
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CommercialPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.green), // 👈 icon
            const SizedBox(width: 8), // space between icon & text
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: size,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //Eco city
  Widget _buildCategoryButton8(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5, // make a bit wider for icon+text
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RosahitechCityPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.green), // 👈 icon
            const SizedBox(width: 8), // space between icon & text
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: size,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //health care
  Widget _buildCategoryButton9(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5, // make a bit wider for icon+text
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HealthCityPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.green), // 👈 icon
            const SizedBox(width: 8), // space between icon & text
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: size,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //health care
  Widget _buildCategoryButton20(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5,
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoyalEcoCityPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: size,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton22(String title, IconData icon) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 35.0,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EcotourismCityPage(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.grey, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: Colors.green, size: 12), // ✅ use parameter
              const SizedBox(width: 16),
              Text(
                title, // ✅ use parameter
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton23(String title, IconData icon) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 35.0,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PalaceCityPage()),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.grey, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: Colors.green, size: 12), // ✅ use parameter
              const SizedBox(width: 16),
              Text(
                title, // ✅ use parameter
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton24(String title, IconData icon) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 35.0,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NorthCityPage()),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.grey, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: Colors.green, size: 12),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Projects you may invest function
  Widget _buildProjectCard({
    required BuildContext context,
    required String imageUrl,
    required String projectId,
    required String name,
    required String type,
    required String goal,
    required String duration,
    required String minInvestment,
    required String time,
    required String roi,
    required bool isTablet,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isTablet = screenWidth >= 600;
    final cardHeight = isTablet ? screenHeight * 0.48 : screenHeight * 0.18;
    final cardWidth = screenWidth * 0.97;

    final imageWidth = cardWidth * 0.30;
    final imageHeight = cardHeight * 0.95;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.symmetric(
        //vertical: screenHeight * 0.01,
        // horizontal: screenWidth * 0.010,
      ),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: imageWidth,
                  height: imageHeight,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: screenWidth * 0.06),
                ),
              ),
            ),
          ),

          // Right side
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.018,
                    horizontal: screenWidth * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // prevent overflow
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet
                                ? screenWidth * 0.022
                                : screenWidth * 0.036,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.004),
                      ...[
                        _infoRow(label: 'Type:', value: type),
                        _infoRow(label: 'Goal:', value: goal),
                        _infoRow(label: 'Duration:', value: duration),
                        _infoRow(label: 'Min Invest:', value: minInvestment),
                        _infoRow(label: 'Time:', value: time),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: screenWidth * 0.03,
                          color: Colors.white,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          'ROI $roi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet
                                ? screenWidth * 0.022
                                : screenWidth * 0.03,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //helper method Projects you may invest function
  Widget _infoRow({
    required String label,
    required String value,
    double fontSize = 10,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey, fontSize: fontSize),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Properties for you function
  Widget _buildPropertyCard({
    required BuildContext context,
    required String imageUrl,
    required String propertyName,
    required String packageName,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth >= 600;

    final cardWidth = isTablet ? screenWidth * 0.5 : screenWidth * 0.98;
    final cardHeight = isTablet ? screenHeight * 0.45 : screenHeight * 0.35;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // allow natural height
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: cardHeight * 0.70,
              // height: 200, // fixed image height
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              propertyName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.green,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // const SizedBox(height: 10),
          Center(
            child: Text(
              packageName,
              style: const TextStyle(fontSize: 12, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  //end
  // Transaction function
  Widget _buildTransactionItem(
    IconData icon,
    String title,
    String date,
    String amount,
    String status,
  ) {
    // Parse and format date
    String formattedDate = 'N/A';
    if (date.trim().isNotEmpty) {
      try {
        final cleanedDate = date.trim(); // remove leading/trailing spaces
        DateTime parsedDate = DateFormat('dd MMM, yyyy').parse(cleanedDate);
        formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
      } catch (_) {
        formattedDate = date; // fallback to raw string
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  title.toLowerCase() == 'deposit' ||
                      title.toLowerCase() == 'investment'
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              // light red background
              borderRadius: BorderRadius.circular(4), // 4px rounded corners
            ),
            child: Icon(
              icon,
              color:
                  title.toLowerCase() == 'deposit' ||
                      title.toLowerCase() == 'investment'
                  ? Colors.green
                  : Colors.orange,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: StatusChip(status: status.toUpperCase()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    // Set loading state for slider
    setState(() {
      isLoading = true;
      imageUrls.clear();
    });

    //  Fetch slider images
    await fetchSliderImages();

    await fetchAndSaveInvestorProfile(); // updates SharedPreferences
    await fetchWalletBalance(); // updates SharedPreferences

    // Wait for both to finish before loading the values
    await _loadDashboardData(); // reads SharedPreferences

    final walletList = await fetchWalletHistory();

    setState(() {
      _profileFuture = getInvestorProfileFromPrefs(); // updates UI profile
      _walletTransactions = walletList
          .map(
            (e) => {
              'type': e.type,
              'date': e.date,
              'amount': e.amount,
              'status': e.status ?? 'N/A',
              'trx_id': e.trxId,
            },
          )
          .toList();
    });
  }

  Widget _buildTreeListItem({
    required Widget child,
    required bool isLast,
    double indent = 60.0,
    double spacing = 20.0,
    double itemWidth = 210.0,
  }) {
    const double itemHeight = 35.0;
    const double lineWidth = 2.0;
    final Color lineColor = Colors.grey;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: SizedBox(
        height: itemHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: indent,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Left vertical line
                  Positioned(
                    left: indent / 2,
                    top: -spacing,
                    bottom: isLast ? itemHeight / 2 : -spacing,
                    child: Container(width: lineWidth, color: lineColor),
                  ),

                  // Right vertical line
                  Positioned(
                    left: indent * 5,
                    top: -spacing,
                    bottom: isLast ? itemHeight / 2 : -spacing,
                    child: Container(width: lineWidth, color: lineColor),
                  ),

                  // Horizontal connector
                  Positioned(
                    left: indent / 2,
                    top: itemHeight / 2 - lineWidth / 2,
                    width: indent / 2, // connects left → right
                    child: Container(height: lineWidth, color: lineColor),
                  ),

                  Positioned(
                    left: indent * 4.5,
                    top: itemHeight / 2 - lineWidth / 2,
                    width: indent / 2, // connects left → right
                    child: Container(height: lineWidth, color: lineColor),
                  ),
                ],
              ),
            ),

            // ✅ Fixed-width item box
            SizedBox(width: itemWidth, child: child),
          ],
        ),
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
}
