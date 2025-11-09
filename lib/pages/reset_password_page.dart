import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cubits/auth_cubit.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthSuccess) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Reset Password')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.key, size: 80, color: Colors.blue)
                  .animate()
                  .fade(duration: 500.ms)
                  .slideY(),
              const SizedBox(height: 32),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(),
              const SizedBox(height: 24),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.read<AuthCubit>().updatePassword(
                            _newPasswordController.text.trim(),
                          ),
                      child: const Text('Update Password'),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}