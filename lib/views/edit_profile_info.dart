import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
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

  // Controllers for text fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Password controllers
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _updatingProfile = false;
  bool _changingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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
    // final url = Uri.parse("${ApiConstants.investorProfile}?investor_code=$investorCode");
    final response = await http.get(
      Uri.parse('https://growupagro.tech/api/investor/profile?investor_code=$investorCode'),
      // url,
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
          content: Text(
            'Failed to load profile',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red, // 🔴 red background for error
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
    // final uri = Uri.parse(ApiConstants.updateProfileInfo);
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    request.fields['investor_code'] = investorCode;

    if (fullNameController.text.trim().isNotEmpty) {
      request.fields['name'] = fullNameController.text.trim();
    }
    if (emailController.text.trim().isNotEmpty) {
      request.fields['email'] = emailController.text.trim();
    }
    if (phoneController.text.trim().isNotEmpty) {
      request.fields['phone'] = phoneController.text.trim();
    }

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', profileImage!.path));
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: $respStr');

      setState(() => _updatingProfile = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        // ✅ Refresh latest profile data from server
        await _loadProfileData();

        // ✅ Save updated name/email/phone in SharedPreferences for dashboard
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('investor_name', fullNameController.text.trim());
        await prefs.setString('investor_email', emailController.text.trim());
        await prefs.setString('investor_phone', phoneController.text.trim());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $respStr'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _updatingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _changePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      _passwordFormKey.currentState!.save();

      final currentPassword = currentPasswordController.text;
      final newPassword = newPasswordController.text;
      final confirmPassword = confirmPasswordController.text;

      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _changingPassword = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorIdString = prefs.getString('investor_id');

      if (token.isEmpty || investorIdString == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error: Missing token or user ID'), backgroundColor: Colors.red),
        );
        return;
      }

      final id = int.tryParse(investorIdString);
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user ID format'), backgroundColor: Colors.red),
        );
        return;
      }

      final url = Uri.parse(
          'https://growupagro.tech/api/change-password');
      final response = await http.post(
        // Uri.parse(ApiConstants.changePassword),
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "id": id,
          "current_password": currentPassword,
          "new_password": newPassword,
          "new_password_confirmation": confirmPassword,
        }),
      );

      setState(() => _changingPassword = false);

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Password updated successfully'), backgroundColor: Colors.green),
        );
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        _passwordFormKey.currentState!.reset();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update password'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (val) =>
        (val == null || val.trim().isEmpty) ? 'This field is required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Form
            Form(
              key: _formKey,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Edit Profile Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundImage: profileImage != null
                              ? FileImage(profileImage!)
                              : (profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage('assets/images/img.png')) as ImageProvider,
                          child: const Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(Icons.camera_alt, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(label: 'Full Name', controller: fullNameController),
                      _buildTextField(label: 'Email Address', controller: emailController, keyboardType: TextInputType.emailAddress),
                      _buildTextField(label: 'Phone Number', controller: phoneController, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _updatingProfile ? null : _submitProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          backgroundColor: Colors.green,
                        ),
                        child: _updatingProfile
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Update Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Password Form
            Form(
              key: _passwordFormKey,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: const Text('Change Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField('Current Password', currentPasswordController, _obscureCurrentPassword, () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      }),
                      _buildPasswordField('New Password', newPasswordController, _obscureNewPassword, () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      }),
                      _buildPasswordField('Confirm New Password', confirmPasswordController, _obscureConfirmPassword, () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      }),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _changingPassword ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          backgroundColor: Colors.blue,
                        ),
                        child: _changingPassword
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Change Password',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscure, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (val) => (val == null || val.trim().isEmpty) ? 'This field is required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
