import 'package:flutter/material.dart';
import 'package:my_app/auth/auth_service.dart';
import 'package:my_app/pages/register_page.dart';
import 'package:my_app/pages/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Login action
  void login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter email and password")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    await authService.signInWithEmailPassword(email, password);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) throw "Login failed. Try again.";

    // Fetch role
    final profile = await supabase
        .from('profile')
        .select('typeOfUser')
        .eq('userId', user.id)
        .maybeSingle();

    final role = profile?['typeOfUser'] ?? "default";

    // Navigate to homepage with role
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(userRole: role),
        ),
      );
    }

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}



void _showForgotPasswordDialog(BuildContext context) {
  final TextEditingController emailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: "Enter your email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email cannot be empty")),
                );
                return;
              }

              try {
                final supabase = Supabase.instance.client;

                await supabase.auth.resetPasswordForEmail(email);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password reset link sent! Check your email."),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Send Link"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ⭐ Your Logo on top
               Image.asset(
                  'assets/Startbee.jpg',
                  height: 120,
                  ),
                 const SizedBox(height: 20),
                // Title
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(226, 247, 162, 5), // Purple color
                  ),
                ),
                const SizedBox(height: 40),

                // Username field
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const UnderlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 241, 158, 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _isLoading ? null : login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign In",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Forgot password
                TextButton(
  onPressed: () {
    _showForgotPasswordDialog(context);
  },
  child: const Text(
    "Forgot Password?",
    style: TextStyle(color: Colors.grey),
  ),
),


                // Sign up text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: ()=> Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context)=> const RegisterPage(),)
                      )
                        
                      ,
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Color.fromARGB(255, 252, 195, 10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Cancel button
                // TextButton(
                //   onPressed: () {
                //     Navigator.pop(context);
                //   },
                //   child: const Text(
                //     "Cancel",
                //     style: TextStyle(color: Colors.black54),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
