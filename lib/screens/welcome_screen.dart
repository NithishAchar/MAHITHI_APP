import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo or college image
              Center(
                child: Image.asset(
                  'assets/images/logo.png', // Replace with your actual logo path
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school,
                      size: 100,
                      color: Color(0xFF8B4513),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to\nCollege App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose your login type to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),
              // Faculty login option
              _buildLoginOption(
                context: context,
                title: 'Faculty Login',
                subtitle: 'Access your account',
                icon: Icons.school,
                onTap: () {
                  Navigator.pushNamed(context, '/faculty-login');
                },
              ),
              const SizedBox(height: 16),
              // Student login option
              _buildLoginOption(
                context: context,
                title: 'Student Login',
                subtitle: 'Access your account',
                icon: Icons.person,
                onTap: () {
                  Navigator.pushNamed(context, '/student-login');
                },
                isSelected: true,
              ),
              const SizedBox(height: 16),
              // Public login option
              _buildLoginOption(
                context: context,
                title: 'Public Login',
                subtitle: 'Create new account',
                icon: Icons.public,
                onTap: () {
                  Navigator.pushNamed(context, '/public-login');
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B4513).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B4513)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8B4513),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
} 