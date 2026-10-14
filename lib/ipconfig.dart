class ApiConfig {
  static const String baseUrl = 'http://localhost:5000';

  //Auth
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';
  static const String searchSchool = '$baseUrl/api/auth/search';

  // Admin
  static const String superadminStats = '$baseUrl/api/superadmin/schools-stats';
  static const String schools = '$baseUrl/api/superadmin/schools';
  static const String searchSchools = '$baseUrl/api/superadmin/search';
  static String schoolById(dynamic id) => '$schools/$id';
  static const String adminSchools = '$baseUrl/api/superadmin/admin-schools';
  static const String users = '$baseUrl/api/superadmin/users';
  static String userById(dynamic id) => '$users/$id';

  // Siswa
  static const String dashboardSiswa = '$baseUrl/api/siswa/';
  static const String myReports = '$baseUrl/api/siswa/my-reports';
  static const String createReport = '$baseUrl/api/siswa/reports';
  static const String profileSiswa = '$baseUrl/api/siswa/profile';

  // Guru
  static const String bkDashboardStats = '$baseUrl/api/bk/stats';
  static const String bkReports = '$baseUrl/api/bk/reports';
  static const String bkSiswa = '$baseUrl/api/bk/siswa';
  static String bkReportFollowups(dynamic id) =>
      '$baseUrl/api/bk/reports/${Uri.encodeComponent(id.toString())}/followups';
  static const String bkProfile = '$baseUrl/api/bk/profile';

  // Admin Sekolah
  static const String adminStats = '$baseUrl/api/adminsekolah/stats';
  static const String adminReports = '$baseUrl/api/adminsekolah/getallreports';
  static const String adminUsers = '$baseUrl/api/adminsekolah/getallusers';
}
