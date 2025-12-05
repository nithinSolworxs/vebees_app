import 'package:flutter/material.dart';
import 'package:my_app/pages/profile_page.dart';
import 'package:my_app/pages/ticket_page.dart';
import 'package:my_app/pages/startup_page.dart';
import 'package:my_app/pages/program_admin_page.dart';
import 'package:my_app/pages/user_program_page.dart';
import 'package:my_app/pages/enroll_user_page.dart';
import 'package:my_app/pages/admin_dash_page.dart';
import 'package:my_app/services/notification_service.dart';   // ADD
import 'package:supabase_flutter/supabase_flutter.dart';       // ADD

final supabase = Supabase.instance.client;

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

    // 🔥 Start realtime listener for Admin
    listenToStartupUpdates();
  }

  // 🔥 REALTIME NOTIFICATION LISTENER
  void listenToStartupUpdates() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Check user profile
    final profile = await supabase
        .from('profile')
        .select()
        .eq('userId', user.id)
        .maybeSingle();

    if (profile == null || profile['typeOfUser'] != 'Admin') {
      print("Not admin → no realtime subscription");
      return;
    }

    print("ADMIN → listening to startup inserts");

    supabase.channel('public:startup')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'startup',
        callback: (payload) {
          final data = payload.newRecord;

          NotificationService.showNotification(
            title: "🚀 New Startup Added",
            body: "${data['legalName']} just registered",
          );
        },
      )
      .subscribe();
  }

  void setupNavigationForRole(String role) {
    final roleConfig = <String, dynamic>{
      "Admin": {
        "pages": [
          const AdminDashPage(),
          const ProgramAdminPage(),
          const ProfilePage(),
        ],
        "nav": const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: "Dashboard",
          ),
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

      "User": {
        "pages": [
          const UserProgramPage(),
          const EnrollUserPage(),
          const StartupPage(),
          const TicketPage(),
          const ProfilePage(),
        ],
        "nav": const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: "Programs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add_check),
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

      "default": {
        "pages": [
          const ProfilePage(),
        ],
        "nav": const [
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
        unselectedItemColor: Colors.black,
        showUnselectedLabels: true,
        items: _navItems,
      ),
    );
  }
}
