import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/Auth/login.dart';

// Sesuaikan path import halaman login Anda di bawah ini:
// import 'package:ruang_aman/Auth/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  Map<String, dynamic> userData = {};
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController npsnController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  // Variabel untuk dropdown jenjang
  String? selectedJenjang;
  final List<String> jenjangOptions = [
    'SD/MI/Sederajat',
    'SMP/MTs/Sederajat',
    'SMA/SMK/MA/Sederajat',
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    npsnController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? primaryColor : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> loadProfile() async {
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/adminsekolah/profile'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;

        if (mounted) {
          setState(() {
            userData = Map<String, dynamic>.from(data);
            nameController.text = userData['nama'] ?? userData['name'] ?? '';
            npsnController.text = userData['npsn'] ?? '';
            alamatController.text = userData['alamat'] ?? '';

            // Set nilai dropdown jika cocok dengan opsi, jika tidak biarkan null atau default
            final j = userData['jenjang'] ?? '';
            selectedJenjang = jenjangOptions.contains(j) ? j : null;

            isLoading = false;
          });
        }
        await storage.write(key: 'auth_user', value: jsonEncode(data));
      } else {
        throw Exception('Gagal memuat profil');
      }
    } catch (_) {
      try {
        final userStr = await storage.read(key: 'auth_user');
        if (userStr != null && userStr.isNotEmpty) {
          final decoded = jsonDecode(userStr);
          if (decoded is Map<String, dynamic> && mounted) {
            setState(() {
              userData = decoded;
              nameController.text = userData['nama'] ?? userData['name'] ?? '';
              npsnController.text = userData['npsn'] ?? '';
              alamatController.text = userData['alamat'] ?? '';
              final j = userData['jenjang'] ?? '';
              selectedJenjang = jenjangOptions.contains(j) ? j : null;
              isLoading = false;
            });
            return;
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> updateProfile() async {
    final newName = nameController.text.trim();
    final newJenjang = selectedJenjang ?? '';
    final newNpsn = npsnController.text.trim();
    final newAlamat = alamatController.text.trim();

    if (newName.isEmpty) {
      showMessage('Nama tidak boleh kosong.');
      return;
    }

    try {
      final token = await storage.read(key: 'auth_token');
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/api/adminsekolah/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'nama': newName,
              'jenjang': newJenjang,
              'npsn': newNpsn,
              'alamat': newAlamat,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final updatedData =
            decoded['data'] ??
            {
              ...userData,
              'nama': newName,
              'jenjang': newJenjang,
              'npsn': newNpsn,
              'alamat': newAlamat,
            };

        await storage.write(key: 'auth_user', value: jsonEncode(updatedData));

        setState(() {
          userData = Map<String, dynamic>.from(updatedData);
        });

        if (!mounted) return;
        Navigator.pop(context);
        showMessage('Profil berhasil diperbarui!', success: true);
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['error'] ?? 'Gagal memperbarui profil');
      }
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit Profil Sekolah & Admin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Admin / Sekolah',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // EMAIL DIKUNCI
                    TextField(
                      controller: TextEditingController(
                        text: userData['email'] ?? '-',
                      ),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email (Tidak dapat diubah)',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // DROPDOWN JENJANG SEKOLAH
                    DropdownButtonFormField<String>(
                      value: selectedJenjang,
                      hint: const Text(
                        'Pilih Jenjang Sekolah',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: jenjangOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: darkPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          selectedJenjang = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: npsnController,
                      decoration: InputDecoration(
                        labelText: 'NPSN',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: alamatController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Alamat Sekolah',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // REVISI LOGIKA LOGOUT / REDIRECT KE HALAMAN LOGIN
  Future<void> handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar Akun',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: darkPrimary,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi Admin Sekolah?',
          style: TextStyle(fontSize: 13, color: Color(0xff34403D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'auth_user');
      await storage.delete(key: 'remember_me');

      if (!mounted) return;

      // REDIRECT KE HALAMAN LOGIN DAN BERSIHKAN SEMUA ROUTE SEBELUMNYA
      // Sesuaikan widget halaman login Anda (misal: LoginScreen / LoginPage)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = userData['nama'] ?? userData['name'] ?? 'Admin Sekolah';
    final email = userData['email'] ?? '-';
    final jenjang = userData['jenjang'] ?? '-';
    final npsn = userData['npsn'] ?? '-';
    final alamat = userData['alamat'] ?? '-';
    final role = userData['role']?.toString().toUpperCase() ?? 'ADMIN';

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profil Admin',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: darkPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Informasi akun dan sekolah',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: showEditModal,
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: primaryColor,
                        ),
                        tooltip: 'Edit Profil',
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: lightGreen,
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 50,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Informasi Detail',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  profileCard(
                    icon: Icons.email_outlined,
                    title: 'Email (Terkunci)',
                    subtitle: email,
                  ),
                  profileCard(
                    icon: Icons.school_outlined,
                    title: 'Jenjang',
                    subtitle: jenjang,
                  ),
                  profileCard(
                    icon: Icons.badge_outlined,
                    title: 'NPSN',
                    subtitle: npsn,
                  ),
                  profileCard(
                    icon: Icons.location_on_outlined,
                    title: 'Alamat Sekolah',
                    subtitle: alamat,
                  ),
                  const SizedBox(height: 30),
                  InkWell(
                    onTap: handleLogout,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Keluar Akun',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget profileCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: darkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
