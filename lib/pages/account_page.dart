import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cubits/rating_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/user_cubit.dart';

class AccountPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const AccountPage({super.key, required this.onThemeChanged});

  @override State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? _pic, _email, _name;
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      _pic = snap['profilePic'];
      _email = snap['email'];
      _name = snap['name'];
    });
    context.read<RatingCubit>().fetchAverages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final img = await picker.pickImage(source: ImageSource.gallery);
                if (img != null) context.read<UserCubit>().uploadProfilePic(img);
              },
              child: CircleAvatar(radius: 60, backgroundImage: _pic != null ? NetworkImage(_pic!) : const AssetImage('assets/default_profile.png') as ImageProvider),
            ),
          ).animate().scale(),
          Text('Name: $_name').animate().fadeIn(),
          Text('Email: $_email').animate().fadeIn(delay: 200.ms),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _dark,
            onChanged: (v) {
              setState(() => _dark = v);
              widget.onThemeChanged(v);
            },
          ).animate().fadeIn(delay: 400.ms),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/reset'), child: const Text('Change Password')).animate().fadeIn(delay: 600.ms),
          const Text('Your Ratings:', style: TextStyle(fontWeight: FontWeight.bold)).animate().fadeIn(delay: 800.ms),
          BlocBuilder<RatingCubit, RatingState>(
            builder: (context, state) {
              if (state is RatingLoaded) {
                return Column(children: state.averages.map((e) => ListTile(title: Text(e['category']), trailing: Text(e['average'].toStringAsFixed(1)))).toList());
              }
              return const Text('No ratings yet');
            },
          ),
          ElevatedButton(onPressed: 
          () => context.read<AuthCubit>().signOut(), 
           style: ElevatedButton.styleFrom(backgroundColor:
            Colors.red),
           child: const Text('Logout')).animate().fadeIn(delay: 1000.ms),
        ],
      ),
    );
  }
}