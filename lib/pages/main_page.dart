// lib/pages/main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cubits/user_cubit.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().fetchAllUsers();
    _searchController.addListener(() {
      context.read<UserCubit>().searchUsers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/account'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ).animate().fadeIn().slideY(),
          ),
          Expanded(
            child: BlocBuilder<UserCubit, UserState>(
              builder: (context, state) {
                if (state is UserLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is UserError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<UserCubit>().fetchAllUsers(),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }

                if (state is UserLoaded) {
                  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                  final users = state.users
                      .where((u) => u['id'] != currentUserId)
                      .toList();

                  if (users.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return UserCard(
                        userId: user['id'],
                        userName: user['name'] ?? 'Unknown',
                        profilePic: user['profilePic'],
                        onRate: (id, ratings) {
                          context.read<UserCubit>().rateUser(id, ratings);
                        },
                      ).animate().fadeIn(delay: (index * 100).ms).slideX();
                    },
                  );
                }

                return const Center(child: Text("Tap to load users"));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserCard extends StatefulWidget {
  final String userId;
  final String userName;
  final String? profilePic;
  final Function(String, Map<String, double>) onRate;

  const UserCard({
    super.key,
    required this.userId,
    required this.userName,
    this.profilePic,
    required this.onRate,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  double personality = 3;
  double morals = 3;
  double attitude = 3;
  double style = 3;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.profilePic != null
                      ? NetworkImage(widget.profilePic!)
                      : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.userName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSlider('Personality', personality,
                (v) => setState(() => personality = v)),
            _buildSlider('Morals', morals, (v) => setState(() => morals = v)),
            _buildSlider(
                'Attitude', attitude, (v) => setState(() => attitude = v)),
            _buildSlider('Style', style, (v) => setState(() => style = v)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final ratings = {
                    'personality': personality,
                    'morals': morals,
                    'attitude': attitude,
                    'style': style,
                  };
                  widget.onRate(widget.userId, ratings);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Rating submitted!")),
                  );
                },
                child: const Text("Submit Rating"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text("$label:")),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
            width: 40,
            child: Text(value.toInt().toString(), textAlign: TextAlign.center)),
      ],
    );
  }
}
