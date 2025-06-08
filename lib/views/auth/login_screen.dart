import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../main_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // 🔗 Replace this with your actual Firebase Storage image URL
  final String logoUrl = 'https://firebasestorage.googleapis.com/v0/b/easycook-ca3d5.firebasestorage.app/o/EasyCook(logo).png?alt=media&token=4f03c781-15fa-43ef-b640-3d56367e541c';

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.orange[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(height: 40),

              // 🍽 Logo
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(logoUrl),
                      radius: 50,
                      backgroundColor: Colors.white,
                      onBackgroundImageError: (_, __) =>
                          const Icon(Icons.image_not_supported, size: 60),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Welcome to EasyCook",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text("Your smart recipe companion", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // 🧾 Login Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text("Login to Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 20),

                        // 📧 Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => Validators.validateEmail(value ?? ""),
                        ),

                        SizedBox(height: 16),

                        // 🔒 Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => Validators.validatePassword(value ?? ""),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));
                            },
                            child: Text("Forgot Password?"),
                          ),
                        ),

                        SizedBox(height: 10),

                        // 🟠 Login Button
                        ElevatedButton.icon(
                          onPressed: () async {
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
                                        Text("Logging in...", style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                              bool success = await authViewModel.signIn(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );

                              Navigator.of(context).pop(); // Close loader

                              if (success) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => MainScreen()),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Login failed. Please check your credentials.")),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.login),
                          label: Text("Login", style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          ),
                        ),

                        SizedBox(height: 10),

                        // 🔗 Sign Up
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpScreen()));
                          },
                          child: Text("Don't have an account? Sign Up"),
                        ),
                      ],
                    ),
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
