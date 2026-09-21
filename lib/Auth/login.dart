import 'package:flutter/material.dart';
import 'package:ruang_aman/Auth/register.dart';
import 'package:ruang_aman/siswa/home.dart';
import 'package:ruang_aman/siswa/menu.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: Column(
            children: [
              const SizedBox(height: 35),

              // LOGO
              Image.asset("assets/logo_ruang.jpeg", height: 85),

              const SizedBox(height: 15),

              // TITLE
              const Text(
                "Selamat Datang\n"
                "di RuangAman",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 24,

                  fontWeight: FontWeight.bold,

                  color: Color(0xff124F4A),

                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Masuk untuk melanjutkan",

                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 35),

              // NIS / EMAIL
              inputField(icon: Icons.person_outline, hint: "NIS / Email"),

              const SizedBox(height: 15),

              // PASSWORD
              inputField(
                icon: Icons.lock_outline,

                hint: "Password",

                password: true,
              ),

              const SizedBox(height: 12),

              // REMEMBER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,

                        height: 20,

                        child: Checkbox(
                          value: false,

                          onChanged: (value) {},

                          activeColor: const Color(0xff087F72),
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Text(
                        "Ingat saya",

                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),

                  const Text(
                    "Lupa password?",

                    style: TextStyle(
                      color: Color(0xff087F72),

                      fontWeight: FontWeight.w600,

                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // BUTTON LOGIN
              Container(
                width: double.infinity,

                height: 52,

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff62C9A9), Color(0xff087F72)],
                  ),

                  borderRadius: BorderRadius.circular(30),
                ),

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,

                    shadowColor: Colors.transparent,
                  ),

                  onPressed: () {
                    Navigator.pushReplacement(
                      context,

                      MaterialPageRoute(builder: (context) => const MenuPage()),
                    );
                  },

                  child: const Text(
                    "Masuk",

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 16,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // PEMISAH
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),

                    child: Text("atau", style: TextStyle(color: Colors.grey)),
                  ),

                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 20),

              // GOOGLE LOGIN
              Container(
                height: 50,

                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),

                  border: Border.all(color: Colors.grey.shade300),
                ),

                child: TextButton(
                  onPressed: () {},

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Image.asset("assets/gg.png", height: 20),

                      const SizedBox(width: 12),

                      const Text(
                        "Masuk dengan Google",

                        style: TextStyle(
                          color: Color(0xff333333),

                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // REGISTER
              // REGISTER
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },

                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.grey, fontSize: 13),

                    children: [
                      TextSpan(text: "Belum punya akun? "),

                      TextSpan(
                        text: "Daftar sekarang",

                        style: TextStyle(
                          color: Color(0xff087F72),

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputField({
    required IconData icon,

    required String hint,

    bool password = false,
  }) {
    return TextField(
      obscureText: password,

      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),

        hintText: hint,

        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),

        filled: true,

        fillColor: const Color(0xffFAFAFA),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),

          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),

          borderSide: const BorderSide(color: Color(0xff087F72)),
        ),
      ),
    );
  }
}
