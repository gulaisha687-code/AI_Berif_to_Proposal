import 'package:flutter/material.dart';
import '../brand.dart';
import '../screens/welcome_sc.dart';
import '../services/auth_ser.dart';

// An account icon in the app bar: shows who is signed in, and sign out / sign in.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) async {
        if (value == 'out') await AuthService.signOut();
        if (!context.mounted) return;
        Navigator.of(context)
            .pushAndRemoveUntil(fadeRoute(const WelcomeScreen()), (r) => false);
      },
      itemBuilder: (_) {
        final user = AuthService.currentUser;
        final name = user == null
            ? 'Guest'
            : ((user.displayName ?? '').isNotEmpty
            ? user.displayName!
            : (user.email ?? 'Account'));
        return [
          PopupMenuItem<String>(enabled: false, child: Text(name)),
          PopupMenuItem<String>(
            value: user == null ? 'in' : 'out',
            child: Text(user == null ? 'Sign in' : 'Sign out'),
          ),
        ];
      },
    );
  }
}