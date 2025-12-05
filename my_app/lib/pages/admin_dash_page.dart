import 'package:flutter/material.dart';
import 'package:my_app/pages/admin_enroll_page.dart';
import 'package:my_app/pages/admin_user_page.dart';
import 'package:my_app/pages/admin_startup_page.dart';
 import 'package:my_app/pages/admin_ticket_page.dart';

class AdminDashPage extends StatelessWidget {
  const AdminDashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Image.asset(
              "assets/logo.jpg",
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              "Dashboard",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,

          children: [
            _buildDashCard(
              context,
              title: "Enrollers",
              icon: Icons.group_add_outlined,
              color1: Colors.orange.shade700,
              color2: Colors.orange.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminEnrollPage()),
                );
              },
            ),

            _buildDashCard(
              context,
              title: "Users",
              icon: Icons.people_outline,
              color1: Colors.blue.shade700,
              color2: Colors.blue.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUserPage()),
                );
              },
            ),

            _buildDashCard(
              context,
              title: "Startups",
              icon: Icons.payments_outlined,
              color1: Colors.purple.shade700,
              color2: Colors.purple.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminStartupPage()),
                );
              },
            ),

            _buildDashCard(
              context,
              title: "Tickets",
              icon: Icons.confirmation_number_outlined,
              color1: Colors.green.shade700,
              color2: Colors.green.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminTicketPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --------------------- WIDGET FOR CARDS -------------------------
  Widget _buildDashCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
