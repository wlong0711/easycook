import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userProfile = authViewModel.userProfile;

    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text("User Details"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: userProfile == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 👤 Profile Picture
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.orange.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: (userProfile["profilePic"] != null &&
                                userProfile["profilePic"] != "")
                            ? NetworkImage(userProfile["profilePic"])
                            : null,
                        child: (userProfile["profilePic"] == null ||
                                userProfile["profilePic"] == "")
                            ? Icon(Icons.person, size: 60, color: Colors.orange)
                            : null,
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // 🧾 Info Cards
                  _buildInfoTile(Icons.person, "Full Name", userProfile["fullName"] ?? "No Name"),
                  _buildInfoTile(Icons.phone, "Phone Number", userProfile["phoneNumber"] ?? "No Phone Number"),
                  _buildInfoTile(Icons.email, "Email Address", authViewModel.user?.email ?? "No Email"),

                  SizedBox(height: 30),

                  // ✏️ Edit Profile
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen()),
                      );
                    },
                    icon: Icon(Icons.edit),
                    label: Text("Edit Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  SizedBox(height: 20),

                  // 🔓 Logout
                  ElevatedButton.icon(
                    onPressed: () async {
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
                                Icon(Icons.logout, size: 48, color: Colors.red),
                                SizedBox(height: 16),
                                Text("Confirm Logout", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text(
                                  "Are you sure you want to log out from your account?",
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text("Cancel"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey[700],
                                        side: BorderSide(color: Colors.grey),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop(); // Close dialog
                                        await authViewModel.signOut();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => LoginScreen()),
                                        );
                                      },
                                      child: Text("Log Out"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.logout, color: Colors.white),
                    label: Text("Log Out", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // 🔧 Custom tile builder for cleaner layout
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Text(label),
      ),
    );
  }
}
