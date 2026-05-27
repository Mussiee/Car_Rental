import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/user_header.dart';
import '../owner/owner_home_screen.dart';
import './account_settings_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const UserHeader(isOwner: false),
          const SizedBox(height: 32),

          // Switch to Owner Mode
          Card(
            color: Colors.green[50],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green[200]!),
            ),
            child: ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.green),
              title: const Text('Switch to Owner Mode'),
              subtitle: const Text('List and manage your cars'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OwnerHomeScreen()),
                );
              },
            ),
          ),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Account Settings'),
            subtitle: const Text('Edit name & phone number'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountSettingsScreen(),
                ),
              );
            },
          ),

          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
