import 'package:flutter/material.dart';
import 'register_siswa.dart';
import 'register_guru.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FCFA),
      body: Stack(
        children: [
          // BACKGROUND DECORATION
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xffDDF3EC),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xffE7F7F2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BACK BUTTON
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xff087F72),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TITLE
                  const Text(
                    "Buat Akun\nRuangAman",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Pilih peran kamu untuk mendapatkan pengalaman terbaik",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // PILIH SISWA
                  roleCard(
                    context,
                    title: "Saya Siswa",
                    desc: "Cari bantuan dan terhubung dengan Guru BK",
                    icon: Icons.school_rounded,
                    color: const Color(0xff087F72),
                    page: const RegisterSiswa(),
                  ),

                  const SizedBox(height: 20),

                  // PILIH GURU BK
                  roleCard(
                    context,
                    title: "Saya Guru BK",
                    desc: "Dampingi siswa melalui layanan konseling",
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xff42B883),
                    page: const RegisterGuru(),
                  ),

                  const SizedBox(height: 60),

                  Center(
                    child: Text(
                      "Aman bercerita • Nyaman berkembang",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget roleCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(.07),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 32),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff124F4A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xffE7F7F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xff087F72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}