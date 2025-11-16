import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/investor_profile_model.dart';

class InvestorProfilePage extends StatefulWidget {
  const InvestorProfilePage({super.key});

  @override
  _InvestorProfilePageState createState() => _InvestorProfilePageState();
}

class _InvestorProfilePageState extends State<InvestorProfilePage> {
  final _formKeyInvestor = GlobalKey<FormState>();
  final _formKeyBank = GlobalKey<FormState>();
  final _formKeyMobileBank = GlobalKey<FormState>();
  final _formKeyNominee = GlobalKey<FormState>();
  InvestorProfileResponse? investorProfile;

  bool isLoading = true;
  String? profileImageUrl;

  int _selectedIndex = 0;
  final List<Widget> _pages = [
    // MenuPage(),       // index 0
    // GrowupPage(),     // index 1
    // PropertyPage(),   // index 2
    // TradingPage(),    // index 3
    // WebTabPage(),     // index 4 <-- this shows your WebView
  ];

  // loading indicator for all update buttons
  bool isUpdatingInvestor = false;
  bool isUpdatingBank = false;
  bool isUpdatingMobileBanking = false;
  bool isUpdatingNominee = false;

  // Edit mode flags for each section
  bool isEditingInvestor = false;
  bool isEditingBank = false;
  bool isEditingMobileBanking = false;
  bool isEditingNominee = false;

  // Profile completion
  int profileCompletion = 0;
  List<String> missingFields = [];

  // Dropdown data
  List<dynamic> districts = [];
  List<dynamic> upazilas = [];
  List<dynamic> allUpazilas = [];
  List<dynamic> filteredUpazilas = [];
  List<dynamic> relations = [];

  int? selectedDistrictId;
  int? selectedUpazilaId;

  // Investor Info
  String investorCode = '';
  String phone = '';
  String email = '';
  String nid = '';
  String address = '';
  String? nidFrontUrl;
  String? nidBackUrl;

  // Nominee Info
  String nomineeName = '';
  String nomineeContact = '';
  String nomineeNid = '';
  String nomineeAddress = '';
  int? selectedRelationId;
  int? nomineeId;
  String nomineeBankHolder = '';
  String nomineeBankName = '';
  String nomineeBranch = '';
  String nomineeAccountNo = '';
  String nomineeBkash = '';
  String nomineeNagad = '';
  String nomineeRocket = '';


  // Bank Info
  String bankHolder = '';
  String bankName = '';
  String branch = '';
  String accountNo = '';
  String routingNo = '';

  // Mobile Banking
  String bkash = 'N/A';
  String nagad = 'N/A';
  String rocket = 'N/A';

  File? nidFrontFile;
  File? nidBackFile;

  @override
  void initState() {
    super.initState();
    fetchInvestorProfile();
  }

  Future<void> fetchInvestorProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.investorProfile(investorCode));

    try {
      setState(() => isLoading = true);
      print('Sending investor_code: $investorCode');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];

        setState(() {
          // Load dropdown data
          districts = data['dropdown_data']['districts'] ?? [];
          allUpazilas = data['dropdown_data']['upazilas'] ?? [];
          relations = data['dropdown_data']['relations'] ?? [];

          // Investor Info
          final investor = data['investor'] ?? {};
          profileImageUrl = investor['image'] != null
              ? 'https://growupagro.tech/storage/${investor['image']}'
              : null;

          // ✅ Correct NID keys
          nidFrontUrl =
          (investor['nid_front'] != null &&
              investor['nid_front'].toString().isNotEmpty)
              ? 'https://growupagro.tech/storage/${investor['nid_front']}'
              : null;

          nidBackUrl =
          (investor['nid_back'] != null &&
              investor['nid_back'].toString().isNotEmpty)
              ? 'https://growupagro.tech/storage/${investor['nid_back']}'
              : null;

          // Debug prints
          print('NID Front URL: $nidFrontUrl');
          print('NID Back URL: $nidBackUrl');

          // Investor fields
          phone = investor['phone'] ?? '';
          email = investor['email'] ?? '';
          nid = investor['nid'] ?? '';
          address = investor['address'] ?? '';

          // District
          selectedDistrictId = investor['district_id'] != null
              ? int.tryParse(investor['district_id'].toString())
              : null;

          if (selectedDistrictId == null && districts.isNotEmpty) {
            selectedDistrictId = int.tryParse(districts.first['id'].toString());
          }

          // Filter upazilas for this district
          filteredUpazilas = allUpazilas
              .where(
                (u) =>
            u['district_id'].toString() ==
                selectedDistrictId.toString(),
          )
              .toList();

          selectedUpazilaId = investor['upazila_id'] != null
              ? int.tryParse(investor['upazila_id'].toString())
              : null;

          if (selectedUpazilaId == null ||
              !filteredUpazilas.any((u) => u['id'] == selectedUpazilaId)) {
            selectedUpazilaId = filteredUpazilas.isNotEmpty
                ? filteredUpazilas.first['id']
                : null;
          }

          // Nominee Info
          final nominee = data['nominee_information'] ?? {};
          nomineeId = nominee['id'];
          nomineeName = nominee['name'] ?? '';
          nomineeContact = nominee['contact'] ?? '';
          nomineeNid = nominee['nid'] ?? '';
          nomineeAddress = nominee['address'] ?? '';
          selectedRelationId = nominee['relation'] != null
              ? int.tryParse(nominee['relation']['id'].toString())
              : null;

          if (selectedRelationId == null && relations.isNotEmpty) {
            selectedRelationId = int.tryParse(relations.first['id'].toString());
          }



          // Bank Info
          final bankInfo = data['banking_information'] ?? {};
          bankHolder = bankInfo['bank_account_name'] ?? '';
          bankName = bankInfo['bank_name'] ?? '';
          branch = bankInfo['branch_name'] ?? '';
          accountNo = bankInfo['account_number'] ?? '';
          routingNo = bankInfo['routing_no'] ?? '';
          bkash = bankInfo['bkash_number'] ?? 'N/A';
          nagad = bankInfo['nagad_number'] ?? 'N/A';
          rocket = bankInfo['rocket_number'] ?? 'N/A';

          // Nominee Bank Info
          final nomineeBank = data['nominee_bank'] ?? {};
          nomineeBankHolder = nomineeBank['bank_account_name'] ?? '';
          nomineeBankName = nomineeBank['bank_name'] ?? '';
          nomineeBranch = nomineeBank['branch_name'] ?? '';
          nomineeAccountNo = nomineeBank['account_number'] ?? '';
          nomineeBkash = nomineeBank['bkash_number'] ?? 'N/A';
          nomineeNagad = nomineeBank['nagad_number'] ?? 'N/A';
          nomineeRocket = nomineeBank['rocket_number'] ?? 'N/A';


          // Profile completion
          final profileCompletionData = data['profile_completion'];
          profileCompletion = profileCompletionData != null
              ? profileCompletionData['percentage'] ?? 0
              : 0;

          missingFields = profileCompletionData != null
              ? List<String>.from(
            (profileCompletionData['missing_fields'] ?? [])
                .whereType<String>(),
          )
              : [];

          isLoading = false;
        });
      } else {
        print('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateInvestorInfo() async {
    if (!_formKeyInvestor.currentState!.validate()) return;
    setState(() => isUpdatingInvestor = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final url = Uri.parse(ApiConstants.updateInvestorInfo);

      // Prepare multipart request
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add regular text fields
      request.fields['investor_code'] = investorCode;
      request.fields['phone'] = phone;
      request.fields['email'] = email;
      request.fields['district_id'] = selectedDistrictId?.toString() ?? '';
      request.fields['upazila_id'] = selectedUpazilaId?.toString() ?? '';
      request.fields['nid'] = nid;
      request.fields['address'] = address;

      // ✅ Add NID front image if user selected a new one
      if (nidFrontFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('nid_front', nidFrontFile!.path),
        );
      }

      // ✅ Add NID back image if user selected a new one
      if (nidBackFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('nid_back', nidBackFile!.path),
        );
      }

      // Send request
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final result = json.decode(responseData.body);

      if (response.statusCode == 200 && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investor info updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          isEditingInvestor = false;
        });

        // Optionally refresh profile
        await fetchInvestorProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Update failed: ${result['message'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isUpdatingInvestor = false);
    }
  }

  Future<void> pickNidFront() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        nidFrontFile = File(picked.path);
      });
    }
  }

  Future<void> pickNidBack() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        nidBackFile = File(picked.path);
      });
    }
  }

  Future<void> updateNomineeInfo() async {
    if (!_formKeyNominee.currentState!.validate()) return;
    setState(() => isUpdatingNominee = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final body = {
        'investor_code': investorCode,
        'name': nomineeName,
        'contact': nomineeContact,
        'nid': nomineeNid,
        'relation': selectedRelationId?.toString() ?? '',
        'address': nomineeAddress,
        'nominee_bank_account_name': nomineeBankHolder,
        'nominee_bank_name': nomineeBankName,
        'nominee_branch_name': nomineeBranch,
        'nominee_account_number': nomineeAccountNo,
      };

      // Include nominee_id if updating
      if (nomineeId != null) {
        body['nominee_id'] = nomineeId.toString();
      }

      final url = Uri.parse(
        nomineeId == null
            ? ApiConstants.createNomineeInfo()
            : ApiConstants.updateNomineeInfo,
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final result = json.decode(response.body);

      if ((result['success'] ?? false) ||
          result['message'] == "Nominee information saved successfully") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nomineeId == null
                  ? 'Nominee info created successfully!'
                  : 'Nominee info updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Save newly created nominee ID
        if (nomineeId == null && result['nominee'] != null) {
          setState(() {
            nomineeId = result['nominee']['id'];
          });
        }

        setState(() {
          isEditingNominee = false;
        });
      } else {
        throw Exception(result['message'] ?? 'Nominee update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isUpdatingNominee = false);
    }
  }

  Future<void> updateBankInfo() async {
    if (!_formKeyBank.currentState!.validate()) return;
    setState(() => isUpdatingBank = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final url = Uri.parse(ApiConstants.updateBankInfo);

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "investor_code": investorCode,
          "bank_account_name": bankHolder,
          "bank_name": bankName,
          "branch_name": branch,
          "account_number": accountNo,
          "routing_no": routingNo,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank Info updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          isEditingBank = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Bank info update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isUpdatingBank = false);
    }
  }

  Future<void> updateMobileBankingInfo() async {
    if (!_formKeyMobileBank.currentState!.validate()) return;
    setState(() => isUpdatingMobileBanking = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final url = Uri.parse(ApiConstants.updateMobileBankingInfo);

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "investor_code": investorCode,
          "bkash_number": bkash,
          "rocket_number": rocket,
          "nagad_number": nagad,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mobile Banking Info updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          isEditingMobileBanking = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Mobile banking update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isUpdatingMobileBanking = false);
    }
  }

  Widget buildProfileCompletionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔹 Title Row
              Row(
                children: const [
                  Text(
                    "Profile Completion",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔹 Circular Progress + Profile Image
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularPercentIndicator(
                      radius: 65.0,
                      lineWidth: 10.0,
                      percent: (profileCompletion / 100).clamp(0.0, 1.0),
                      progressColor: Colors.green,
                      backgroundColor: Colors.grey.shade300,
                      animation: true,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: ClipOval(
                        child:
                        profileImageUrl == null || profileImageUrl!.isEmpty
                            ? Image.asset(
                          'assets/images/img.png',
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        )
                            : Image.network(
                          profileImageUrl!,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/img.png',
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),

                    // 🔹 Percentage Overlay
                    Positioned(
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${profileCompletion.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              //Missing Fields / Complete Message
              if (missingFields.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upload missing information to complete your profile!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...missingFields.map(
                            (field) => Text(
                          "• $field",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        "Profile is fully completed!",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionCard({
    required String title,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required Future<void> Function() onUpdate,
    required GlobalKey<FormState> formKey,
    required List<Widget> children,
    required bool isLoadingButton, // NEW
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isEditing ? Icons.close : Icons.edit,
                        color: Colors.grey,
                      ),
                      onPressed: onEditToggle,
                    ),
                  ],
                ),
                Divider(height: 1),
                const SizedBox(height: 12),
                ...children,
                if (isEditing) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, // full width
                    child: ElevatedButton(
                      onPressed: onUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Set green color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isLoadingButton
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : const Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEditableField(
      String label,
      String value,
      Function(String) onChanged,
      bool editable, {
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: editable
          ? TextFormField(
        initialValue: value,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        onChanged: onChanged,
        validator: validator,
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Flexible(
            child: Text(
              (value.isNotEmpty && value.toUpperCase() != "NULL")
                  ? value
                  : 'N/A',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\d{10,15}$'); // Adjust pattern as needed
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Investor Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchInvestorProfile,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(), // Important to allow pull-down
          padding: const EdgeInsets.only(bottom: 20, top: 8),
          child: Column(
            children: [
              IndexedStack(index: _selectedIndex, children: _pages),
              buildProfileCompletionCard(),

              // Investor Info Section
              buildSectionCard(
                title: 'Investor Info',
                isEditing: isEditingInvestor,
                onEditToggle: () {
                  setState(() {
                    isEditingInvestor = !isEditingInvestor;
                  });
                },
                onUpdate: updateInvestorInfo,
                formKey: _formKeyInvestor,
                isLoadingButton: isUpdatingInvestor,
                children: [
                  buildEditableField(
                    'Phone',
                    phone,
                        (val) => setState(() => phone = val),
                    isEditingInvestor,
                    keyboardType: TextInputType.phone,
                    validator: phoneValidator,
                  ),
                  buildEditableField(
                    'Email',
                    email,
                        (val) => setState(() => email = val),
                    isEditingInvestor,
                    keyboardType: TextInputType.emailAddress,
                    validator: emailValidator,
                  ),
                  // District dropdown
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'District',
                    ),
                    value:
                    districts.any(
                          (d) =>
                      int.tryParse(d['id'].toString()) ==
                          selectedDistrictId,
                    )
                        ? selectedDistrictId
                        : null,
                    items: districts.map((d) {
                      return DropdownMenuItem<int>(
                        value: int.tryParse(d['id'].toString()),
                        child: Text(d['name']),
                      );
                    }).toList(),
                    onChanged: isEditingInvestor
                        ? (val) {
                      setState(() {
                        selectedDistrictId = val;

                        // Filter upazilas for this district
                        filteredUpazilas = allUpazilas
                            .where(
                              (u) =>
                          u['district_id'].toString() ==
                              val.toString(),
                        )
                            .toList();

                        // Select first upazila automatically if available
                        selectedUpazilaId =
                        filteredUpazilas.isNotEmpty
                            ? filteredUpazilas.first['id']
                            : null;
                      });
                    }
                        : null,
                  ),

                  SizedBox(height: 16),

                  // Upazila dropdown
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Upazila',
                    ),
                    value:
                    filteredUpazilas.any(
                          (u) => u['id'] == selectedUpazilaId,
                    )
                        ? selectedUpazilaId
                        : null,
                    items: filteredUpazilas.map((u) {
                      return DropdownMenuItem<int>(
                        value: u['id'],
                        child: Text(u['name']),
                      );
                    }).toList(),
                    onChanged: isEditingInvestor
                        ? (val) => setState(() => selectedUpazilaId = val)
                        : null,
                    validator: null, // <- no validation if optional
                  ),

                  SizedBox(height: 16),

                  // NID Front & Back Images (always visible)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ✅ NID Front
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'NID Front',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ✅ Show image (from API or new file)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: nidFrontFile != null
                                    ? Image.file(
                                  nidFrontFile!,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                                    : Image.network(
                                  nidFrontUrl ??
                                      'https://via.placeholder.com/150?text=NID+Front',
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(
                                        width: double.infinity,
                                        height: 120,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ✅ Upload Button
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomButton(
                                  text: "Upload NID Front",
                                  icon: Icons.upload,
                                  onPressed: pickNidFront,
                                  backgroundColor: Colors.green[300]!, // same color as before
                                  textColor: Colors.white,
                                  height: 30, // match your previous height
                                  borderRadius: 8, // rounded corners
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  horizontalPadding: 16,
                                  verticalPadding: 0,
                                  useExtraRoundedCorners: false,
                                  isRound: false,
                                ),
                              ),

                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ✅ NID Back
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'NID Back',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ✅ Show image (from API or new file)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: nidBackFile != null
                                    ? Image.file(
                                  nidBackFile!,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                                    : Image.network(
                                  nidBackUrl ??
                                      'https://via.placeholder.com/150?text=NID+Back',
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(
                                        width: double.infinity,
                                        height: 120,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ✅ Upload Button
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomButton(
                                  text: "Upload NID Back",
                                  icon: Icons.upload, // same icon
                                  onPressed: pickNidBack,
                                  backgroundColor: Colors.green[300]!, // same as your button color
                                  textColor: Colors.white,
                                  height: 30, // same height you wanted
                                  borderRadius: 8, // subtle round corners
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  horizontalPadding: 16,
                                  verticalPadding: 0,
                                  useExtraRoundedCorners: false,
                                  isRound: false,
                                ),
                              ),


                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  buildEditableField(
                    'NID Number',
                    nid,
                        (val) => setState(() => nid = val),
                    isEditingInvestor,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Address',
                    address,
                        (val) => setState(() => address = val),
                    isEditingInvestor,
                    validator: requiredValidator,
                  ),
                ],
              ),

              // Bank Info Section
              buildSectionCard(
                title: 'Bank Info',
                isEditing: isEditingBank,
                onEditToggle: () {
                  setState(() {
                    isEditingBank = !isEditingBank;
                  });
                },
                onUpdate: updateBankInfo,
                formKey: _formKeyBank,
                isLoadingButton: isUpdatingBank,
                children: [
                  buildEditableField(
                    'Holder Name',
                    bankHolder,
                        (val) => setState(() => bankHolder = val),
                    isEditingBank,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Bank Name',
                    bankName,
                        (val) => setState(() => bankName = val),
                    isEditingBank,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Branch',
                    branch,
                        (val) => setState(() => branch = val),
                    isEditingBank,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Account No',
                    accountNo,
                        (val) => setState(() => accountNo = val),
                    isEditingBank,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Routing No',
                    routingNo,
                        (val) => setState(() => routingNo = val),
                    isEditingBank,
                    validator: requiredValidator,
                  ),
                ],
              ),

              // Mobile Banking Section
              buildSectionCard(
                title: 'Mobile Banking',
                isEditing: isEditingMobileBanking,
                onEditToggle: () {
                  setState(() {
                    isEditingMobileBanking = !isEditingMobileBanking;
                  });
                },
                onUpdate: updateMobileBankingInfo,
                formKey: _formKeyMobileBank,
                isLoadingButton: isUpdatingMobileBanking,
                children: [
                  buildEditableField(
                    'Bkash',
                    bkash,
                        (val) => setState(() => bkash = val),
                    isEditingMobileBanking,
                    validator: (val) {
                      if (isEditingMobileBanking) {
                        if ((bkash == 'N/A' || bkash.trim().isEmpty) &&
                            (nagad == 'N/A' || nagad.trim().isEmpty) &&
                            (rocket == 'N/A' || rocket.trim().isEmpty)) {
                          return 'At least one mobile banking number is required';
                        }
                      }
                      return null;
                    },
                  ),
                  buildEditableField(
                    'Nagad',
                    nagad,
                        (val) => setState(() => nagad = val),
                    isEditingMobileBanking,
                    validator: (val) {
                      if (isEditingMobileBanking) {
                        if ((bkash == 'N/A' || bkash.trim().isEmpty) &&
                            (nagad == 'N/A' || nagad.trim().isEmpty) &&
                            (rocket == 'N/A' || rocket.trim().isEmpty)) {
                          return 'At least one mobile banking number is required';
                        }
                      }
                      return null;
                    },
                  ),
                  buildEditableField(
                    'Rocket',
                    rocket,
                        (val) => setState(() => rocket = val),
                    isEditingMobileBanking,
                    validator: (val) {
                      if (isEditingMobileBanking) {
                        if ((bkash == 'N/A' || bkash.trim().isEmpty) &&
                            (nagad == 'N/A' || nagad.trim().isEmpty) &&
                            (rocket == 'N/A' || rocket.trim().isEmpty)) {
                          return 'At least one mobile banking number is required';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),

              // Nominee Info Section
              buildSectionCard(
                title: 'Nominee Info',
                isEditing: isEditingNominee,
                onEditToggle: () {
                  setState(() {
                    isEditingNominee = !isEditingNominee;
                  });
                },
                onUpdate: updateNomineeInfo,
                formKey: _formKeyNominee,
                isLoadingButton: isUpdatingNominee,
                children: [
                  buildEditableField(
                    'Name',
                    nomineeName,
                        (val) => setState(() => nomineeName = val),
                    isEditingNominee,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Contact',
                    nomineeContact,
                        (val) => setState(() => nomineeContact = val),
                    isEditingNominee,
                    validator: phoneValidator,
                  ),
                  buildEditableField(
                    'NID Number',
                    nomineeNid,
                        (val) => setState(() => nomineeNid = val),
                    isEditingNominee,
                    validator: requiredValidator,
                  ),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Relation',
                    ),
                    value:
                    relations.any(
                          (r) => r['id'] == selectedRelationId,
                    )
                        ? selectedRelationId
                        : null,
                    items: relations
                        .map<DropdownMenuItem<int>>((r) {
                      final id = r['id'] as int?;
                      final name = r['name'] as String? ?? 'Unknown';
                      if (id == null) {
                        // Skip this item if id is null to avoid errors
                        // return null;
                      }
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(name),
                      );
                    })
                        .whereType<DropdownMenuItem<int>>()
                        .toList(),

                    onChanged: isEditingNominee
                        ? (val) =>
                        setState(() => selectedRelationId = val)
                        : null,
                    validator: (value) =>
                    value == null ? 'Please select a relation' : null,
                  ),
                  SizedBox(height: 8),

                  buildEditableField(
                    'Address',
                    nomineeAddress,
                        (val) => setState(() => nomineeAddress = val),
                    isEditingNominee,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Account Holder Name',
                    nomineeBankHolder ?? '',
                        (val) => setState(() => nomineeBankHolder = val),
                    isEditingNominee,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Bank Name',
                    nomineeBankName ?? '',
                        (val) => setState(() => nomineeBankName = val),
                    isEditingNominee,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Branch Name',
                    nomineeBranch ?? '',
                        (val) => setState(() => nomineeBranch = val),
                    isEditingNominee,
                    validator: requiredValidator,
                  ),
                  buildEditableField(
                    'Account Number',
                    nomineeAccountNo ?? '',
                        (val) => setState(() => nomineeAccountNo = val),
                    isEditingNominee,
                    validator: requiredValidator,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
