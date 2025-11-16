import 'dart:convert';
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
import 'package:growup_agro/views/global_insights.dart';
import 'package:growup_agro/views/residencial_city_page.dart';
import 'package:growup_agro/views/rosa_health.dart';
import 'package:growup_agro/views/royal_eco_city.dart';
import 'package:growup_agro/views/royal_eco_tourism.dart';
import 'package:growup_agro/views/royal_north_bengal_club.dart';
import 'package:growup_agro/views/royal_palace.dart';
import 'package:growup_agro/views/live.dart';
import 'package:growup_agro/views/short_duration.dart';
import 'package:growup_agro/views/wallet_history.dart';
import 'package:growup_agro/widgets/advertisement_slider.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_properties.model.dart';
import '../widgets/achievement_card.dart';
import '../widgets/appbar_content.dart';
import '../widgets/category_item.dart';
import '../widgets/home_image_slider.dart';
import '../widgets/properties_carousel_section.dart';
import '../widgets/shariah_project_carousel.dart';
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
                child: const Text('No', style: TextStyle(fontSize: 30),),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes', style: TextStyle(color: Colors.red, fontSize: 30)),
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
                          accountName: Text(
                            profile['name'] ?? 'No Name',
                            style: const TextStyle(color: Colors.white),
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
                                  Navigator.pop(context);
                                  Future.delayed(
                                    const Duration(milliseconds: 200),
                                    () {
                                      if (mounted) {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pushNamed('/myprofile');
                                      }
                                    },
                                  );
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

                        // ---------------- Dashboard ----------------
                        _drawerTile(
                          context,
                          FontAwesomeIcons.gaugeHigh,
                          'Dashboard',
                          '/dashboard',
                        ),

                        // ---------------- Wallet ----------------
                        ExpansionTile(
                          leading: const Icon(
                            FontAwesomeIcons.wallet,
                            color: Colors.green,
                          ),
                          title: const Text(
                            'Wallet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.only(left: 30),
                          children: [
                            _drawerTile(
                              context,
                              FontAwesomeIcons.wallet,
                              'My Wallet',
                              '/wallet',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.moneyCheck,
                              'Deposit',
                              '/deposit',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.arrowDown,
                              'Withdraw',
                              '/withdraw',
                            ),
                          ],
                        ),

                        // ---------------- Growup ----------------
                        ExpansionTile(
                          leading: const Icon(
                            FontAwesomeIcons.seedling,
                            color: Colors.green,
                          ),
                          title: const Text(
                            'Growup',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.only(left: 30),
                          children: [
                            _drawerTile(
                              context,
                              FontAwesomeIcons.folderOpen,
                              'Projects',
                              '/projects',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.diagramProject,
                              'Invested Projects',
                              '/myprojects',
                            ),
                          ],
                        ),

                        // ---------------- Invoices ----------------
                        ExpansionTile(
                          leading: const Icon(
                            FontAwesomeIcons.fileInvoiceDollar,
                            color: Colors.green,
                          ),
                          title: const Text(
                            'Invoices',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.only(left: 30),
                          children: [
                            _drawerTile(
                              context,
                              FontAwesomeIcons.fileInvoice,
                              'Growup',
                              '/invoice_growup',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.fileInvoiceDollar,
                              'Recharge',
                              '/invoice_recharge',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.coins,
                              'ROI',
                              '/invoice_roi',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.handHoldingDollar,
                              'Capital Return',
                              '/capital_return',
                            ),
                          ],
                        ),

                        // ---------------- Investment History ----------------
                        _drawerTile(
                          context,
                          FontAwesomeIcons.clockRotateLeft,
                          'Investment History',
                          '/investmenthistory',
                        ),

                        // ---------------- Properties ----------------
                        ExpansionTile(
                          leading: const Icon(
                            FontAwesomeIcons.building,
                            color: Colors.green,
                          ),
                          title: const Text(
                            'Properties',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.only(left: 30),
                          children: [
                            _drawerTile(
                              context,
                              FontAwesomeIcons.building,
                              'Package Details',
                              '/properties',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.bagShopping,
                              'Ordered Properties',
                              '/ordered_properties',
                            ),
                          ],
                        ),

                        // ---------------- Products ----------------
                        ExpansionTile(
                          leading: const Icon(
                            FontAwesomeIcons.box,
                            color: Colors.green,
                          ),
                          title: const Text(
                            'Products',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.only(left: 30),
                          children: [
                            _drawerTile(
                              context,
                              FontAwesomeIcons.box,
                              'All Products',
                              '/products',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.boxOpen,
                              'My Orders',
                              '/myorders',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.truck,
                              'Track My Orders',
                              '/track_orders',
                            ),
                          ],
                        ),

                        // ---------------- Profile ----------------
                        _drawerTile(
                          context,
                          FontAwesomeIcons.user,
                          'Profile',
                          '/profile',
                        ),

                        // ---------------- Certification ----------------
                        ExpansionTile(
                          leading: const Icon(
                            FontAwesomeIcons.certificate,
                            color: Colors.green,
                          ),
                          title: const Text(
                            'Certification',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.only(left: 30),
                          children: [
                            _drawerTile(
                              context,
                              FontAwesomeIcons.fileLines,
                              'TAX Certificate',
                              '/tax_certificate',
                            ),
                            _drawerTile(
                              context,
                              FontAwesomeIcons.coins,
                              'Investment Certificate',
                              '/project_certificate',
                            ),
                          ],
                        ),

                        // ---------------- Miscellaneous ----------------
                        _drawerTile(
                          context,
                          FontAwesomeIcons.circleInfo,
                          'About Us',
                          '/about_us',
                        ),
                        _drawerTile(
                          context,
                          FontAwesomeIcons.newspaper,
                          'News',
                          '/news',
                        ),
                        _drawerTile(
                          context,
                          FontAwesomeIcons.blog,
                          'Blog',
                          '/blogs',
                        ),

                        const Divider(height: 20, thickness: 1, color: Colors.green),

                        // ---------------- Logout ----------------
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

        backgroundColor: Colors.white,

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
                              aspectRatio: 1,
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


              //Growup INVESTMENT BY CATEGORY
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
                              padding: const EdgeInsets.only(top: 8.0),
                              // adjust value as needed
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
                            CategoryGridCard(
                              minCrossAxisCount: 3,
                              maxCrossAxisCount: 3,
                              iconSize: 20,
                              items: [
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

                            const SizedBox(height: 10),

                            CategoryGridCard(
                              minCrossAxisCount: 2,
                              maxCrossAxisCount: 2,
                              iconSize: 22,
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
                                  isLive: true,
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
                                  itemBgColor: Colors.red.shade50,
                                  icon: SvgPicture.asset(
                                    Assets.iconsMach,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.green,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  title: 'Matured Projects',
                                  textColor: Colors.red,
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
                                'PROJECTS\nYOU MAY INVEST',
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
                            return ShariahProjectCarousel(projects: projects);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                //PROPERTIES INVESTMENT BY CATEGORY
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
                                    padding: const EdgeInsets.all(4.0),
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

                        const SizedBox(height: 4),

                        // This is the section with your buttons, it remains unchanged.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CategoryGridCard(
                                minCrossAxisCount: 3,
                                maxCrossAxisCount: 3,
                                iconSize: 18,
                                items: [
                                  CategoryItem(
                                    icon: Icon(
                                      FontAwesomeIcons.city,
                                      color: Colors.green,
                                    ),
                                    title: 'Residential',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ResidencialCityPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  CategoryItem(
                                    icon: Icon(
                                      FontAwesomeIcons.handshake,
                                      color: Colors.green,
                                    ),
                                    title: 'Commercial',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CommercialPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  CategoryItem(
                                    icon: Icon(FontAwesomeIcons.microchip),
                                    title: 'ROSA HiTech City',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const HealthCityPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              SizedBox(height: 16),

                              CategoryGridCard(
                                minCrossAxisCount: 2,
                                maxCrossAxisCount: 2,
                                iconSize: 18,
                                items: [
                                  CategoryItem(
                                    icon: Icon(
                                      FontAwesomeIcons.crown,
                                      color: Colors.green,
                                    ),
                                    title: 'The Royal Eco City',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const RoyalEcoCityPage()),
                                      );
                                    },

                                    subItems: [
                                      CategoryItem(
                                        icon: const Icon(FontAwesomeIcons.tree, color: Colors.green),
                                        title: 'The Royal Agro Eco Tourism',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const EcotourismCityPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      CategoryItem(
                                        icon: const Icon(FontAwesomeIcons.treeCity, color: Colors.green),
                                        title: 'The Royal Palace',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const PalaceCityPage()),
                                          );
                                        },
                                        isLive: false,
                                      ),
                                      CategoryItem(
                                        icon: const Icon(FontAwesomeIcons.chessKing, color: Colors.green),
                                        title: 'The Royal North-Bengal Club',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const NorthCityPage()),
                                          );
                                        },
                                        isLive: false,
                                      ),
                                    ],
                                  ),
                                  CategoryItem(
                                    icon: Icon(FontAwesomeIcons.heartPulse),
                                    title: 'ROSA Health',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                          const HealthCityPage(),
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
                ),

                //  Properties For You (Static cards)
                Container(
                  color: Colors.green.withValues(alpha: .1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 8),
                            child: Text(
                              "PROPERTIES YOU MAY INVEST",
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
                      Divider(thickness: 1, color: Colors.grey, height: 1),
                      SizedBox(height: 16),
                      SizedBox(
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

                            return PropertiesCarouselSection(
                              propertyPackages: propertyPackages,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Transactions
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
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
                ),

                // GrowUp Recent Activities
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16),
                      child: Text(
                        "GrowUp Recent Activities",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 0,
                        top: 0,
                        bottom: 8,
                        right: 0,
                      ),
                      child: AdvertisementSlider(),
                    ),
                  ],
                ),

                // GrowUp Global Insight
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16),
                      child: Text(
                        "GrowUp Global Insight",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 0,
                        top: 0,
                        bottom: 8,
                        right: 0,
                      ),
                      child: GlobalInsightsSlider(),
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
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pushNamed(route);
          }
        });
      },
    );
  }
}
