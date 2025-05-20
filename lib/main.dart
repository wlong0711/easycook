import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/auth/login_screen.dart';
import 'views/main_screen.dart'; // Your bottom-nav main page
import 'viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EasyCook',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: FirebaseAuth.instance.currentUser == null
          ?  LoginScreen()  // 🔐 Show login if not signed in
          :  MainScreen(),  // ✅ Show home if signed in
    );
  }
}
