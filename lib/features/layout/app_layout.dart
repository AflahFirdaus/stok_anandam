import 'package:flutter/material.dart';
import 'app_sidebar.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({
    super.key,
    required this.currentRoute,
    required this.child,
    this.onNavigate,
    this.onLogout,
    this.title,
  });

  final String currentRoute;
  final Widget child;
  final void Function(String route)? onNavigate;
  final VoidCallback? onLogout;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSidebar(
            currentRoute: currentRoute,
            onNavigate: onNavigate,
            onLoginTap: onLogout,
            isLoggedIn: true,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    color: Colors.white,
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
