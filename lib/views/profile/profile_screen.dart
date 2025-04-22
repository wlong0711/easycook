import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'user_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Provider.of<AuthViewModel>(context, listen: false).fetchUserProfile();
    Provider.of<AuthViewModel>(context, listen: false).fetchUserProfile().then((_) {
    print("✅ Profile fetched.");
    });
    
    Future.delayed(Duration(seconds: 5), () {
    if (Provider.of<AuthViewModel>(context, listen: false).userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile. Please try again.")),
      );
    }
  });
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
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserDetailsScreen()),
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
                      children: [
                        // ✅ Safe profile picture rendering
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: (userProfile["profilePic"] != null &&
                                  userProfile["profilePic"] != "")
                              ? NetworkImage(userProfile["profilePic"])
                              : null,
                          child: (userProfile["profilePic"] == null ||
                                  userProfile["profilePic"] == "")
                              ? Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 15),

                        // ✅ Safe username display
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
