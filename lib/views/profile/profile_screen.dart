import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'user_details_screen.dart';  // ✅ Navigate to the new User Details Page

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AuthViewModel>(context, listen: false).fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userProfile = authViewModel.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: userProfile == null
          ? Center(child: CircularProgressIndicator())  // Loading indicator
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header (Username & Picture) - Click to Open Details
                GestureDetector(
                  onTap: () {
                    // ✅ Navigate to User Details Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserDetailsScreen()),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: userProfile["profilePic"] != ""
                              ? NetworkImage(userProfile["profilePic"])
                              : null,
                          child: userProfile["profilePic"] == ""
                              ? Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 15),

                        // Username
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile["fullName"] ?? "No Name",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "View Profile Details",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
