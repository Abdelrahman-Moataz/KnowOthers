import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cubits/auth_cubit.dart';

class AuthPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const AuthPage({super.key, required this.onThemeChanged});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AuthSuccess) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')).animate().fadeIn().slideY(),
              TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')).animate().fadeIn(delay: 200.ms).slideY(),
              ElevatedButton(onPressed: () => context.read<AuthCubit>().signIn(_email.text, _pass.text), child: const Text('Sign In')).animate().fadeIn(delay: 400.ms),
              ElevatedButton.icon(
                onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Google'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ).animate().fadeIn(delay: 600.ms),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/signup'), child: const Text('Sign Up')).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}