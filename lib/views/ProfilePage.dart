import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:growup_agro/utils/api_constants.dart';
import '../widgets/custom_button.dart';

class InvestorProfilePage extends StatefulWidget {
  const InvestorProfilePage({super.key});

  @override
  State<InvestorProfilePage> createState() => _InvestorProfilePageState();
}

class _InvestorProfilePageState extends State<InvestorProfilePage> {
  // form keys
  final _formKeyInvestor = GlobalKey<FormState>();
  final _formKeyBank = GlobalKey<FormState>();
  final _formKeyMobileBank = GlobalKey<FormState>();
  final _formKeyNominee = GlobalKey<FormState>();

  bool isLoading = true;
  bool isUpdatingInvestor = false;
  bool isUpdatingBank = false;
  bool isUpdatingMobileBanking = false;
  bool isUpdatingNominee = false;

  bool isEditingInvestor = false;
  bool isEditingBank = false;
  bool isEditingMobileBanking = false;
  bool isEditingNominee = false;

  int profileCompletion = 0;
  List<String> missingFields = [];

  List<dynamic> districts = [];
  List<dynamic> allUpazilas = [];
  List<dynamic> filteredUpazilas = [];
  List<dynamic> relations = [];

  int? selectedDistrictId;
  int? selectedUpazilaId;

  String investorCode = '';
  String phone = '';
  String email = '';
  String nid = '';
  String address = '';
  String? nidFrontUrl;
  String? nidBackUrl;
  String? profileImageUrl;

  // Nominee Info
  String nomineeName = '';
  String nomineeContact = '';
  String nomineeNid = '';
  String nomineeAddress = '';
  int? selectedRelationId;
  int? nomineeId;
  String? nomineebankAccountName;
  String? nomineebankName;
  String? nomineebranch;
  String? nomineeaccountNo;

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
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final investor = data['investor'] ?? {};

        setState(() {
          districts = data['dropdown_data']['districts'] ?? [];
          allUpazilas = data['dropdown_data']['upazilas'] ?? [];
          relations = data['dropdown_data']['relations'] ?? [];

          profileImageUrl = investor['image'] != null
              ? 'https://growupagro.tech/storage/${investor['image']}'
              : null;

          nidFrontUrl = investor['nid_front'] != null
              ? 'https://growupagro.tech/storage/${investor['nid_front']}'
              : null;
          nidBackUrl = investor['nid_back'] != null
              ? 'https://growupagro.tech/storage/${investor['nid_back']}'
              : null;

          phone = investor['phone'] ?? '';
          email = investor['email'] ?? '';
          nid = investor['nid'] ?? '';
          address = investor['address'] ?? '';

          selectedDistrictId = investor['district_id'];
          filteredUpazilas = allUpazilas
              .where((u) => u['district_id'] == selectedDistrictId)
              .toList();
          selectedUpazilaId = investor['upazila_id'];

          // nominee info
          final nominee = data['nominee_information'] ?? {};
          nomineeId = nominee['id'];
          nomineeName = nominee['name'] ?? '';
          nomineeContact = nominee['contact'] ?? '';
          nomineeNid = nominee['nid'] ?? '';
          nomineeAddress = nominee['address'] ?? '';
          selectedRelationId =
              nominee['relation']?['id'] ?? (relations.isNotEmpty ? relations.first['id'] : null);
          nomineebankAccountName = nominee['bank_account_name'];
          nomineebankName = nominee['bank_name'];
          nomineebranch = nominee['branch_name'];
          nomineeaccountNo = nominee['account_number'];

          // bank info
          final bankInfo = data['banking_information'] ?? {};
          bankHolder = bankInfo['bank_account_name'] ?? '';
          bankName = bankInfo['bank_name'] ?? '';
          branch = bankInfo['branch_name'] ?? '';
          accountNo = bankInfo['account_number'] ?? '';
          routingNo = bankInfo['routing_no'] ?? '';
          bkash = bankInfo['bkash_number'] ?? 'N/A';
          nagad = bankInfo['nagad_number'] ?? 'N/A';
          rocket = bankInfo['rocket_number'] ?? 'N/A';

          final profileCompletionData = data['profile_completion'];
          profileCompletion = profileCompletionData?['percentage'] ?? 0;
          missingFields = List<String>.from(profileCompletionData?['missing_fields'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      setState(() => isLoading = false);
    }
  }

  // simplified for brevity
  Future<void> updateInvestorInfo() async {
    if (!_formKeyInvestor.currentState!.validate()) return;
    setState(() => isUpdatingInvestor = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isUpdatingInvestor = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Investor info updated"), backgroundColor: Colors.green),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 20),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget buildEditableField(
      String label, String value, Function(String) onChanged, bool editable,
      {TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: editable
          ? TextFormField(
        initialValue: value,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
          Flexible(
              child: Text(value.isNotEmpty ? value : 'N/A',
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget buildSectionCard({
    required IconData icon,
    required String title,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required Future<void> Function() onUpdate,
    required GlobalKey<FormState> formKey,
    required List<Widget> children,
    required bool isLoadingButton,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.black26,
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
                    _buildSectionHeader(icon, title),
                    IconButton(
                      icon: Icon(
                        isEditing ? Icons.close : Icons.edit,
                        color: Colors.green.shade700,
                      ),
                      onPressed: onEditToggle,
                    )
                  ],
                ),
                const SizedBox(height: 12),
                ...children,
                if (isEditing) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: CustomButton(
                      text: "Update",
                      onPressed: isLoadingButton ? null : onUpdate,
                      loading: isLoadingButton,
                      backgroundColor: const Color(0xFF2E7D32),
                      height: 40,
                      borderRadius: 8,
                      fontSize: 13,
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

  Widget buildProfileCompletionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "Profile Completion",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: profileCompletion / 100,
                progressColor: Colors.green,
                backgroundColor: Colors.grey.shade300,
                animation: true,
                circularStrokeCap: CircularStrokeCap.round,
                center: ClipOval(
                  child: profileImageUrl == null
                      ? Image.asset('assets/images/img.png',
                      width: 100, height: 100, fit: BoxFit.cover)
                      : Image.network(profileImageUrl!,
                      width: 100, height: 100, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Image.asset('assets/images/img.png')),
                ),
              ),
              const SizedBox(height: 10),
              Text("$profileCompletion%",
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.black87)),
              if (missingFields.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text("Missing Fields:",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                for (final field in missingFields)
                  Text("⛔ $field",
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  String? requiredValidator(String? val) =>
      val == null || val.trim().isEmpty ? "This field is required" : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text("Investor Profile",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
        onRefresh: fetchInvestorProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20, top: 8),
          child: Column(
            children: [
              buildProfileCompletionCard(),
              buildSectionCard(
                icon: Icons.person_outline,
                title: "Investor Info",
                isEditing: isEditingInvestor,
                onEditToggle: () =>
                    setState(() => isEditingInvestor = !isEditingInvestor),
                onUpdate: updateInvestorInfo,
                formKey: _formKeyInvestor,
                isLoadingButton: isUpdatingInvestor,
                children: [
                  buildEditableField(
                      "Phone", phone, (v) => phone = v, isEditingInvestor,
                      validator: requiredValidator),
                  buildEditableField(
                      "Email", email, (v) => email = v, isEditingInvestor,
                      validator: requiredValidator),
                  buildEditableField("NID", nid, (v) => nid = v,
                      isEditingInvestor,
                      validator: requiredValidator),
                  buildEditableField(
                      "Address", address, (v) => address = v,
                      isEditingInvestor,
                      validator: requiredValidator),
                ],
              ),
              buildSectionCard(
                icon: Icons.account_balance,
                title: "Bank Info",
                isEditing: isEditingBank,
                onEditToggle: () =>
                    setState(() => isEditingBank = !isEditingBank),
                onUpdate: () async {},
                formKey: _formKeyBank,
                isLoadingButton: isUpdatingBank,
                children: [
                  buildEditableField("Holder Name", bankHolder,
                          (v) => bankHolder = v, isEditingBank),
                  buildEditableField(
                      "Bank Name", bankName, (v) => bankName = v,
                      isEditingBank),
                  buildEditableField(
                      "Branch", branch, (v) => branch = v, isEditingBank),
                  buildEditableField("Account No", accountNo,
                          (v) => accountNo = v, isEditingBank),
                  buildEditableField("Routing No", routingNo,
                          (v) => routingNo = v, isEditingBank),
                ],
              ),
              buildSectionCard(
                icon: Icons.phone_android,
                title: "Mobile Banking",
                isEditing: isEditingMobileBanking,
                onEditToggle: () => setState(
                        () => isEditingMobileBanking = !isEditingMobileBanking),
                onUpdate: () async {},
                formKey: _formKeyMobileBank,
                isLoadingButton: isUpdatingMobileBanking,
                children: [
                  buildEditableField("Bkash", bkash,
                          (v) => bkash = v, isEditingMobileBanking),
                  buildEditableField("Nagad", nagad,
                          (v) => nagad = v, isEditingMobileBanking),
                  buildEditableField("Rocket", rocket,
                          (v) => rocket = v, isEditingMobileBanking),
                ],
              ),
              buildSectionCard(
                icon: Icons.group_outlined,
                title: "Nominee Info",
                isEditing: isEditingNominee,
                onEditToggle: () =>
                    setState(() => isEditingNominee = !isEditingNominee),
                onUpdate: () async {},
                formKey: _formKeyNominee,
                isLoadingButton: isUpdatingNominee,
                children: [
                  buildEditableField("Name", nomineeName,
                          (v) => nomineeName = v, isEditingNominee),
                  buildEditableField("Contact", nomineeContact,
                          (v) => nomineeContact = v, isEditingNominee),
                  buildEditableField("NID", nomineeNid,
                          (v) => nomineeNid = v, isEditingNominee),
                  buildEditableField("Address", nomineeAddress,
                          (v) => nomineeAddress = v, isEditingNominee),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
