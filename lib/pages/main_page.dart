import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cubits/user_cubit.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().fetchAllUsers();
    _search.addListener(() => context.read<UserCubit>().searchUsers(_search.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users'), actions: [IconButton(icon: const Icon(Icons.account_circle), onPressed: () => Navigator.pushNamed(context, '/account'))]),
      body: Column(
        children: [
          TextField(controller: _search, decoration: const InputDecoration(labelText: 'Search')).animate().fadeIn(),
          Expanded(
            child: BlocBuilder<UserCubit, UserState>(
              builder: (context, state) {
                if (state is UserLoading) return const Center(child: CircularProgressIndicator());
                if (state is UserError) return Center(child: Text(state.message));
                if (state is UserLoaded) {
                  return ListView.builder(
                    itemCount: state.users.length,
                    itemBuilder: (context, i) {
                      final user = state.users[i];
                      return UserCard(
                        userId: user['id'],
                        userName: user['name'],
                        profilePic: user['profilePic'],
                        onRate: (id, ratings) => context.read<UserCubit>().rateUser(id, ratings),
                      ).animate().fadeIn(delay: (i * 100).ms);
                    },
                  );
                }
                return const Center(child: Text('No users'));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserCard extends StatefulWidget {
  final String userId, userName;
  final String? profilePic;
  final Function(String, Map<String, double>) onRate;
  const UserCard({super.key, required this.userId, required this.userName, this.profilePic, required this.onRate});

  @override State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  double p = 3, m = 3, a = 3, s = 3;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              CircleAvatar(backgroundImage: widget.profilePic != null ? NetworkImage(widget.profilePic!) : const AssetImage('assets/default_profile.png') as ImageProvider),
              const SizedBox(width: 12),
              Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            _slider('Personality', p, (v) => setState(() => p = v)),
            _slider('Morals', m, (v) => setState(() => m = v)),
            _slider('Attitude', a, (v) => setState(() => a = v)),
            _slider('Style', s, (v) => setState(() => s = v)),
            ElevatedButton(onPressed: () => widget.onRate(widget.userId, {'personality': p, 'morals': m, 'attitude': a, 'style': s}), child: const Text('Rate')),
          ],
        ),
      ),
    );
  }

  Widget _slider(String label, double value, Function(double) onChanged) {
    return Row(children: [
      Expanded(flex: 2, child: Text('$label: ${value.toInt()}')),
      Expanded(flex: 3, child: Slider(value: value, min: 1, max: 5, divisions: 4, onChanged: onChanged)),
    ]);
  }
}