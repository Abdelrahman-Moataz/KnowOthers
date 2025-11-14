// lib/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';

class ProfilePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const ProfilePage({super.key, required this.onThemeChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  String? _photoUrl;
  bool _isUploading = false;
  bool _darkMode = false;

  // Rating averages
  double overallAvg = 0.0;
  final Map<String, double> categoryAvg = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRatings();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _photoUrl = data['photoUrl'];
      });
    }
  }

  Future<void> _loadRatings() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('ratings')
        .where('rateeId', isEqualTo: userId)
        .get();

    if (snap.docs.isEmpty) return;

    final Map<String, List<int>> scores = {};
    for (var doc in snap.docs) {
      final data = doc.data();
      final cat = data['category'] as String;
      final score = data['score'] as int;
      scores.putIfAbsent(cat, () => []).add(score);
    }

    double total = 0;
    int count = 0;
    scores.forEach((cat, list) {
      final avg = list.reduce((a, b) => a + b) / list.length;
      categoryAvg[cat] = double.parse(avg.toStringAsFixed(1));
      total += avg;
      count++;
    });

    setState(() {
      overallAvg = double.parse((total / count).toStringAsFixed(1));
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploading = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child('profile_pics/$userId.jpg');
    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'photoUrl': url,
    });

    setState(() {
      _photoUrl = url;
      _isUploading = false;
    });
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'name': newName,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Name updated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // === PHOTO ===
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                        ? NetworkImage(_photoUrl!)
                        : const AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                  if (_isUploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(backgroundColor: Colors.white),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: _pickAndUploadImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // === NAME ===
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _updateName,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // === EMAIL ===
            Text(
              user.email ?? 'No email',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // === RATINGS ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Ratings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Overall: $overallAvg / 5', style: const TextStyle(fontSize: 20)),
                    const Divider(),
                    ...categoryAvg.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key),
                          Text('${e.value} / 5'),
                        ],
                      ),
                    )).toList(),
                    if (categoryAvg.isEmpty)
                      const Text('No ratings yet', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // === SETTINGS ===
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (v) {
                setState(() => _darkMode = v);
                widget.onThemeChanged(v);
              },
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Change Password'),
              onTap: () => Navigator.pushNamed(context, '/reset'),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await context.read<AuthCubit>().signOut();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}