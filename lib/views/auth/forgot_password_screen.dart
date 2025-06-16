import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.orange[50],
      // appBar: AppBar(title: Text("Forgot Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 40),

            // 📩 Icon and instructions
            Center(
              child: Column(
                children: [
                  Icon(Icons.lock_reset_rounded, size: 80, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    "Reset Your Password",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Enter your email to receive a password reset link.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // 🧾 Form Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 📧 Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Enter a valid email";
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // 🟠 Submit button
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // ✅ Show loading dialog
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
                                      Text("Sending...", style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            );

                            bool success = await authViewModel.resetPassword(
                              _emailController.text.trim(),
                            );

                            Navigator.of(context).pop(); // Close loading

                            if (success) {
                              // ✅ Success Dialog
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
                                        Icon(Icons.mark_email_read_rounded, color: Colors.orange, size: 48),
                                        SizedBox(height: 16),
                                        Text("Email Sent", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Text(
                                          "A password reset link has been sent to your email. Please check your inbox.",
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 24),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close dialog
                                            Navigator.pop(context);     // Return to login
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
                            } else {
                              // ❌ Error Dialog
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
                                        Text("Failed", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Text(
                                          "Something went wrong. Please check the email address and try again.",
                                          textAlign: TextAlign.center,
                                        ),
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
                        },
                        icon: Icon(Icons.send),
                        label: Text("Send Reset Link", style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        ),
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
}
