import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/user_cubit.dart';
import 'cubits/rating_cubit.dart';
import 'pages/auth_page.dart';
import 'pages/signup_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/main_page.dart';
import 'pages/account_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    print("done");
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAErD7oG3owrkSuGcjWMP9_HnZi9FcYZBs",
        appId: "1:1018540097624:android:810ab649a493f70bf24a2d",
        messagingSenderId: "1018540097624",
        projectId: "b-fh-bbc87",
        storageBucket: "b-fh-bbc87.appspot.com",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const RatingApp());
}

class RatingApp extends StatefulWidget {
  const RatingApp({super.key});
  @override
  State<RatingApp> createState() => _RatingAppState();
}

class _RatingAppState extends State<RatingApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message.notification?.title ?? 'New Notification')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
        BlocProvider<UserCubit>(create: (_) => UserCubit()),
        BlocProvider<RatingCubit>(create: (_) => RatingCubit()),
      ],
      child: MaterialApp(
        title: 'User Rating',
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData.light().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          cardTheme: CardThemeData(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
        ),
        darkTheme: ThemeData.dark().copyWith(primaryColor: Colors.blueAccent),
        home:
            AuthWrapper(onThemeChanged: (v) => setState(() => _isDarkMode = v)),
        routes: {
          '/main': (_) => const MainPage(),
          '/account': (_) => AccountPage(
              onThemeChanged: (v) => setState(() => _isDarkMode = v)),
          '/signup': (_) => const SignUpPage(),
          '/reset': (_) => const ResetPasswordPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Function(bool) onThemeChanged;
  const AuthWrapper({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/main');
          });
        }
        return AuthPage(onThemeChanged: onThemeChanged);
      },
    );
  }
}
