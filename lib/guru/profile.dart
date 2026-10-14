import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/Auth/login.dart';

class ProfileGuruPage extends StatefulWidget {
  const ProfileGuruPage({super.key});

  @override
  State<ProfileGuruPage> createState() => _ProfileGuruPageState();
}

class _ProfileGuruPageState extends State<ProfileGuruPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  bool isLoading = true;
  Map<String, dynamic> guruProfile = {};
  String? error;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Token sesi tidak ditemukan.');
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.bkProfile),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            guruProfile = decoded is Map
                ? Map<String, dynamic>.from(decoded)
                : {};
            isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat profil');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        guruProfile = {
          'nama': 'Guru BK',
          'email': 'gurubk@ruangaman.com',
          'sekolah': 'Instansi Sekolah',
          'nip': '-',
          'jenis_kelamin': '-',
        };
        isLoading = false;
      });
    }
  }

  // Dialog / Form Edit Profil
  // Dialog / Form Edit Profil
  Future<void> _showEditProfileDialog() async {
    final namaController = TextEditingController(
      text: guruProfile['nama'] ?? '',
    );
    // Email dibuat readOnly, namun tetap disertakan nilainya untuk dikirim jika diperlukan backend
    final emailController = TextEditingController(
      text: guruProfile['email'] ?? '',
    );
    final nipController = TextEditingController(
      text: guruProfile['nip'] != '-' ? guruProfile['nip'] : '',
    );
    String selectedGender = guruProfile['jenis_kelamin'] ?? 'Perempuan';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              decoration: const BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 20),
                    const Text(
                      "Edit Profil Guru",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // FIELD EMAIL DIKUNCI (TIDAK DAPAT DIUBAH)
                    TextFormField(
                      controller: emailController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email (Tidak dapat diubah)',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nipController,
                      decoration: const InputDecoration(
                        labelText: 'NIP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['Laki-laki', 'Perempuan'].contains(selectedGender)
                          ? selectedGender
                          : 'Perempuan',
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        border: OutlineInputBorder(),
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
                      onChanged: (val) =>
                          setModalState(() => selectedGender = val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => saving = true);

                                try {
                                  final token = await storage.read(
                                    key: 'auth_token',
                                  );
                                  final response = await http
                                      .put(
                                        Uri.parse(ApiConfig.bkProfile),
                                        headers: {
                                          'Content-Type': 'application/json',
                                          'Accept': 'application/json',
                                          'Authorization': 'Bearer $token',
                                        },
                                        body: jsonEncode({
                                          'nama': namaController.text.trim(),
                                          // Email tidak ikut diubah/dikirim ulang jika dikunci
                                          'nip': nipController.text.trim(),
                                          'jenis_kelamin': selectedGender,
                                        }),
                                      )
                                      .timeout(const Duration(seconds: 15));

                                  if (response.statusCode == 200) {
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    loadProfile();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profil berhasil diperbarui',
                                        ),
                                        backgroundColor: primaryColor,
                                      ),
                                    );
                                  } else {
                                    throw Exception('Gagal memperbarui profil');
                                  }
                                } catch (e) {
                                  setModalState(() => saving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        child: saving
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

  @override
  Widget build(BuildContext context) {
    final nama = guruProfile['nama'] ?? 'Guru BK';
    final email = guruProfile['email'] ?? 'email@sekolah.sch.id';
    final sekolah = guruProfile['sekolah'] ?? 'Instansi Sekolah';
    final nip = guruProfile['nip'] ?? '-';
    final jenisKelamin = guruProfile['jenis_kelamin'] ?? '-';

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Profil",
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: _showEditProfileDialog,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: primaryColor,
                        ),
                        tooltip: 'Edit Profil',
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: lightGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 62,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    nama,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff263330),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Guru Bimbingan & Konseling",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 15,
                          color: primaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Guru BK",
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Informasi Akun",
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff263330),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  profileCard(
                    icon: Icons.person_outline,
                    title: "Data Pribadi",
                    subtitle: email,
                    onTap: () => _showDetailSheet(
                      context,
                      title: "Data Pribadi",
                      icon: Icons.person_outline,
                      children: [
                        DetailItem(label: "Nama", value: nama),
                        DetailItem(label: "Email", value: email),
                        DetailItem(label: "Jenis Kelamin", value: jenisKelamin),
                      ],
                    ),
                  ),
                  profileCard(
                    icon: Icons.school_outlined,
                    title: "Informasi Sekolah",
                    subtitle: sekolah,
                    onTap: () => _showDetailSheet(
                      context,
                      title: "Informasi Sekolah",
                      icon: Icons.school_outlined,
                      children: [
                        DetailItem(label: "Sekolah", value: sekolah),
                        const DetailItem(
                          label: "Jabatan",
                          value: "Guru Bimbingan & Konseling",
                        ),
                      ],
                    ),
                  ),
                  profileCard(
                    icon: Icons.badge_outlined,
                    title: "Informasi Kepegawaian",
                    subtitle: "NIP: $nip",
                    onTap: () => _showDetailSheet(
                      context,
                      title: "Informasi Kepegawaian",
                      icon: Icons.badge_outlined,
                      children: [
                        DetailItem(label: "NIP", value: nip),
                        const DetailItem(label: "Status", value: "Guru Tetap"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => _showLogoutDialog(context),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xffFDEDED),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xffEF4444),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Keluar",
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                color: Color(0xffEF4444),
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }

  Widget profileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffEEF2F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff34403D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xffA6B0AD),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 15, 22, 30),
          decoration: const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...children,
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Keluar dari akun?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Anda akan keluar dari akun Guru BK."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () async {
                await storage.delete(key: 'auth_token');
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text("Keluar"),
            ),
          ],
        );
      },
    );
  }
}

class DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const DetailItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff34403D),
            ),
          ),
        ],
      ),
    );
  }
}
