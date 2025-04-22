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
      appBar: AppBar(
        title: Text("User Details"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: userProfile == null
          ? Center(child: CircularProgressIndicator())  // Loading indicator
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Profile picture with null-safe check
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: (userProfile["profilePic"] != null &&
                              userProfile["profilePic"] != "")
                          ? NetworkImage(userProfile["profilePic"])
                          : null,
                      child: (userProfile["profilePic"] == null ||
                              userProfile["profilePic"] == "")
                          ? Icon(Icons.person, size: 80, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(height: 20),

                  // ✅ Full Name
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.orange),
                    title: Text(userProfile["fullName"] ?? "No Name"),
                    subtitle: Text("Full Name"),
                  ),

                  // ✅ Phone Number
                  ListTile(
                    leading: Icon(Icons.phone, color: Colors.orange),
                    title: Text(userProfile["phoneNumber"] ?? "No Phone Number"),
                    subtitle: Text("Phone Number"),
                  ),

                  // ✅ Email
                  ListTile(
                    leading: Icon(Icons.email, color: Colors.orange),
                    title: Text(authViewModel.user?.email ?? "No Email"),
                    subtitle: Text("Email Address"),
                  ),

                  SizedBox(height: 20),

                  // ✅ Edit Profile Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen()),
                      );
                    },
                    child: Text("Edit Profile"),
                  ),
                  
                  SizedBox(height: 20),

                  // ✅ Logout Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authViewModel.signOut();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      icon: Icon(Icons.logout, color: Colors.white),
                      label: Text("Log Out", style: TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
