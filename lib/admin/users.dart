import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  bool loading = true;
  bool showSearch = false;
  String? error;
  List<Map<String, dynamic>> users = [];
  String selectedRole = 'Semua';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
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

  Future<void> loadUsers() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      String url = '${ApiConfig.baseUrl}/api/adminsekolah/getallusers';
      List<String> queryParams = [];

      final keyword = searchController.text.trim();
      if (keyword.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(keyword)}');
      }
      if (selectedRole != 'Semua') {
        // Menyesuaikan nilai role dengan yang disimpan di database/controller
        String roleParam = selectedRole.toLowerCase();
        if (roleParam == 'guru bk') roleParam = 'guru bk';
        queryParams.add('role=${Uri.encodeComponent(roleParam)}');
      }
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          data = decoded['data'];
        }

        if (mounted) {
          setState(() {
            users = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            loading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data pengguna (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString().replaceFirst('Exception: ', '');
          loading = false;
        });
      }
    }
  }

  Future<void> confirmAndDeleteUser(String userId, String namaUser) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkPrimary)),
        content: Text('Apakah Anda yakin ingin menghapus akun "$namaUser"? Tindakan ini tidak dapat dibatalkan.', style: const TextStyle(fontSize: 13, color: Color(0xff34403D))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await storage.read(key: 'auth_token');
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/user/$userId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        showMessage('Pengguna berhasil dihapus', success: true);
        loadUsers();
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['error'] ?? 'Gagal menghapus pengguna');
      }
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin' || 'admin sekolah':
        return const Color(0xffEF4444);
      case 'guru bk' || 'guru':
        return const Color(0xff3B82F6);
      case 'siswa':
        return const Color(0xff16A66A);
      default:
        return Colors.grey;
    }
  }

  Widget badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Pengguna',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Daftar akun siswa dan guru di sekolah',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  headerButton(icon: Icons.refresh_rounded, onTap: loadUsers),
                  const SizedBox(width: 8),
                  headerButton(
                    icon: Icons.search_rounded,
                    onTap: () {
                      setState(() {
                        showSearch = !showSearch;
                        if (!showSearch) {
                          searchController.clear();
                          loadUsers();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showSearch
                  ? Padding(
                      key: const ValueKey('search-box'),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: TextField(
                        controller: searchController,
                        onSubmitted: (_) => loadUsers(),
                        decoration: InputDecoration(
                          hintText: 'Cari nama pengguna...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchController.clear();
                              loadUsers();
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-search')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  filterChip('Semua'),
                  filterChip('Siswa'),
                  filterChip('Guru BK'),
                  filterChip('Admin'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loading ? 'Memuat data...' : '${users.length} akun ditemukan',
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: loadUsers,
                child: loading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : error != null
                        ? Center(child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)))
                        : users.isEmpty
                            ? const Center(child: Text('Tidak ada pengguna ditemukan', style: TextStyle(color: Colors.grey, fontSize: 12.5)))
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final userId = user['id']?.toString() ?? '';
                                  final nama = user['nama'] ?? user['name'] ?? 'Tanpa Nama';
                                  final email = user['email'] ?? '-';
                                  final role = user['role'] ?? 'siswa';
                                  final kelas = user['kelas'];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2)),
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
                                          child: const Icon(Icons.person_outline_rounded, color: primaryColor, size: 20),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nama,
                                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: darkPrimary),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                email,
                                                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                              ),
                                              if (kelas != null && kelas.toString().isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Kelas: $kelas',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xff34403D)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            badge(role, roleColor(role)),
                                            const SizedBox(height: 6),
                                            InkWell(
                                              onTap: () => confirmAndDeleteUser(userId, nama),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: darkPrimary),
        ),
      ),
    );
  }

  Widget filterChip(String label) {
    final active = selectedRole.toLowerCase() == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() => selectedRole = label);
          loadUsers();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? primaryColor : const Color(0xffE2ECE9)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xff34403D),
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}