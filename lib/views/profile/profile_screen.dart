import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'user_details_screen.dart';
import 'favorite_recipes_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AuthViewModel>(context, listen: false).fetchUserProfile().then((_) {
      print("✅ Profile fetched.");
    });

    Future.delayed(Duration(seconds: 5), () {
      if (!mounted) return; // ✅ Ensure widget is still active
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("My Profile"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: userProfile == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📸 Profile Header
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserDetailsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: (userProfile["profilePic"] != null &&
                                    userProfile["profilePic"] != "")
                                ? NetworkImage(userProfile["profilePic"])
                                : null,
                            child: (userProfile["profilePic"] == null ||
                                    userProfile["profilePic"] == "")
                                ? Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                            backgroundColor: Colors.orange[200],
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile["fullName"] ?? "No Name",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  authViewModel.user?.email ?? "No Email",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Tap to view and edit profile",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // 📚 Saved Recipes
                  Text(
                    "Your Activity",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.bookmark, color: Colors.orange),
                      title: Text("My Recipe Collection"),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoriteRecipesScreen()),
                        );
                      },
                    ),
                  ),

                  // 📌 Add more options below if needed (history, settings, etc.)
                ],
              ),
            ),
    );
  }
}
