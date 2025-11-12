import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:growup_agro/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String investorCode = '';
  File? profileImage;
  String? profileImageUrl;

  // Text controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // Password controllers
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _updatingProfile = false;
  bool _changingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    investorCode = prefs.getString('investor_code') ?? '';

    final response = await http.get(
      Uri.parse('https://growupagro.tech/api/investor/profile?investor_code=$investorCode'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final investor = data['data']['investor'];
      setState(() {
        fullNameController.text = investor['name'] ?? '';
        emailController.text = investor['email'] ?? '';
        phoneController.text = investor['phone'] ?? '';
        profileImageUrl = investor['image'] != null
            ? 'https://growupagro.tech/storage/${investor['image']}'
            : null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _updatingProfile = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final uri = Uri.parse('https://growupagro.tech/api/investor/profile/investor-info/update');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['investor_code'] = investorCode
      ..fields['name'] = fullNameController.text.trim()
      ..fields['email'] = emailController.text.trim()
      ..fields['phone'] = phoneController.text.trim();

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', profileImage!.path));
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      setState(() => _updatingProfile = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        _loadProfileData();
      } else {
        debugPrint('Error: $respStr');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: Something went wrong'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _updatingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Something went wrong'), backgroundColor: Colors.red),
      );

    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorIdString = prefs.getString('investor_id');
    if (investorIdString == null) return;

    setState(() => _changingPassword = true);
    final id = int.tryParse(investorIdString);

    final url = Uri.parse('https://growupagro.tech/api/change-password');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "id": id,
        "current_password": currentPasswordController.text,
        "new_password": newPasswordController.text,
        "new_password_confirmation": confirmPasswordController.text,
      }),
    );

    setState(() => _changingPassword = false);
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildProfileForm(),
            const SizedBox(height: 25),
            _buildPasswordSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 150,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
          ),
        ),
        Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                backgroundImage: profileImage != null
                    ? FileImage(profileImage!)
                    : (profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : const AssetImage('assets/images/img.png')) as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.black87),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              fullNameController.text.isEmpty ? "Investor" : fullNameController.text,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Input fields with border
            _buildInput('Full Name', fullNameController, TextInputType.name),
            _buildInput('Email Address', emailController, TextInputType.emailAddress),
            _buildInput('Phone Number', phoneController, TextInputType.phone),
            const SizedBox(height: 16),

            // ✅ Centered Update Button
            Center(
              child: CustomButton(
                text: "Update Profile",
                onPressed: _updatingProfile ? null : _submitProfile,
                loading: _updatingProfile,
                backgroundColor: const Color(0xFF2E7D32),
                height: 40,
                borderRadius: 8,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      [TextInputType type = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Form(
      key: _passwordFormKey,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Input fields with visible borders
            _buildPasswordField(
                'Current Password', currentPasswordController, _obscureCurrent, () {
              setState(() => _obscureCurrent = !_obscureCurrent);
            }),
            _buildPasswordField(
                'New Password', newPasswordController, _obscureNew, () {
              setState(() => _obscureNew = !_obscureNew);
            }),
            _buildPasswordField(
                'Confirm Password', confirmPasswordController, _obscureConfirm, () {
              setState(() => _obscureConfirm = !_obscureConfirm);
            }),
            const SizedBox(height: 16),

            // ✅ Centered CustomButton
            Center(
              child: CustomButton(
                text: "Change Password",
                onPressed: _changingPassword ? null : _changePassword,
                loading: _changingPassword,
                backgroundColor: Colors.blueAccent,
                height: 40,
                borderRadius: 8,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      String label, TextEditingController controller, bool obscure, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }

}
