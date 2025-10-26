import 'dart:convert';
import 'dart:ui';
// import 'package:carousel_slider/carousel_slider.dart' show CarouselSlider, CarouselOptions;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:growup_agro/models/live_project_model.dart';
import 'package:growup_agro/models/slider_model.dart';
import 'package:growup_agro/models/wallet_history_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/NotificationPage.dart';
import 'package:growup_agro/views/Total_projects.dart';
import 'package:growup_agro/views/all_projects.dart';
import 'package:growup_agro/views/all_properties.dart';
import 'package:growup_agro/views/auto_slider_card.dart';
import 'package:growup_agro/views/certificates_web.dart';
import 'package:growup_agro/views/commercial_city.dart';
import 'package:growup_agro/views/desposit_page.dart';
import 'package:growup_agro/views/investment_history.dart';
import 'package:growup_agro/views/invoice_capital_return.dart';
import 'package:growup_agro/views/invoice_growup.dart';
import 'package:growup_agro/views/invoice_recharge.dart';
import 'package:growup_agro/views/invoice_roi.dart';
import 'package:growup_agro/views/my_orders_page.dart';
import 'package:growup_agro/views/project_Descriotion_page.dart';
import 'package:growup_agro/views/project_certificate_page.dart';
// import '../../../growup_agro/lib/views/desposit_page.dart';
import 'package:growup_agro/views/recharge_page.dart';
import 'package:growup_agro/views/residencial_city_page.dart';
import 'package:growup_agro/views/rosa_health.dart';
import 'package:growup_agro/views/rosa_hitech.dart';
import 'package:growup_agro/views/royal_eco_city.dart';
import 'package:growup_agro/views/royal_eco_tourism.dart';
import 'package:growup_agro/views/royal_north_bengal_club.dart';
import 'package:growup_agro/views/royal_palace.dart';
import 'package:growup_agro/views/live.dart';
import 'package:growup_agro/views/short_duration.dart';
import 'package:growup_agro/views/tax_certificate.dart';
import 'package:growup_agro/views/todays_income_dialog.dart';
import 'package:growup_agro/views/total_income_dialog.dart';
import 'package:growup_agro/views/upcoming_projects.dart';
import 'package:growup_agro/views/wallet_balance_dialog.dart';
import 'package:growup_agro/views/wallet_history.dart';
import 'package:growup_agro/views/withdraw_page.dart';
import 'package:growup_agro/widgets/bottom_nav_bar.dart';
import 'package:growup_agro/widgets/webview_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_properties.model.dart';
import 'IntroPage.dart';
import 'all_products_page.dart';
import 'completed_projects.dart';
import 'total_investment_dialog.dart' hide WalletHistoryDialog;
import 'eco_city.dart';
import 'healthcare.dart';
import 'hitech_city.dart';
import 'long_duration.dart'; // For SystemNavigator.pop()
import 'package:intl/intl.dart';
import 'package:growup_agro/views/about_us_page.dart';


import 'my_growup_projects_dialog.dart';
import 'my_projects.dart';

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
  // slider picture start
  // final List<String> imageUrls = [
  //   // 'https://admin-growup.onebitstore.site/storage/uploads/slider-image/68cfb01aa8e87.jpg',
  //   // 'https://admin-growup.onebitstore.site/storage/uploads/slider-image/68cfb0265fd21.jpg',
  //   // 'https://admin-growup.onebitstore.site/storage/uploads/slider-image/68cfb02cb01b6.jpg',
  // ];
  // bool isLoading = true;
  //slider picture end
  int _selectedIndex = 0;
  double totalIncome = 0.0;
  double todaysIncome = 0.0;
  int totalProjects = 0;
  String totalwallet_balance = '0';
  String totalInvestment = '0';
  String _walletBalance = '0';
  int _loyaltyPoints = 78;
  bool _showAllCards = false; // Add this inside your State class
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchKey = GlobalKey();

  List<String> imageUrls = [];
  bool isLoading = true;

  List<Map<String, dynamic>> _walletTransactions = [];
  late Future<Map<String, dynamic>> _profileFuture;

  final List<Widget> _pages = [
    // MenuPage(),       // index 0
    // GrowupPage(),     // index 1
    // PropertyPage(),   // index 2
    // TradingPage(),    // index 3
    // WebTabPage(),     // index 4 <-- this shows your WebView
  ];

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
            'date': e.date ?? '',
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

      // debugPrint('Status Code: ${response.statusCode}');
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
      // final response = await http.get(
      //   Uri.parse(
      //     'https://admin-growup.onebitstore.site/api/investor/profile?investor_code=$investorCode',
      //   ),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //   },
      // );
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
      // 'walletbalance': prefs.getString('wallet_balance') ?? 'N/A',
      // "totalinvestment": prefs.getString('total_investment') ?? 'N/A',
      // "totalIncome": prefs.getString('total_income') ?? 'N/A',
      // "todaysIncome": prefs.getString('todays_income') ?? 'N/A',
      // "totalProjects": prefs.getString('total_projects') ?? 'N/A',
    };
  }

  Future<AllPropertiesResponse> fetchProperties() async {
    final response = await http.get(
      // Uri.parse("https://growupagro.tech/api/properties"),
      Uri.parse(ApiConstants.allProperties),
    );

    if (response.statusCode == 200) {
      return AllPropertiesResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load properties");
    }
  }

  // logout start
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    // final url = Uri.parse(
    //   'https://admin-growup.onebitstore.site/api/investor/logout',
    // );

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
  //logout end

  //transaction
  Future<List<WalletHistoryModel>> fetchWalletHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final investorCode = prefs.getString('investor_code');

    // final url = Uri.parse(
    //   'https://admin-growup.onebitstore.site/api/wallet-history?investor_code=$investorCode',
    // );
    //
    // final response = await http.get(
    //   url,
    //   headers: {
    //     'Authorization': 'Bearer $token',
    //     'Content-Type': 'application/json',
    //   },
    // );
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
    // final url = Uri.parse(
    //   'https://admin-growup.onebitstore.site/api/all-projects',
    // );
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
        //left drawer fetch data from api
        drawer: Drawer(
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
                return Container(
                  color: const Color(0xFFFFFFFF),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // DrawerHeader(
                      //   decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
                      //   margin: EdgeInsets.zero,
                      //   padding: const EdgeInsets.all(16),
                      //   child: Row(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       // Avatar on the left
                      //       CircleAvatar(
                      //         radius: 38,
                      //         backgroundImage: profile['image'] != null && profile['image'] != ''
                      //             ? NetworkImage('https://admin-growup.onebitstore.site/storage/${profile['image']}')
                      //             : const AssetImage('assets/images/img.png') as ImageProvider,
                      //       ),
                      //       const SizedBox(width: 16),
                      //
                      //       // Info Column on the right
                      //       Expanded(
                      //         child: SingleChildScrollView(
                      //           child: Column(
                      //             crossAxisAlignment: CrossAxisAlignment.start,
                      //             children: [
                      //               // Name + Edit icon row
                      //               Row(
                      //                 children: [
                      //                   Expanded(
                      //                     child: Text(
                      //                       profile['name'] ?? 'No Name',
                      //                       style: const TextStyle(
                      //                         color: Colors.white,
                      //                         fontWeight: FontWeight.bold,
                      //                         fontSize: 18,
                      //                       ),
                      //                       overflow: TextOverflow.ellipsis,
                      //                     ),
                      //                   ),
                      //                   GestureDetector(
                      //                     onTap: () {
                      //                       Navigator.pushNamed(context, '/myprofile');
                      //                     },
                      //                     child: Image.asset(
                      //                       'assets/icons/edit.png',
                      //                       width: 20,
                      //                       height: 20,
                      //                     ),
                      //                   ),
                      //                 ],
                      //               ),
                      //               const SizedBox(height: 8),
                      //
                      //               // Code
                      //               Row(
                      //                 children: [
                      //                   const Icon(Icons.person, color: Colors.white70, size: 16),
                      //                   const SizedBox(width: 6),
                      //                   Expanded(
                      //                     child: Text(
                      //                       profile['code'] ?? '',
                      //                       style: const TextStyle(
                      //                         color: Colors.white70,
                      //                         fontSize: 12,
                      //                       ),
                      //                       overflow: TextOverflow.ellipsis,
                      //                     ),
                      //                   ),
                      //                 ],
                      //               ),
                      //               const SizedBox(height: 6),
                      //
                      //               // Phone
                      //               Row(
                      //                 children: [
                      //                   const Icon(Icons.phone, color: Colors.white70, size: 16),
                      //                   const SizedBox(width: 6),
                      //                   Expanded(
                      //                     child: Text(
                      //                       profile['phone'] ?? '',
                      //                       style: const TextStyle(
                      //                         color: Colors.white70,
                      //                         fontSize: 12,
                      //                       ),
                      //                       overflow: TextOverflow.ellipsis,
                      //                     ),
                      //                   ),
                      //                 ],
                      //               ),
                      //               const SizedBox(height: 6),
                      //
                      //               // Email
                      //               Row(
                      //                 children: [
                      //                   const Icon(Icons.email, color: Colors.white70, size: 16),
                      //                   const SizedBox(width: 6),
                      //                   Expanded(
                      //                     child: Text(
                      //                       profile['email'] ?? '',
                      //                       style: const TextStyle(
                      //                         color: Colors.white70,
                      //                         fontSize: 12,
                      //                       ),
                      //                       overflow: TextOverflow.ellipsis,
                      //                     ),
                      //                   ),
                      //                 ],
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
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
                            const SizedBox(width: 4), // minimal space
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/myprofile');
                              },
                              child: Image.asset(
                                'assets/icons/edit.png',
                                width: 28,
                                height: 28,
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
                            // Text(
                            //   "ID: ${profile['code']}",
                            //   style: const TextStyle(
                            //     fontSize: 10,
                            //     color: Colors.white,
                            //   ),
                            // )
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

                        // currentAccountPicture: CircleAvatar(
                        //   backgroundImage:
                        //       profile['image'] != null && profile['image'] != ''
                        //       ? NetworkImage(
                        //           'https://admin-growup.onebitstore.site/storage/${profile['image']}',
                        //         )
                        //       : const AssetImage('assets/images/img.png')
                        //             as ImageProvider,
                        // ),
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
                        ),
                        title: Text('Wallet'),
                        childrenPadding: EdgeInsets.only(
                          left: 40,
                        ), // Add left space for all children
                        children: <Widget>[
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.wallet,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/wallet'),
                          ),

                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.moneyCheck,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/deposit'),
                          ),

                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.arrowDown,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/withdraw'),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.seedling,
                          color: Colors.green,
                        ),
                        title: Text('Growup'),
                        childrenPadding: EdgeInsets.only(
                          left: 40,
                        ), // Add left space for all children
                        children: <Widget>[
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.folderOpen,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/projects'),
                          ),
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.projectDiagram,
                              size: 18,
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
                        ),
                        title: Text('Invoices'),
                        childrenPadding: EdgeInsets.only(
                          left: 40,
                        ), // Add left space for all children
                        children: <Widget>[
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.fileInvoice,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/invoice_growup'),
                          ),
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.warehouse,
                              size: 18,
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
                              size: 18,
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
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/invoice_recharge',
                            ),
                          ),

                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.coins,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/invoice_roi'),
                          ),

                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.handHoldingDollar,
                              size: 18,
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
                        ),
                        title: Text('Properties'),
                        childrenPadding: EdgeInsets.only(
                          left: 40,
                        ), // Add left space for all children
                        children: <Widget>[
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.building,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/properties'),
                          ),
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.shoppingBag,
                              size: 18,
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
                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.box,
                          color: Colors.green,
                        ),
                        title: Text('Products'),
                        childrenPadding: EdgeInsets.only(
                          left: 40,
                        ), // Add left space for all children
                        children: <Widget>[
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.box,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/products'),
                          ),
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.shoppingCart,
                              size: 18,
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
                              FontAwesomeIcons.boxOpen,
                              size: 18,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/myorders'),
                          ),

                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.truck,
                              size: 18,
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
                      // _buildDrawerItem(Icons.work_outline, 'Projects', context, '/projects'),
                      // _buildDrawerItem(Icons.account_balance_wallet, 'My Projects', context, '/myprojects'),


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
                        ),
                        title: Text('Certification'),
                        childrenPadding: EdgeInsets.only(
                          left: 40,
                        ), // Add left space for all children
                        children: <Widget>[
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.fileAlt,
                              size: 18,
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
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/tax_certificate',
                            ),
                          ),
                          ListTile(
                            leading: Icon(
                              FontAwesomeIcons.coins,
                              size: 18,
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
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/project_certificate',
                            ),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        leading: Icon(
                          FontAwesomeIcons.infoCircle,
                          color: Colors.green,
                        ),
                        title: Text('About'),
                        childrenPadding: EdgeInsets.only(
                          left: 40,
                        ), // Add left space for all children
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(
                              FontAwesomeIcons.infoCircle,
                              size: 18,
                              color: Colors.green,
                            ),
                            title: const Text('About Us'),
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
                            //   Navigator.pop(context); // Close the drawer or dialog if needed
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(builder: (context) => const CertificateWebViewPage()),
                            //   );
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
                );
              }
            },
          ),
        ),

        //Circle avatar ,text and wallet button
        appBar: _selectedIndex == 4
            ? null
            : AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          centerTitle: true,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          elevation: 0,

          // Drawer avatar at the left
          leading: Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 10),
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
                      // final imageUrl =
                      //     profile['image'] != null &&
                      //         profile['image'].toString().isNotEmpty
                      //     ? 'https://admin-growup.onebitstore.site/storage/${profile['image']}'
                      //     : null;

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
              : Container(
            width: double.infinity,
            padding: const EdgeInsets.all(0.0),
            decoration: BoxDecoration(
              // color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Username from API
                      FutureBuilder<Map<String, dynamic>>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return const Center(
                              child: Text("Error fetching data"),
                            );
                          } else {
                            final profile = snapshot.data!;
                            return Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      // Name
                                      Flexible(
                                        child: Text(
                                          "${profile['name']}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      // Loyalty Points
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[700],
                                          borderRadius:
                                          BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(
                                              width: 4,
                                            ),
                                            Text(
                                              '$_loyaltyPoints',
                                              style:
                                              const TextStyle(
                                                fontSize: 12,
                                                color: Colors
                                                    .white,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Text(
                                  //   "ID: ${profile['code']}",
                                  //   style: const TextStyle(
                                  //     fontSize: 10,
                                  //     color: Colors.white,
                                  //   ),
                                  // )
                                ],
                              ),
                            );
                          }
                        },
                      ),

                      // end of username api

                      // wallet balance
                      Container(
                        width: 160,
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 12,
                          top: 6,
                          bottom: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(
                                  3,
                                ),
                              ),
                              child: Image.asset(
                                'assets/icons/img_5.png',
                                fit: BoxFit.cover,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),

                            Text(
                              '$_walletBalance',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                                      color: Colors.white.withOpacity(
                                        0.9,
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

        body:
        // _selectedIndex == 4
        //     ? const AllPropertiesPage()
        //     :
        RefreshIndicator(
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
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (imageUrls.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: Center(child: Text('No images available')),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 220,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        viewportFraction: 1.0,
                      ),
                      items: imageUrls.map((url) {
                        return Builder(
                          builder: (BuildContext context) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child:
                                      CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),

                // const CertificationsSection(),

                // IndexedStack(index: _selectedIndex, children: _pages),

                // The single container holding all four counter items.
                // The new parent Container adds the margin.
                // Container(
                //   // This adds left and right margin.
                //   margin: const EdgeInsets.symmetric(horizontal: 12.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(10.0),
                //     decoration: BoxDecoration(
                //       color: Colors.green.shade50,
                //       border: Border.all(
                //         color: Colors.grey.shade300,
                //         width: 1,
                //       ),
                //       borderRadius: BorderRadius.circular(12.0),
                //     ),
                //     child: Column(
                //       children: [
                //         // First Row
                //         IntrinsicHeight(
                //           // Added to make the VerticalDivider visible
                //           child: Row(
                //             children: [
                //               // Card 1: Fund Disburse
                //               Expanded(
                //                 child: Padding(
                //                   padding: const EdgeInsets.symmetric(
                //                     vertical: 8.0,
                //                   ),
                //                   child: Column(
                //                     mainAxisAlignment:
                //                     MainAxisAlignment.center,
                //                     children: [
                //                       const Icon(
                //                         FontAwesomeIcons.handHoldingDollar,
                //                         size: 20,
                //                         color: Colors.green,
                //                       ),
                //                       const SizedBox(height: 6),
                //                       const Text(
                //                         "৳ 1Billion++",
                //                         style: TextStyle(
                //                           fontSize: 16,
                //                           fontWeight: FontWeight.bold,
                //                           color: Colors.black87,
                //                         ),
                //                       ),
                //                       const SizedBox(height: 1),
                //                       const Text(
                //                         "Fund Disburse",
                //                         style: TextStyle(
                //                           fontSize: 12,
                //                           color: Colors.black,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                         textAlign: TextAlign.center,
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ),
                //               // NEW: Vertical line separator
                //               const VerticalDivider(width: 1, thickness: 1),
                //               // Card 2: Fund Reimburse
                //               Expanded(
                //                 child: Padding(
                //                   padding: const EdgeInsets.symmetric(
                //                     vertical: 8.0,
                //                   ),
                //                   child: Column(
                //                     mainAxisAlignment:
                //                     MainAxisAlignment.center,
                //                     children: [
                //                       const Icon(
                //                         FontAwesomeIcons.moneyBillTransfer,
                //                         size: 20,
                //                         color: Colors.green,
                //                       ),
                //                       const SizedBox(height: 6),
                //                       const Text(
                //                         "৳ 1Billion++",
                //                         style: TextStyle(
                //                           fontSize: 16,
                //                           fontWeight: FontWeight.bold,
                //                           color: Colors.black87,
                //                         ),
                //                       ),
                //                       const SizedBox(height: 1),
                //                       const Text(
                //                         "Fund Reimburse",
                //                         style: TextStyle(
                //                           fontSize: 12,
                //                           color: Colors.black,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                         textAlign: TextAlign.center,
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //         // NEW: Horizontal line separator
                //         const Divider(height: 1, thickness: 1),
                //         // Second Row
                //         IntrinsicHeight(
                //           // Added to make the VerticalDivider visible
                //           child: Row(
                //             children: [
                //               // Card 3: Farmers Engaged
                //               Expanded(
                //                 child: Padding(
                //                   padding: const EdgeInsets.symmetric(
                //                     vertical: 8.0,
                //                   ),
                //                   child: Column(
                //                     mainAxisAlignment:
                //                     MainAxisAlignment.center,
                //                     children: [
                //                       const Icon(
                //                         FontAwesomeIcons.wheatAwn,
                //                         size: 20,
                //                         color: Colors.green,
                //                       ),
                //                       const SizedBox(height: 6),
                //                       const Text(
                //                         "12K+",
                //                         style: TextStyle(
                //                           fontSize: 16,
                //                           fontWeight: FontWeight.bold,
                //                           color: Colors.black87,
                //                         ),
                //                       ),
                //                       const SizedBox(height: 1),
                //                       const Text(
                //                         "Farmers Engaged",
                //                         style: TextStyle(
                //                           fontSize: 12,
                //                           color: Colors.black,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                         textAlign: TextAlign.center,
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ),
                //               // NEW: Vertical line separator
                //               const VerticalDivider(width: 1, thickness: 1),
                //               // Card 4: Active Projects
                //               Expanded(
                //                 child: Padding(
                //                   padding: const EdgeInsets.symmetric(
                //                     vertical: 8.0,
                //                   ),
                //                   child: Column(
                //                     mainAxisAlignment:
                //                     MainAxisAlignment.center,
                //                     children: [
                //                       const Icon(
                //                         FontAwesomeIcons.seedling,
                //                         size: 20,
                //                         color: Colors.green,
                //                       ),
                //                       const SizedBox(height: 6),
                //                       const Text(
                //                         "100k Ton++",
                //                         style: TextStyle(
                //                           fontSize: 16,
                //                           fontWeight: FontWeight.bold,
                //                           color: Colors.black87,
                //                         ),
                //                       ),
                //                       const SizedBox(height: 1),
                //                       const Text(
                //                         "Farm Produce Sold",
                //                         style: TextStyle(
                //                           fontSize: 12,
                //                           color: Colors.black,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                         textAlign: TextAlign.center,
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),

                // Total Counting cards
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double cardWidth =
                          (constraints.maxWidth - 16) /
                              3; // 16 = 2 gaps of 8 pixels between cards

                      //counter
                      String formatValue(String value) {
                        try {
                          final parsedValue = double.tryParse(value) ?? 0.0;
                          final formattedValue = NumberFormat('#,##0.00').format(parsedValue);
                          return formattedValue;
                        } catch (e) {
                          return value;
                        }
                      }


                      Widget buildCard(
                          String title,
                          String value,
                          IconData icon,
                          ) {
                        String displayValue = formatValue(value);
                        return Container(
                          width: cardWidth,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip
                                .none, // allow positioning outside padding if needed
                            children: [
                              Center(
                                child: _buildInnerCard(
                                  title,
                                  displayValue, // <-- use formatted value here
                                  icon,
                                ),
                              ),

                              Positioned(
                                top: -20, // a little padding from top edge
                                right:
                                -10, // a little padding from right edge
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.more_horiz,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  splashRadius: 20,
                                  onPressed: () {
                                    if (title == 'Total Investment') {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            insetPadding:
                                            const EdgeInsets.all(12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child:
                                            const TotalInvestmentHistoryPage(),
                                          );
                                        },
                                      );
                                    } else if (title == "Today's Income") {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            insetPadding:
                                            const EdgeInsets.all(12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child:
                                            const TodaysIncomeDialog(),
                                          );
                                        },
                                      );
                                    } else if (title == "Total Income") {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            insetPadding:
                                            const EdgeInsets.all(12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child:
                                            const TotalIncomeDialog(),
                                          );
                                        },
                                      );
                                    } else if (title ==
                                        "My Grow Up Projects") {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            insetPadding:
                                            const EdgeInsets.all(12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child:
                                            const MyGrowupProjectsDialog(),
                                          );
                                        },
                                      );
                                    } else if (title == "Wallet Balance") {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            insetPadding:
                                            const EdgeInsets.all(12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child:
                                            const WalletHistoryDialog(),
                                          );
                                        },
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Details'),
                                            content: Text(
                                              'Here are more details about "$title".',
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                style:
                                                ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                  Colors.red,
                                                ),
                                                child: const Text(
                                                  "Close",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // three cards disburse, reimburse and engaged
                      // Widget buildCardcounter(String title, String value, IconData icon, Color iconColor) {
                      //   // Wrap with a Container to add border and shape
                      //   return Container(
                      //     decoration: BoxDecoration(
                      //
                      //       // The border for each card
                      //       border: Border.all(
                      //         color: Colors.grey.shade300, // Light grey color for the border
                      //         width: 1,
                      //       ),
                      //       // The corner radius
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     child: Padding(
                      //       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      //       child: Column(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         children: [
                      //           Icon(icon, size: 20, color: iconColor),
                      //           const SizedBox(height: 6),
                      //           Text(
                      //             value,
                      //             style: const TextStyle(
                      //               fontSize: 16,
                      //               fontWeight: FontWeight.bold,
                      //               color: Colors.black87,
                      //             ),
                      //           ),
                      //           const SizedBox(height: 1),
                      //           Text(
                      //             title,
                      //             style: const TextStyle(fontSize: 12, color: Colors.black,fontWeight: FontWeight.bold,),
                      //             textAlign: TextAlign.center,
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   );
                      // }

                      return Column(
                        children: [
                          // const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: buildCard(
                                  'Today\'s Income',
                                  todaysIncome.toString(),
                                  Icons.monetization_on,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: buildCard(
                                  'Total Income',
                                  totalIncome.toString(),
                                  Icons.account_balance_wallet,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row 2: Full-width Wallet Balance card with image
                          // buildFullImageCard(
                          //   context,
                          //   'Wallet Balance',
                          //   totalwallet_balance.toString(),
                          //   'assets/images/img_2.png', // your image
                          // ),
                          // const SizedBox(height: 8),

                          // Row 3: Two half-width cards
                          Row(
                            children: [
                              Expanded(
                                child: buildCard(
                                  'My Grow Up Projects',
                                  totalProjects.toString(),
                                  Icons.auto_graph,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: buildCard(
                                  'Ordered Properties',
                                  '0',
                                  Icons.home_work_outlined,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: buildCard(
                                  "Total Investment",
                                  totalInvestment.toString(),
                                  FontAwesomeIcons.moneyBillTrendUp,
                                ),
                              ),
                            ],
                          ),

                          // const SizedBox(height: 8),
                          // SizedBox(
                          //   height: 90, // card height
                          //   width: double.infinity,
                          //   child: PageView(
                          //     controller: PageController(
                          //       viewportFraction: 1.02,
                          //     ), // full width minus small space
                          //     children: [
                          //       Padding(
                          //         padding: const EdgeInsets.symmetric(
                          //           horizontal: 4,
                          //         ), // space between cards
                          //         child: buildCard(
                          //           // context,
                          //           "Total Investment",
                          //           totalInvestment.toString(),
                          //             FontAwesomeIcons.piggyBank,
                          //           // "assets/images/img_1.png",
                          //         ),
                          //       ),
                          //       // Padding(
                          //       //   padding: const EdgeInsets.symmetric(
                          //       //     horizontal: 4,
                          //       //   ), // space between cards
                          //       //   child: buildFullImageCard(
                          //       //     context,
                          //       //     "Wallet Balance",
                          //       //     totalwallet_balance.toString(),
                          //       //     "assets/images/img_2.png",
                          //       //   ),
                          //       // ),
                          //       // Add more cards here
                          //     ],
                          //   ),
                          // ),

                          // Row 4: Full-width Total Investment card with image
                          // buildFullImageCard(
                          //   context,
                          //   'Total Investment',
                          //   totalInvestment.toString(),
                          //   'assets/images/img_1.png', // your image
                          // ),
                        ],
                      );
                    },
                  ),
                ),

                const CompanyCertificationsCarousel(),

                IndexedStack(index: _selectedIndex, children: _pages),

                // The single container holding all four counter items.
                // The new parent Container adds the margin.
                Container(
                  // This adds left and right margin.
                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      children: [
                        // First Row
                        IntrinsicHeight(
                          // Added to make the VerticalDivider visible
                          child: Row(
                            children: [
                              // Card 1: Fund Disburse
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.handHoldingDollar,
                                        size: 20,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        "৳ 1Billion++",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      const Text(
                                        "Fund Disburse",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // NEW: Vertical line separator
                              const VerticalDivider(width: 1, thickness: 1),
                              // Card 2: Fund Reimburse
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.moneyBillTransfer,
                                        size: 20,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        "৳ 1Billion++",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      const Text(
                                        "Fund Reimburse",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // NEW: Horizontal line separator
                        const Divider(height: 1, thickness: 1),
                        // Second Row
                        IntrinsicHeight(
                          // Added to make the VerticalDivider visible
                          child: Row(
                            children: [
                              // Card 3: Farmers Engaged
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.wheatAwn,
                                        size: 20,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        "12K+",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      const Text(
                                        "Farmers Engaged",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // NEW: Vertical line separator
                              const VerticalDivider(width: 1, thickness: 1),
                              // Card 4: Active Projects
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.seedling,
                                        size: 20,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        "100k Ton++",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      const Text(
                                        "Farm Produce Sold",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
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
                  ),
                ),

                // Growup Investment by category
                Card(
                  // CHANGED: Set elevation to 0 and color to transparent
                  elevation: 0,
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with asset icon on the right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: two lines of text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // CHANGED: Wrapped the Text widget with a Container for highlighting
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
                                      6,
                                    ), // Rounded corners
                                  ),
                                  child: const Text(
                                    'GROWUP',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'INVESTMENT BY CATEGORY',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            // Right side: icon
                            Image.asset(
                              'assets/icons/Shariah.png',
                              width: 60,
                              height: 60,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Your container with buttons
                        Container(
                          // Set the color to transparent if you want the buttons to sit on the main background
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              // First row of buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildCategoryButton4(
                                      'Short-Term Projects',
                                      Icons.timelapse,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCategoryButton5(
                                      'Long-Term Projects',
                                      Icons.access_time_filled,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Second row of buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildCategoryButton3(
                                      'Live Projects',
                                      FontAwesomeIcons.broadcastTower,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCategoryButton2(
                                      'Matured Projects',
                                      FontAwesomeIcons.checkCircle,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              // Second row of buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildCategoryButton11(
                                      'All GrowUp Projects',
                                      Icons.dashboard_outlined,
                                    ),
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

                // Projects you may invest
                Padding(
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 10,
                    left: 8,
                    right: 8,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // ✅ shrink to fit
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PROJECTS YOU MAY INVEST',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                            return CarouselSlider(
                              options: CarouselOptions(
                                height:
                                MediaQuery.of(context).size.height *
                                    0.20,
                                autoPlay: true,
                                autoPlayInterval: const Duration(
                                  seconds: 5,
                                ),
                                enlargeCenterPage: true,
                                viewportFraction:
                                1.0, // shows multiple cards partially
                                enableInfiniteScroll: true,
                              ),
                              items: projects.map((project) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return _buildProjectCard(
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
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                // Properties Investment by category
                Container(
                  // CHANGED: Set the color to transparent to remove the white background
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with static icon on the right
                        Row(
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
                                      6,
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
                                const SizedBox(height: 10),
                                const Text(
                                  'INVESTMENT BY CATEGORY',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    height: 1.0,
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

                        const SizedBox(height: 10),

                        // This is the section with your buttons, it remains unchanged.
                        Column(
                          children: [
                            // ... (Your first three rows of buttons remain the same) ...

                            // Row 1: Residential + Commercial (No change)
                            Row(
                              children: [
                                Expanded(child: _buildCategoryButton6('Residential ', FontAwesomeIcons.city)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildCategoryButton7('Commercial ', FontAwesomeIcons.handshake)),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 3: ROSA HiTech City + ROSA Health (No change)
                            Row(
                              children: [
                                Expanded(child: _buildCategoryButton8('ROSA HiTech City', FontAwesomeIcons.microchip)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildCategoryButton9('ROSA Health', FontAwesomeIcons.heartbeat)),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 2: The Royal Eco City (No change)
                            // Row(
                            //   children: [
                            //     Expanded(child: _buildCategoryButton21('The Royal Eco City', FontAwesomeIcons.crown)),
                            //   ],
                            // ),
                            // const SizedBox(height: 10),



                            // --- NEW SECTION FOR THE ROYAL CLUB AND ITS CHILDREN ---
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. The Parent Button (remains the same)
                                _buildCategoryButton20(
                                  'The Royal Eco City',
                                  FontAwesomeIcons.crown,
                                ),
                                const SizedBox(height: 20),
                                // 2. The new Tree List for Sub-Children
                                _buildTreeListItem(
                                  child: _buildCategoryButton22('The Royal Agro Eco Tourism', FontAwesomeIcons.seedling),
                                  isLast: false,
                                ),
                                _buildTreeListItem(
                                  child: _buildCategoryButton23('The Royal Palace', FontAwesomeIcons.landmark),
                                  isLast: false,
                                ),
                                _buildTreeListItem(
                                  child: _buildCategoryButton24('The Royal North-Bengal Club', FontAwesomeIcons.users),
                                  isLast: true, // Mark the last item
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                //  Properties For You (Static cards)
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PROPERTIES YOU MAY INVEST',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.propertyPackages.isEmpty) {
                                // Combined error and no-data checks for brevity
                                return const Center(
                                  child: Text("No properties found"),
                                );
                              }

                              final propertyPackages = snapshot.data!.propertyPackages;

                              // Ensure you have enough data to display 2 items
                              // If you have less than 2, the viewportFraction might look odd.
                              final displayPackages = propertyPackages.take(propertyPackages.length);

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
                                  pageSnapping: true, // Optional: ensures snapping to whole pages (items)

                                  // The sliding step remains 1 by default, which is exactly what you need.
                                ),

                                // You should use the full list here, not just .take(3), to ensure infinite scroll works well.
                                items: displayPackages.map((package) {
                                  return Builder(
                                    builder: (BuildContext context) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add padding between cards
                                        child: _buildPropertyCard(
                                          context: context,
                                          imageUrl: "https://growupagro.tech${package.imageUrl}",
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
                ),

                // Transactions
                Card(
                  elevation: 9,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transaction title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TRANSACTION',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WalletHistoryPage(),
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
                        const Divider(thickness: 1.2, color: Colors.green),

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
                            }
                            else {
                              icon = Icons.help_outline;
                            }

                            return _buildTransactionItem(
                              icon,
                              tx['type'].toString().toUpperCase(),
                              tx['date'] ?? '',  // <- use 'date' not 'created_at'
                              '${tx['amount']} Tk',
                              tx['status'] ?? 'N/A',
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // bottomNavigationBar: CustomBottomNavBar(
        //   selectedIndex: _selectedIndex,
        //   onItemTapped: _onItemTapped,
        // ),
      ),
    );
  }

  // left drawer
  ListTile _buildDrawerItem(
      IconData icon,
      String title,
      BuildContext context,
      String route,
      ) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      onTap: () {
        //Navigator.pop(context); // close the drawer first
        Navigator.pushNamed(context, route);
      },
    );
  }

  // Total Investment, income and today's income function
  Widget _buildCompositeCard(double width, List<Widget> innerCards) {
    return SizedBox(
      width: width,
      child: Card(
        color: Colors.white, // Explicitly set white color
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Ensure inner container is also white
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          height: 100,
          child: Row(
            children: List.generate(innerCards.length * 2 - 1, (index) {
              if (index.isOdd) {
                return Container(
                  width: 1,
                  height: double.infinity,
                  color: Colors.grey.shade300,
                );
              }
              return Expanded(child: innerCards[index ~/ 2]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerCard(String title, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // imagecard
  Widget buildFullImageCard(
      BuildContext context,
      String title,
      String value,
      String imagePath,
      ) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.9),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(imagePath, fit: BoxFit.cover),

            // 👇 Blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // adjust strength
              child: Container(
                color: Colors.black.withOpacity(0.3), // dark overlay
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '৳ $value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Three-dot button
            Positioned(
              top: -6,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                splashRadius: 20,
                onPressed: () {
                  if (title == "Wallet Balance") {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          insetPadding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const WalletHistoryDialog(),
                        );
                      },
                    );
                  } else if (title == 'Total Investment') {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return Dialog(
                          insetPadding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const TotalInvestmentHistoryPage(),
                        );
                      },
                    );
                  } else {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Details'),
                          content: Text(
                            'Here are more details about "$title".',
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text(
                                "Close",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //// Total Investment, income and today's income function end

  // Investment by category function

  //Long Duration
  Widget _buildCategoryButton2(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5, // make a bit wider for icon+text
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CompletedProjectsPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16 , color: Colors.green), // 👈 icon
            const SizedBox(width: 6), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //short Duration
  Widget _buildCategoryButton3(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5, // make a bit wider for icon+text
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LiveProjectsPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16 , color: Colors.green), // 👈 icon
            const SizedBox(width: 6), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // live
  Widget _buildCategoryButton4(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5,
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShortProjectsPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16 , color: Colors.green), // 👈 icon
            const SizedBox(width: 6), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //upcoming
  Widget _buildCategoryButton10(String label, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 80, // Adjust width as needed
        height: 80, // Adjust height as needed
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TotalProjectsPage(),
              ),
            );
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEBFEDE), // fully transparent
            shadowColor: const Color(0xFFEBFEDE), // remove shadow
            foregroundColor: Colors.green[700], // icon/text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey, width: 0), // outline
            ),
            padding: const EdgeInsets.all(12),
            elevation: 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Matured
  // Matured
  Widget _buildCategoryButton11(String label, IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5,
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AllProjectsPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1), // border
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18 , color: Colors.green), // 👈 icon
            const SizedBox(width: 10), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //All projects
  Widget _buildCategoryButton5(String label,  IconData icon) {
    double size = 14;

    return SizedBox(
      width: size * 5,
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LongProjectsPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1), // border
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18 , color: Colors.green), // 👈 icon
            const SizedBox(width: 6), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //Residential city
  // Widget _buildCategoryButton6(String label, IconData icon, String imageUrl) {
  //   final screenWidth = MediaQuery.of(context).size.width;
  //   final screenHeight = MediaQuery.of(context).size.height;
  //
  //   final isTablet = screenWidth >= 600;
  //   final cardHeight = isTablet ? screenHeight * 0.18 : screenHeight * 0.10;
  //   final cardWidth = screenWidth * 0.95;
  //
  //   return SizedBox(
  //     width: cardWidth,
  //     height: cardHeight,
  //     child: InkWell(
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => const ResidencialCityPage(),
  //           ),
  //         );
  //       },
  //       borderRadius: BorderRadius.circular(12),
  //       child: Card(
  //         elevation: 9,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         clipBehavior: Clip.antiAlias,
  //         child: Stack(
  //           fit: StackFit.expand,
  //           children: [
  //             // Background image
  //             Image.network(
  //               imageUrl,
  //               fit: BoxFit.cover,
  //               errorBuilder: (context, error, stackTrace) => Container(
  //                 color: Colors.grey[300],
  //                 child: const Icon(Icons.image_not_supported,
  //                     size: 40, color: Colors.grey),
  //               ),
  //             ),
  //
  //             BackdropFilter(
  //               filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5), // adjust strength
  //               child: Container(
  //                 color: Colors.black.withOpacity(0.3), // dark overlay
  //               ),
  //             ),
  //
  //             // Gradient overlay
  //             Container(
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   colors: [
  //                     Colors.black.withOpacity(0.5),
  //                     Colors.transparent
  //                   ],
  //                   begin: Alignment.bottomCenter,
  //                   end: Alignment.topCenter,
  //                 ),
  //               ),
  //             ),
  //
  //             // Icon + Label
  //             Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //               child: Row(
  //                 children: [
  //                   Icon(icon,
  //                       size: isTablet ? screenWidth * 0.04 : 28,
  //                       color: Colors.white),
  //                   const SizedBox(width: 12),
  //                   Expanded(
  //                     child: Text(
  //                       label,
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: isTablet
  //                             ? screenWidth * 0.022
  //                             : screenWidth * 0.040,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // // residential
  // Widget _buildCategoryButton6(String label, IconData icon) {
  //   double size = 8; // base size → controls icon + text scaling
  //
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: SizedBox(
  //       height: 100, // fixed height
  //       child: OutlinedButton(
  //         onPressed: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => const ResidencialCityPage(),
  //             ),
  //           );
  //         },
  //         style: OutlinedButton.styleFrom(
  //           side: const BorderSide(color: Colors.grey, width: 1), // border
  //           backgroundColor: Colors.white,
  //           foregroundColor: Colors.black,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           padding: const EdgeInsets.all(12),
  //         ),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             // 🔹 Icon inside round box
  //             Container(
  //               width: size * 3,
  //               height: size * 3,
  //               decoration: BoxDecoration(
  //                 shape: BoxShape.circle,
  //                 color: Colors.green[50],
  //                 border: Border.all(color: Colors.green[700]!, width: 1),
  //               ),
  //               child: Icon(icon, size: size * 1.6, color: Colors.green[700]),
  //             ),
  //             const SizedBox(height: 10),
  //             Text(
  //               label,
  //               style: TextStyle(
  //                 color: Colors.black,
  //                 fontSize: size,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16 , color: Colors.green), // 👈 icon
            const SizedBox(width: 12), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
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
            MaterialPageRoute(
              builder: (context) => const CommercialPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.green), // 👈 icon
            const SizedBox(width: 12), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //royal north
  Widget _buildCategoryButton21(String label, IconData icon) {
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
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.green), // 👈 icon
            const SizedBox(width: 12), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
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
            MaterialPageRoute(
              builder: (context) => const RosahitechCityPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.green), // 👈 icon
            const SizedBox(width: 12), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
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
            MaterialPageRoute(
              builder: (context) => const HealthCityPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.green), // 👈 icon
            const SizedBox(width: 12), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
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
      width: size * 5, // make a bit wider for icon+text
      height: size * 3.5,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoyalEcoCityPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.green), // 👈 icon
            const SizedBox(width: 12), // space between icon & text
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: size, fontWeight: FontWeight.bold),
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
        width: 250.0,
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ecotourismCityPage(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.grey, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: Colors.green, size: 12), // ✅ use parameter
              const SizedBox(width: 8),
              Text(
                title, // ✅ use parameter
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
        width: 250.0,
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PalaceCityPage(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.grey, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: Colors.green, size: 12), // ✅ use parameter
              const SizedBox(width: 8),
              Text(
                title, // ✅ use parameter
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
        width: 250.0,
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NorthCityPage(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.grey, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: Colors.green, size: 12), // ✅ use parameter
              const SizedBox(width: 8),
              Text(
                title, // ✅ use parameter
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
  })
  {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isTablet = screenWidth >= 600;
    final cardHeight = isTablet ? screenHeight * 0.48 : screenHeight * 0.18;
    final cardWidth = screenWidth * 0.97;

    final imageWidth = cardWidth * 0.30;
    final imageHeight = cardHeight * 0.95;

    final buttonWidth = cardWidth * 0.25;
    final buttonHeight = cardHeight * 0.18;

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
        boxShadow: [
          // BoxShadow(
          //   color: Colors.grey.withOpacity(0.9),
          //   spreadRadius: 2,
          //   blurRadius: 8,
          //   offset: Offset(0, 4),
          // ),
        ],
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
                    vertical: screenHeight * 0.028,
                    horizontal: screenWidth * 0.01,
                  ),
                  child: Column(
                    // mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          // fontSize: screenWidth * 0.036,
                          fontSize: isTablet
                              ? screenWidth * 0.022
                              : screenWidth * 0.036,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.005),

                      // Info fields
                      _infoRow(
                        label: 'Type:',
                        value: type,
                        fontSize: isTablet
                            ? screenWidth * 0.022
                            : screenWidth * 0.028,
                      ),
                      _infoRow(
                        label: 'Goal:',
                        value: goal,
                        fontSize: isTablet
                            ? screenWidth * 0.022
                            : screenWidth * 0.028,
                      ),
                      _infoRow(
                        label: 'Duration:',
                        value: duration,
                        fontSize: isTablet
                            ? screenWidth * 0.022
                            : screenWidth * 0.028,
                      ),
                      _infoRow(
                        label: 'Min Invest:',
                        value: minInvestment,
                        fontSize: isTablet
                            ? screenWidth * 0.022
                            : screenWidth * 0.028,
                      ),
                      _infoRow(
                        label: 'Time:',
                        value: time,
                        fontSize: isTablet
                            ? screenWidth * 0.022
                            : screenWidth * 0.028,
                      ),
                    ],
                  ),
                ),

                // ROI Badge
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

                // "Invest Now" Button
                // Positioned(
                //   bottom: cardHeight * 0.19,
                //   right: -buttonWidth * 0.38,
                //   child: Transform.rotate(
                //     angle: -1.5708,
                //     child: SizedBox(
                //       width: buttonWidth,
                //       height: buttonHeight,
                //       child: ElevatedButton(
                //         onPressed: () async {
                //           final parsedProjectId = int.tryParse(projectId);
                //           final prefs = await SharedPreferences.getInstance();
                //           final investorCode = prefs.getString('investor_code') ?? '';
                //
                //           if (parsedProjectId != null &&
                //               investorCode.isNotEmpty) {
                //             Navigator.push(
                //               context,
                //               MaterialPageRoute(
                //                 builder: (_) => ProjectDescriptionPage(
                //                   projectId: parsedProjectId,
                //                   investorCode: investorCode,
                //                 ),
                //               ),
                //             );
                //           }
                //         },
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: const Color(0xFF61B15A),
                //           foregroundColor: Colors.white,
                //           padding: EdgeInsets.symmetric(
                //             horizontal: 4,
                //             vertical: 4,
                //           ),
                //           shape: const RoundedRectangleBorder(
                //             borderRadius: BorderRadius.only(
                //               topRight: Radius.circular(16),
                //               bottomLeft: Radius.circular(16),
                //             ),
                //           ),
                //         ),
                //         child: Text(
                //           'Details',
                //           style: TextStyle(
                //             fontSize: isTablet
                //                 ? screenWidth * 0.022
                //                 : screenWidth * 0.03,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
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

  // properties you may invest

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
      // height: cardHeight,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // BoxShadow(
          //   color: Colors.grey.withOpacity(0.9),
          //   spreadRadius: 2,
          //   blurRadius: 8,
          //   offset: Offset(0, 4),
          // ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // allow natural height
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
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

          // const Spacer(),
          // const SizedBox(height: 12),
          // // Button flush with bottom card edges
          // SizedBox(
          //   width: double.infinity,
          //   height: 40,
          //   child: ElevatedButton(
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => const AllPropertiesPage()),
          //       );
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.green,
          //       shape: const RoundedRectangleBorder(
          //         borderRadius: BorderRadius.only(
          //           bottomLeft: Radius.circular(16),
          //           bottomRight: Radius.circular(16),
          //         ),
          //       ),
          //       elevation: 0, // match card shadow
          //     ),
          //     child: const Text(
          //       'See Details',
          //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          //     ),
          //   ),
          // ),
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
      )
  {
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
          Icon(icon, color: Colors.green, size: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: status.toLowerCase() == 'approved'
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.9),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: status.toLowerCase() == 'approved'
                        ? Colors.black
                        : Colors.black,
                  ),
                ),
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
              'date': e.date ?? '',
          'amount': e.amount,
          'status': e.status ?? 'N/A',
          'trx_id': e.trxId,
        },
      )
          .toList();
    });
  }

// 헬 NEW HELPER WIDGET for creating the tree structure 헬
  Widget _buildTreeListItem({
    required Widget child,
    required bool isLast,
    double indent = 60.0,
    double spacing = 20.0, // 👈 extra gap between items
  }) {
    const double itemHeight = 35.0; // Use the actual height of your buttons (35.0)
    const double lineWidth = 2.0;
    final Color lineColor = Colors.grey;

    // Calculate the total height of the tree element (item height + spacing)
    final double totalHeight = itemHeight + spacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: SizedBox(
        height: itemHeight, // The actual height of the content (button)
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tree Line Connector
            SizedBox(
              width: indent,
              child: Stack(
                clipBehavior: Clip.none, // Allow lines to draw outside Stack boundaries
                alignment: Alignment.centerLeft,
                children: [
                  // 1. Vertical Line
                  Positioned(
                    left: indent / 2,
                    top: -spacing ,
                    bottom: isLast ? itemHeight / 2 : -spacing,
                    child: Container(width: lineWidth, color: lineColor),
                  ),

                  // 2. Horizontal Connector (T-Junction)
                  Positioned(
                    left: indent / 2,
                    top: itemHeight / 2 - lineWidth / 2, // Middle of the item
                    width: 30,
                    child: Container(height: lineWidth, color: lineColor),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// class CertificationsSection extends StatelessWidget {
//   const CertificationsSection({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(10.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           const Text(
//             'Company Certifications & Affiliations',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 10),
//
//           // --- ROSA Certifications (Using structured data now) ---
//           SizedBox(
//             height: 150, // adjust height based on your card size
//             child: PageView(
//               controller: PageController(viewportFraction: 0.9),
//               children: [
//                 _buildCompanyCertificationCard(
//                   context,
//                   companyName: 'GrowUp Agrotech Limited',
//                   logoIcon: Icons.grass,
//                   certifications: const [
//                     {'name': 'Certificate of Incorporation', 'number': 'C-195903'},
//                     {'name': 'DCCI Registration', 'number': 'ECNGRO202507001532'},
//                     {'name': 'BIDA Registration', 'number': 'L-202508060017189-H'},
//                     {'name': 'Trade License', 'number': 'TRAD/DNCC/006823'},
//                     {'name': 'D&B D-U-N-S', 'number': '77-411-5707'},
//                   ],
//                   color: Colors.green.shade50,
//                   iconColor: Colors.green.shade800,
//                 ),
//
//                 // const SizedBox(width: 2),
//
//                 _buildCompanyCertificationCard(
//                   context,
//                   companyName: 'Rural Organisations for Social Affairs (ROSA)',
//                   logoIcon: Icons.business,
//                   certifications: const [
//                     {'name': 'Established in', 'number': '1992'},
//                     {'name': 'Reg No of (DSS)', 'number': 'DSS NAT-152'},
//                     {'name': 'MRA No', 'number': '017330010400726'},
//                     {'name': 'NGO Bureau No', 'number': '1091'},
//                     {'name': 'Received financial support from PKSF', 'number': ''},
//                   ],
//                   color: Colors.blue.shade50,
//                   iconColor: Colors.blue.shade800,
//                 ),
//               ],
//             ),
//           )
//
//         ],
//       ),
//     );
//   }
//
//   // UPDATED SIGNATURE: certifications is now List<dynamic>
//   Widget _buildCompanyCertificationCard(
//       BuildContext context, {
//         required String companyName,
//         required IconData logoIcon,
//         required List<dynamic> certifications, // Changed to dynamic
//         required Color color,
//         required Color iconColor,
//       }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(10.0),
//         border: Border.all(color: Colors.grey.shade300, width: 0.8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(logoIcon, size: 18, color: iconColor),
//               const SizedBox(width: 8),
//               Text(
//                 companyName,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: iconColor,
//                 ),
//               ),
//             ],
//           ),
//           const Divider(height: 12, thickness: 0.5),
//
//           // Use Column and Padding for the list of certifications
//           ...certifications.map((cert) {
//             // Check if the item is a Map (Structured Data) or a String (Simple Data)
//             final bool isStructured = cert is Map<String, String>;
//
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(Icons.check_circle_outline, size: 14, color: iconColor.withOpacity(0.7)),
//                   const SizedBox(width: 8),
//
//                   if (isStructured) ...[
//                     // STRUCTURED FORMAT (GrowUp Agrotech Limited)
//                     Text(
//                       '${cert['name']}:',
//                       style: const TextStyle(
//                         fontSize: 10,
//                         height: 1.2,
//                         fontWeight: FontWeight.w600, // Name bolded for emphasis
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         cert['number']!,
//                         style: const TextStyle(fontSize: 10, height: 1.2, color: Colors.black87),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ] else
//                   // SIMPLE STRING FORMAT (Rural Organisations for Social Affairs)
//                     Expanded(
//                       child: Text(
//                         cert.toString(),
//                         style: const TextStyle(fontSize: 10, height: 1.2),
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }
// }