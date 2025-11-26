import 'package:flutter/material.dart';
import 'package:my_app/pages/profile_page.dart';
import 'package:my_app/pages/ticket_page.dart';
import 'package:my_app/pages/startup_page.dart';
import 'package:my_app/pages/program_admin_page.dart';
import 'package:my_app/pages/user_program_page.dart';
import 'package:my_app/pages/enroll_user_page.dart';

class HomePage extends StatefulWidget {
  final String userRole;

  const HomePage({super.key, required this.userRole});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    setupNavigationForRole(widget.userRole);
  }

  void setupNavigationForRole(String role) {
    final roleConfig = <String, dynamic>{
      "Admin": {
        "pages": [
          const ProgramAdminPage(),
          const ProfilePage(),
        ],
        "nav": const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: "Programs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      },

      // ---------- UPDATED USER ROLE ORDER ----------
      "User": {
        "pages": [
          const UserProgramPage(),
          const EnrollUserPage(),  // 1 Programs
          const StartupPage(),      // 2 Startup
          const TicketPage(),       // 3 Tickets
          const ProfilePage(),      // 4 Profile
        ],
        "nav": const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: "Programs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add_check), // <-- NEW ICON (Enroll)
            label: "Cohort",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_outlined),
            label: "Startup",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: "Tickets",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      },
      // ------------------------------------------------

      "default": {
        "pages": [
          const UserProgramPage(),
          const ProfilePage(),
        ],
        "nav": const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: "Programs",
          ),
          
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      }
    };

    final config = roleConfig[role] ?? roleConfig["default"];

    _pages = List<Widget>.from(config["pages"]);
    _navItems = List<BottomNavigationBarItem>.from(config["nav"]);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: _navItems,
      ),
    );
  }
}
