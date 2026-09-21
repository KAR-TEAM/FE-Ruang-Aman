import 'package:flutter/material.dart';

class ProfileGuruPage extends StatelessWidget {
  const ProfileGuruPage({super.key});

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,

      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 30,
            bottom: 100,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  // =====================================================
                  // HEADER
                  // =====================================================
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Profil",
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =====================================================
                  // PROFILE IMAGE
                  // =====================================================
                  Container(
                    width: 105,
                    height: 105,

                    decoration: BoxDecoration(
                      color: lightGreen,
                      shape: BoxShape.circle,

                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),

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

                  // =====================================================
                  // NAMA
                  // =====================================================
                  const Text(
                    "Ibu Rina Kartika",
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff263330),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // =====================================================
                  // ROLE
                  // =====================================================
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

                  // =====================================================
                  // BADGE GURU
                  // =====================================================
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

                  // =====================================================
                  // INFORMASI AKUN
                  // =====================================================
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
                    subtitle: "Lihat dan ubah informasi diri",

                    onTap: () {
                      _showDataPribadi(context);
                    },
                  ),

                  profileCard(
                    icon: Icons.school_outlined,
                    title: "Informasi Sekolah",
                    subtitle: "SMAN 1 Contoh",

                    onTap: () {
                      _showInformasiSekolah(context);
                    },
                  ),

                  profileCard(
                    icon: Icons.badge_outlined,
                    title: "Informasi Kepegawaian",
                    subtitle: "NIP dan data Guru BK",

                    onTap: () {
                      _showKepegawaian(context);
                    },
                  ),

                  const SizedBox(height: 15),

                  // =====================================================
                  // PENGATURAN
                  // =====================================================
                  const Align(
                    alignment: Alignment.centerLeft,

                    child: Text(
                      "Pengaturan",

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
                    icon: Icons.lock_outline,
                    title: "Ubah Password",
                    subtitle: "Ganti password akun",

                    onTap: () {
                      _showSimpleMessage(
                        context,
                        "Ubah Password",
                        "Fitur ubah password belum tersedia.",
                      );
                    },
                  ),

                  profileCard(
                    icon: Icons.notifications_none,
                    title: "Notifikasi",
                    subtitle: "Atur pemberitahuan laporan",

                    onTap: () {
                      _showSimpleMessage(
                        context,
                        "Notifikasi",
                        "Pengaturan notifikasi akan tersedia di sini.",
                      );
                    },
                  ),

                  profileCard(
                    icon: Icons.help_outline,
                    title: "Bantuan",
                    subtitle: "Pusat bantuan RuangAman",

                    onTap: () {
                      _showSimpleMessage(
                        context,
                        "Bantuan",
                        "Silakan hubungi administrator jika mengalami kendala.",
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // =====================================================
                  // LOGOUT
                  // =====================================================
                  Material(
                    color: Colors.transparent,

                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),

                      onTap: () {
                        _showLogoutDialog(context);
                      },

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

                  const SizedBox(height: 25),

                  // =====================================================
                  // VERSION
                  // =====================================================
                  const Text(
                    "RuangAman v1.0.0",

                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 10,
                      color: Colors.grey,
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

  // ============================================================
  // PROFILE CARD
  // ============================================================
  Widget profileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xffEEF2F0),
        ),

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

                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 22,
                  ),
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

                const SizedBox(width: 8),

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

  // ============================================================
  // DATA PRIBADI
  // ============================================================
  void _showDataPribadi(BuildContext context) {
    _showDetailSheet(
      context,
      title: "Data Pribadi",
      icon: Icons.person_outline,
      children: const [
        DetailItem(
          label: "Nama",
          value: "Rina Kartika, S.Pd.",
        ),

        DetailItem(
          label: "Email",
          value: "guru@gmail.com",
        ),

        DetailItem(
          label: "No. Telepon",
          value: "0812-3456-7890",
        ),

        DetailItem(
          label: "Jenis Kelamin",
          value: "Perempuan",
        ),
      ],
    );
  }

  // ============================================================
  // SEKOLAH
  // ============================================================
  void _showInformasiSekolah(BuildContext context) {
    _showDetailSheet(
      context,
      title: "Informasi Sekolah",
      icon: Icons.school_outlined,
      children: const [
        DetailItem(
          label: "Sekolah",
          value: "SMAN 1 Contoh",
        ),

        DetailItem(
          label: "Jabatan",
          value: "Guru Bimbingan & Konseling",
        ),

        DetailItem(
          label: "Unit",
          value: "Bimbingan dan Konseling",
        ),
      ],
    );
  }

  // ============================================================
  // KEPEGAWAIAN
  // ============================================================
  void _showKepegawaian(BuildContext context) {
    _showDetailSheet(
      context,
      title: "Informasi Kepegawaian",
      icon: Icons.badge_outlined,
      children: const [
        DetailItem(
          label: "NIP",
          value: "19870612 201501 2 001",
        ),

        DetailItem(
          label: "Status",
          value: "Guru Tetap",
        ),

        DetailItem(
          label: "Jabatan",
          value: "Guru BK",
        ),

        DetailItem(
          label: "Masa Kerja",
          value: "11 Tahun",
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL BOTTOM SHEET
  // ============================================================
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
          padding: const EdgeInsets.fromLTRB(
            22,
            15,
            22,
            30,
          ),

          decoration: const BoxDecoration(
            color: backgroundColor,

            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
          ),

          child: SafeArea(
            top: false,

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

                      child: Icon(
                        icon,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        title,

                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                ...children,
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SIMPLE MESSAGE
  // ============================================================
  void _showSimpleMessage(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                "OK",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            "Anda akan keluar dari akun Guru BK.",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                "Batal",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
              ),

              onPressed: () {
                Navigator.pop(context);

                // NANTI ARAHKAN KE LOGIN
                // Navigator.pushAndRemoveUntil(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => const LoginScreen(),
                //   ),
                //   (route) => false,
                // );
              },

              child: const Text(
                "Keluar",
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// DETAIL ITEM
// ============================================================================
class DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const DetailItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),

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