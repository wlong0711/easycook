import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();  
  File? _selectedImage;
  bool _isLoading = true;  // ✅ Add loading flag

  @override
  void initState() {
    super.initState();
    _loadUserProfile();  // ✅ Load profile data safely
  }

  Future<void> _loadUserProfile() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    await authViewModel.fetchUserProfile();  // Ensure profile data is fetched

    if (mounted) {
      setState(() {
        _nameController.text = authViewModel.userProfile?["fullName"] ?? "";
        _phoneController.text = authViewModel.userProfile?["phoneNumber"] ?? "";
        _isLoading = false;  // ✅ Set loading to false when data is ready
      });
    }
  }

  // ✅ Pick Image from Gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
  if (_formKey.currentState!.validate()) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(width: 20),
              Text("Saving...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.updateUserProfile(
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      if (_selectedImage != null) {
        await authViewModel.updateProfilePicture(_selectedImage!, context);
      }

      Navigator.of(context).pop(); // Close loader

      // Success dialog
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text("Success!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Profile updated successfully.", textAlign: TextAlign.center),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.pop(context, "updated");
                  },
                  child: Text("OK"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loader
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text("Error", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Something went wrong. Please try again.", textAlign: TextAlign.center),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 📸 Profile Picture with tap-to-change and border
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.orange.shade200],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (authViewModel.userProfile?["profilePic"] != null &&
                                        authViewModel.userProfile?["profilePic"] != "")
                                    ? NetworkImage(authViewModel.userProfile!["profilePic"])
                                    : null,
                            child: (_selectedImage == null &&
                                    (authViewModel.userProfile?["profilePic"] == "" ||
                                        authViewModel.userProfile?["profilePic"] == null))
                                ? Icon(Icons.person, size: 60, color: Colors.orange)
                                : null,
                          ),
                        ),
                        Positioned(
                          child: InkWell(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.camera_alt, color: Colors.orange),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),

                    // 👤 Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? "Full name is required" : null,
                    ),
                    SizedBox(height: 16),

                    // 📞 Phone Number
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => Validators.validatePhoneNumber(value ?? ""),
                    ),
                    SizedBox(height: 30),

                    // ✅ Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: Icon(Icons.save),
                        label: Text("Save Changes", style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
