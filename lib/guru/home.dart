import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedRange = "7 Hari Terakhir";

  // ============================================================
  // WARNA RUANGAMAN
  // ============================================================
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,

      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 25,
                bottom: 110,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================
                      _buildHeader(),

                      const SizedBox(height: 25),

                      // ==================================================
                      // WELCOME
                      // ==================================================
                      _buildWelcomeCard(),

                      const SizedBox(height: 25),

                      // ==================================================
                      // FILTER
                      // ==================================================
                      _buildFilter(),

                      const SizedBox(height: 25),

                      // ==================================================
                      // RINGKASAN
                      // ==================================================
                      const Text(
                        "Ringkasan Laporan",
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1F2937),
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildStatisticGrid(),

                      const SizedBox(height: 28),

                      // ==================================================
                      // PRIORITAS
                      // ==================================================
                      _buildRiskHeader(),

                      const SizedBox(height: 15),

                      _buildRiskCard(),

                      const SizedBox(height: 28),

                      // ==================================================
                      // AKTIVITAS
                      // ==================================================
                      const Text(
                        "Aktivitas Terbaru",
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1F2937),
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildActivityCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Dashboard",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),

              SizedBox(height: 5),

              Text(
                "Pantau laporan siswa hari ini",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // NOTIFIKASI
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none,
                size: 27,
                color: Colors.grey,
              ),

              Positioned(
                right: 10,
                top: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat datang, Guru BK 👋",
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPrimary,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "Pantau kondisi siswa dan tindak lanjuti laporan yang membutuhkan perhatian.",
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 12,
                    color: Color(0xff55736D),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xffD7EFE8),
              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.health_and_safety_outlined,
              color: primaryColor,
              size: 31,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================
  Widget _buildFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Rentang Waktu",
          style: TextStyle(
            decoration: TextDecoration.none,
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 52,
          width: double.infinity,

          padding: const EdgeInsets.symmetric(horizontal: 14),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),

            border: Border.all(color: const Color(0xffE4EBE8)),
          ),

          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,

                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),

                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: primaryColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRange,
                    isExpanded: true,

                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),

                    style: const TextStyle(
                      decoration: TextDecoration.none,
                      color: Color(0xff3B4A47),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),

                    items: const [
                      DropdownMenuItem(
                        value: "7 Hari Terakhir",
                        child: Text(
                          "7 Hari Terakhir",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      DropdownMenuItem(
                        value: "30 Hari Terakhir",
                        child: Text(
                          "30 Hari Terakhir",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      DropdownMenuItem(
                        value: "3 Bulan Terakhir",
                        child: Text(
                          "3 Bulan Terakhir",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRange = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GRID STATISTIK RESPONSIVE
  // ============================================================
  Widget _buildStatisticGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;

        if (constraints.maxWidth >= 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 350) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisSpacing: 12,
          mainAxisSpacing: 12,

          // Tinggi card dibuat tetap agar isi
          // tidak overflow ke bawah.
          mainAxisExtent: 165,

          children: const [
            StatCard(
              title: "Total Laporan",
              value: "128",
              subtitle: "Semua laporan",
              icon: Icons.description_outlined,
              iconBackground: Color(0xffE9F7F1),
              iconColor: primaryColor,
            ),

            StatCard(
              title: "Sedang Ditangani",
              value: "23",
              subtitle: "Sedang diproses",
              icon: Icons.hourglass_bottom_rounded,
              iconBackground: Color(0xffFFF4E1),
              iconColor: Color(0xffF59E0B),
            ),

            StatCard(
              title: "Selesai",
              value: "78",
              subtitle: "Telah diselesaikan",
              icon: Icons.check_circle_outline_rounded,
              iconBackground: Color(0xffE8F1FF),
              iconColor: Color(0xff3B82F6),
            ),

            StatCard(
              title: "Risiko Tinggi",
              value: "5",
              subtitle: "Butuh perhatian",
              icon: Icons.warning_amber_rounded,
              iconBackground: Color(0xffFDECEC),
              iconColor: Color(0xffEF4444),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HEADER PRIORITAS
  // ============================================================
  Widget _buildRiskHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Prioritas Risiko",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xff1F2937),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),

          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(20),
          ),

          child: const Text(
            "Laporan Aktif",

            style: TextStyle(
              decoration: TextDecoration.none,
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RISK CARD RESPONSIVE
  // ============================================================
  Widget _buildRiskCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

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

      child: LayoutBuilder(
        builder: (context, constraints) {
          // Kalau ruang sempit, chart dan legend
          // disusun vertikal.
          final bool smallScreen = constraints.maxWidth < 430;

          final Widget chart = SizedBox(
            width: 125,
            height: 125,

            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 38,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,

                    borderData: FlBorderData(show: false),

                    sections: [
                      PieChartSectionData(
                        value: 14,
                        color: const Color(0xffEF5350),
                        radius: 15,
                        title: "",
                      ),

                      PieChartSectionData(
                        value: 41,
                        color: const Color(0xffF4A340),
                        radius: 15,
                        title: "",
                      ),

                      PieChartSectionData(
                        value: 45,
                        color: const Color(0xff35B99A),
                        radius: 15,
                        title: "",
                      ),
                    ],
                  ),
                ),

                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "124",
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      "Laporan",
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          const Widget legend = Column(
            children: [
              RiskLegendItem(
                color: Color(0xffEF5350),
                label: "Tinggi",
                value: "16",
                percentage: "14%",
              ),

              SizedBox(height: 14),

              RiskLegendItem(
                color: Color(0xffF4A340),
                label: "Sedang",
                value: "52",
                percentage: "41%",
              ),

              SizedBox(height: 14),

              RiskLegendItem(
                color: Color(0xff35B99A),
                label: "Rendah",
                value: "56",
                percentage: "45%",
              ),
            ],
          );

          return Column(
            children: [
              if (smallScreen)
                Column(
                  children: [
                    Center(child: chart),

                    const SizedBox(height: 20),

                    const SizedBox(width: double.infinity, child: legend),
                  ],
                )
              else
                Row(
                  children: [
                    chart,

                    const SizedBox(width: 20),

                    const Expanded(child: legend),
                  ],
                ),

              const SizedBox(height: 18),

              // INFO
              Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),

                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(13),
                ),

                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(Icons.info_outline, color: primaryColor, size: 18),

                    SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        "5 laporan risiko tinggi membutuhkan tindak lanjut segera.",

                        style: TextStyle(
                          decoration: TextDecoration.none,
                          color: Color(0xff66756F),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // AKTIVITAS TERBARU
  // ============================================================
  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: const Column(
        children: [
          ActivityItem(
            icon: Icons.description_outlined,
            iconBackground: Color(0xffE9F7F1),
            iconColor: primaryColor,
            title: "Laporan baru diterima",
            subtitle: "Siswa mengirim laporan baru",
            time: "10 menit",
          ),

          Divider(height: 1, color: Color(0xffEEEEEE)),

          ActivityItem(
            icon: Icons.check_circle_outline,
            iconBackground: Color(0xffE8F1FF),
            iconColor: Color(0xff3B82F6),
            title: "Laporan selesai",
            subtitle: "Laporan berhasil ditindaklanjuti",
            time: "1 jam",
          ),

          Divider(height: 1, color: Color(0xffEEEEEE)),

          ActivityItem(
            icon: Icons.warning_amber_rounded,
            iconBackground: Color(0xffFDECEC),
            iconColor: Color(0xffEF4444),
            title: "Risiko tinggi terdeteksi",
            subtitle: "Laporan memerlukan perhatian segera",
            time: "2 jam",
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STAT CARD
// ============================================================================
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  final IconData icon;

  final Color iconBackground;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, size: 21, color: iconColor),
          ),

          const SizedBox(height: 10),

          Text(
            value,

            maxLines: 1,

            style: const TextStyle(
              decoration: TextDecoration.none,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xff1E2926),
              height: 1,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            title,

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              decoration: TextDecoration.none,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LEGEND RISIKO
// ============================================================================
class RiskLegendItem extends StatelessWidget {
  final Color color;

  final String label;
  final String value;
  final String percentage;

  const RiskLegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,

          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,

                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,

                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff293532),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(15),
          ),

          child: Text(
            percentage,

            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ACTIVITY ITEM
// ============================================================================
class ActivityItem extends StatelessWidget {
  final IconData icon;

  final Color iconBackground;
  final Color iconColor;

  final String title;
  final String subtitle;
  final String time;

  const ActivityItem({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool verySmall = constraints.maxWidth < 330;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: iconBackground,

                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(icon, color: iconColor, size: 21),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        decoration: TextDecoration.none,

                        fontSize: 12,

                        fontWeight: FontWeight.w600,

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

                        fontSize: 10,

                        color: Colors.grey,
                      ),
                    ),

                    // Jika layar sangat kecil,
                    // waktu diletakkan di bawah.
                    if (verySmall) ...[
                      const SizedBox(height: 5),

                      Text(
                        time,

                        style: const TextStyle(
                          decoration: TextDecoration.none,

                          fontSize: 9.5,

                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Pada ukuran normal waktu di kanan.
              if (!verySmall) ...[
                const SizedBox(width: 10),

                Text(
                  time,

                  maxLines: 1,

                  style: const TextStyle(
                    decoration: TextDecoration.none,

                    fontSize: 9.5,

                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
