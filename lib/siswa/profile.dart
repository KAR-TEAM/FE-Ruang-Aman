import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/Auth/login.dart';
import 'package:ruang_aman/ipconfig.dart';

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

  Map<String, dynamic> profile = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) return;

      final response = await http
          .get(
            Uri.parse(ApiConfig.profileSiswa),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            profile = data;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showEditProfileSheet() {
    final nameController = TextEditingController(text: profile['nama'] ?? '');
    final emailController = TextEditingController(text: profile['email'] ?? '');

    // Validasi nilai awal jenis kelamin agar sesuai dengan pilihan dropdown
    String selectedJenisKelamin = profile['jenis_kelamin'] ?? 'Laki-laki';
    if (selectedJenisKelamin != 'Laki-laki' &&
        selectedJenisKelamin != 'Perempuan') {
      selectedJenisKelamin = 'Laki-laki';
    }

    final nisController = TextEditingController(text: profile['nis'] ?? '');
    final kelasController = TextEditingController(text: profile['kelas'] ?? '');
    final jurusanController = TextEditingController(
      text: profile['jurusan'] ?? '',
    );
    final tahunMasukController = TextEditingController(
      text: profile['tahun_masuk']?.toString() ?? '',
    );
    final waliController = TextEditingController(
      text: profile['nama_wali'] ?? '',
    );
    final kontakWaliController = TextEditingController(
      text: profile['kontak_wali'] ?? '',
    );

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.9,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                decoration: const BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Profil Siswa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          buildTextField('Nama Lengkap', nameController),
                          buildTextField('Email', emailController),

                          // Dropdown Jenis Kelamin
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: DropdownButtonFormField<String>(
                              value: selectedJenisKelamin,
                              decoration: InputDecoration(
                                labelText: 'Jenis Kelamin',
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Laki-laki',
                                  child: Text('Laki-laki'),
                                ),
                                DropdownMenuItem(
                                  value: 'Perempuan',
                                  child: Text('Perempuan'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(
                                    () => selectedJenisKelamin = val,
                                  );
                                }
                              },
                            ),
                          ),

                          buildTextField('NIS', nisController),
                          buildTextField('Kelas', kelasController),
                          buildTextField('Jurusan', jurusanController),
                          buildTextField(
                            'Tahun Masuk',
                            tahunMasukController,
                            keyboardType: TextInputType.number,
                          ),
                          buildTextField('Nama Wali', waliController),
                          buildTextField(
                            'Kontak Wali',
                            kontakWaliController,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                try {
                                  final token = await storage.read(
                                    key: 'auth_token',
                                  );
                                  final response = await http.put(
                                    Uri.parse(ApiConfig.profileSiswa),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Accept': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: jsonEncode({
                                      'nama': nameController.text,
                                      'email': emailController.text,
                                      'jenis_kelamin': selectedJenisKelamin,
                                      'nis': nisController.text,
                                      'kelas': kelasController.text,
                                      'jurusan': jurusanController.text,
                                      'tahun_masuk': tahunMasukController.text,
                                      'nama_wali': waliController.text,
                                      'kontak_wali': kontakWaliController.text,
                                    }),
                                  );

                                  if (response.statusCode == 200) {
                                    Navigator.pop(sheetContext);
                                    loadProfileData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profil berhasil diperbarui!',
                                        ),
                                        backgroundColor: primaryColor,
                                      ),
                                    );
                                  } else {
                                    throw Exception('Gagal memperbarui profil');
                                  }
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor),
          ),
        ),
      ),
    );
  }

  Future<void> handleLogout() async {
    // Tampilkan pop-up dialog konfirmasi yang elegan
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
          'Apakah Anda yakin ingin keluar dari aplikasi RuangAman?',
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

    // Jika pengguna menekan "Keluar"
    if (confirm == true) {
      // Hapus token dan data sesi tersimpan
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'auth_user');

      if (!mounted) return;

      // Arahkan langsung menggunakan MaterialPageRoute ke halaman Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), 
        (route) => false,
      );}
  }

  @override
  Widget build(BuildContext context) {
    final nama = profile['nama'] ?? 'Siswa';
    final email = profile['email'] ?? '-';
    final jenisKelamin = profile['jenis_kelamin'] ?? '-';
    final nis = profile['nis'] ?? '-';
    final kelas = profile['kelas'] ?? '-';
    final jurusan = profile['jurusan'] ?? '-';
    final tahunMasuk = profile['tahun_masuk'] ?? '-';
    final namaWali = profile['nama_wali'] ?? '-';
    final kontakWali = profile['kontak_wali'] ?? '-';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: lightGreen,
                          child: const Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: darkPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          kelas.isNotEmpty && kelas != '-'
                              ? "Siswa • Kelas $kelas"
                              : "Siswa RuangAman",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 15),
                        OutlinedButton.icon(
                          onPressed: showEditProfileSheet,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: primaryColor,
                          ),
                          label: const Text(
                            "Edit Profil",
                            style: TextStyle(color: primaryColor, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "Informasi Akun",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  profileCard(
                    icon: Icons.email_outlined,
                    title: "Email",
                    subtitle: email,
                  ),
                  profileCard(
                    icon: Icons.badge_outlined,
                    title: "Jenis Kelamin",
                    subtitle: jenisKelamin,
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Informasi Akademik & Wali",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  profileCard(
                    icon: Icons.pin_outlined,
                    title: "NIS",
                    subtitle: nis,
                  ),
                  profileCard(
                    icon: Icons.school_outlined,
                    title: "Kelas & Jurusan",
                    subtitle: "$kelas ($jurusan)",
                  ),
                  profileCard(
                    icon: Icons.calendar_today_outlined,
                    title: "Tahun Masuk",
                    subtitle: tahunMasuk.toString(),
                  ),
                  profileCard(
                    icon: Icons.supervisor_account_outlined,
                    title: "Nama Wali",
                    subtitle: namaWali,
                  ),
                  profileCard(
                    icon: Icons.phone_outlined,
                    title: "Kontak Wali",
                    subtitle: kontakWali,
                  ),

                  const SizedBox(height: 25),

                  InkWell(
                    onTap: handleLogout,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Keluar Akun",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 15),
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
                    fontSize: 13.5,
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
