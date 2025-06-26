import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginUser extends StatefulWidget {
  final VoidCallback showRegisterPage;

  const LoginUser({
    super.key,
    required this.showRegisterPage,
  });

  @override
  State<LoginUser> createState() => _LoginUserState();
}

class _LoginUserState extends State<LoginUser> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Display a SnackBar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email or Password don't match"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hello Again",
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Text(
              "Welcome back!",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 20,),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 9, 37, 29),
                border: Border.all(color: Color.fromARGB(255, 45, 190, 120),),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Email",
                  ),
                  style: Theme.of(context).textTheme.bodyLarge
                ),
              ),
            ),
            SizedBox(height: 10,),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 9, 37, 29),
                border: Border.all(color: Color.fromARGB(255, 45, 190, 120),),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: TextField(
                  obscureText: true,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Password",
                  ),
                  style: Theme.of(context).textTheme.bodyLarge
                ),
              ),
            ),
            SizedBox(height: 20,),
            GestureDetector(
              onTap: _signIn,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 45, 190, 120),
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Sign In",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
            SizedBox(height: 15,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "No account yet? ",
                  style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: widget.showRegisterPage,
                  child: Text(
                    " Register Now!",
                    style: GoogleFonts.roboto(fontSize: 12, color: Color.fromARGB(255, 45, 190, 120)),
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