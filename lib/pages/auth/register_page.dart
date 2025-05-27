import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({
    super.key,
    required this.showLoginPage,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController= TextEditingController();
  final TextEditingController _passwordConfirmController= TextEditingController();

  Future _signUp() async {
    if (_passwordController.text == _passwordConfirmController.text) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim(),
      ); 
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
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
              "Hello there",
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Text(
              "Create your account now!",
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
                  controller: _passwordConfirmController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Confirm Password",
                  ),
                  style: Theme.of(context).textTheme.bodyLarge
                ),
              ),
            ),

            SizedBox(height: 20,),

            GestureDetector(
              onTap: _signUp,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 45, 190, 120),
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Sign Up",
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
                  "Have an account? ",
                  style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: widget.showLoginPage,
                  child: Text(
                    " Login Now!",
                    style: GoogleFonts.roboto(fontSize: 12, color: Color.fromARGB(255, 45, 190, 120)),
                  ),
                ),
              ],
            )
          ],
        )
      ),
    );
  }
}