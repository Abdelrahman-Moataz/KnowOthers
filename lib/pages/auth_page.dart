// lib/pages/auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';

class AuthPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const AuthPage({super.key, required this.onThemeChanged});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context
                  .read<AuthCubit>()
                  .signIn(_emailCtrl.text, _passCtrl.text),
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
              icon: const Icon(
                Icons.report_gmailerrorred,
                size: 24,
              ), // optional
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: Colors.black),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
