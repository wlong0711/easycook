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

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())  // ✅ Show loading indicator
          : Padding(
              padding: EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ✅ Profile Picture Update
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : authViewModel.userProfile?["profilePic"] != null &&
                                    authViewModel.userProfile?["profilePic"] != ""
                                ? NetworkImage(authViewModel.userProfile?["profilePic"])
                                : null,
                        child: _selectedImage == null &&
                                (authViewModel.userProfile?["profilePic"] == "" ||
                                    authViewModel.userProfile?["profilePic"] == null)
                            ? Icon(Icons.camera_alt, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "Full Name"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Full name is required";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // ✅ Phone Number Field with Validation
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: "Phone Number"),
                      keyboardType: TextInputType.phone,
                      validator: (value) => Validators.validatePhoneNumber(value ?? ""),
                    ),
                    SizedBox(height: 20),

                    // ✅ Save Changes Button with Validation
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {  // ✅ Ensure validation
                          await authViewModel.updateUserProfile(
                            _nameController.text.trim(),
                            _phoneController.text.trim(),
                          );

                          if (_selectedImage != null) {
                            await authViewModel.updateProfilePicture(_selectedImage!);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Profile updated successfully!")),
                          );

                          Navigator.pop(context, "updated");  // Go back to User Details Screen
                        }
                      },
                      child: Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
