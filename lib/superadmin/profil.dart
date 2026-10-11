import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/Auth/login.dart';

class ProfilSuperadmin extends StatefulWidget {
  const ProfilSuperadmin({super.key});

  @override
  State<ProfilSuperadmin> createState() => _ProfilSuperadminState();
}

class _ProfilSuperadminState extends State<ProfilSuperadmin> {
  // ============================================================
  // WARNA RUANGAMAN
  // ============================================================

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  // ============================================================
  // STORAGE
  // ============================================================

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  // ============================================================
  // STATE
  // ============================================================

  String nama = 'Superadmin';
  String email = '-';
  String role = 'Superadmin';

  bool loading = true;
  bool isLoggingOut = false;
  String? error;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ============================================================
  // MENAMPILKAN PESAN
  // ============================================================

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? primaryColor : Colors.red,
      ),
    );
  }

  // ============================================================
  // AMBIL PROFIL DARI DATA LOGIN
  // ============================================================

  Future<void> loadProfile() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Ambil data user yang disimpan saat login
      final savedUser = await storage.read(key: 'auth_user');

      if (savedUser == null || savedUser.isEmpty) {
        throw Exception(
          'Data pengguna tidak ditemukan. Silakan login kembali.',
        );
      }

      // Ubah JSON menjadi Map
      final decoded = jsonDecode(savedUser);

      if (decoded is! Map) {
        throw Exception('Format data pengguna tidak valid.');
      }

      final user = Map<String, dynamic>.from(decoded);

      if (!mounted) return;

      setState(() {
        nama = user['nama']?.toString() ?? 'Superadmin';
        email = user['email']?.toString() ?? '-';
        role = user['role']?.toString() ?? 'Superadmin';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    if (isLoggingOut) return;

    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Keluar Akun',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun '
            'Superadmin RuangAman?',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() {
      isLoggingOut = true;
    });

    try {
      // Hapus JWT
      await storage.delete(key: 'auth_token');

      // Hapus data pengguna
      await storage.delete(key: 'auth_user');

      // Hapus preferensi ingat saya
      await storage.delete(key: 'remember_me');

      if (!mounted) return;

      // Kembali ke halaman login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage('Gagal keluar dari akun: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  // ============================================================
  // WIDGET INFORMASI PROFIL
  // ============================================================

  Widget profileDetail({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // ICON
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),

          const SizedBox(width: 13),

          // INFORMASI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Superadmin',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: darkPrimary,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Informasi akun dan pengaturan',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // FOTO PROFIL
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              size: 48,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 15),

          // NAMA SUPERADMIN
          Text(
            nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkPrimary,
            ),
          ),

          const SizedBox(height: 6),

          // ROLE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL INFORMASI AKUN
  // ============================================================

  Widget buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          profileDetail(
            icon: Icons.person_outline,
            title: 'Nama Lengkap',
            value: nama,
          ),

          const Divider(height: 1, color: Color(0xffEEEEEE)),

          profileDetail(
            icon: Icons.email_outlined,
            title: 'Alamat Email',
            value: email,
          ),

          const Divider(height: 1, color: Color(0xffEEEEEE)),

          profileDetail(
            icon: Icons.verified_user_outlined,
            title: 'Role Akun',
            value: role,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTON LOGOUT
  // ============================================================

  Widget buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoggingOut ? null : logout,
        icon: isLoggingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              )
            : const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          isLoggingOut ? 'Sedang Keluar...' : 'Keluar Akun',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffFDECEC),
          foregroundColor: Colors.red,
          disabledBackgroundColor: const Color(0xffFDECEC),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadProfile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
            children: [
              // HEADER
              buildHeader(),

              const SizedBox(height: 25),

              // LOADING
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),

              // ERROR
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xffFDECEC),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!loading && error == null) ...[
                // KARTU PROFIL
                buildProfileCard(),

                const SizedBox(height: 25),

                // TITLE
                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkPrimary,
                  ),
                ),

                const SizedBox(height: 15),

                // DETAIL PROFIL
                buildInformationCard(),
              ],

              const SizedBox(height: 30),

              // LOGOUT
              buildLogoutButton(),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'RuangAman • Aman bercerita, nyaman berkembang',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
