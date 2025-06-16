import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'user_details_screen.dart';
import 'favorite_recipes_screen.dart';
import '../profile/shopping_list_screen.dart';

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
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text("My Profile"),
        centerTitle: true,
        backgroundColor: Colors.orange,
        elevation: 2,
      ),
      body: userProfile == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 Profile Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserDetailsScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[300]!, Colors.orange[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: (userProfile["profilePic"] != null &&
                                    userProfile["profilePic"] != "")
                                ? NetworkImage(userProfile["profilePic"])
                                : null,
                            child: (userProfile["profilePic"] == null ||
                                    userProfile["profilePic"] == "")
                                ? Icon(Icons.person, size: 40, color: Colors.orange[700])
                                : null,
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
                                    color: Colors.orange[900],
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  authViewModel.user?.email ?? "No Email",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Tap to view and edit profile",
                                  style: TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  Text(
                    "Your Activity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),

                  // 🧾 Saved Recipes Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bookmark, color: Colors.orange),
                      ),
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

                  // 🛒 Shopping List Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shopping_cart, color: Colors.green),
                      ),
                      title: Text("Shopping List"),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}