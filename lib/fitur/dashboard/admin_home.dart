import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:bersatubantu/fitur/widgets/banner_carousel.dart';
import 'package:bersatubantu/config/banner_config.dart';

// Import necessary screens
import 'package:bersatubantu/fitur/berikandonasi/berikandonasi.dart';
import 'package:bersatubantu/fitur/auth/login/admin_dashboard_screen.dart';
import 'package:bersatubantu/fitur/aturprofile/aturprofile.dart';
import 'package:bersatubantu/fitur/berita_sosial/models/berita_model.dart';
import 'package:bersatubantu/fitur/berita_sosial/screens/detail_berita.dart';
import 'package:bersatubantu/fitur/berita_sosial/screens/tambah_berita.dart';
import 'package:bersatubantu/theme/app_theme.dart';

class AdminHomeDashboard extends StatefulWidget {
  final int initialSelectedIndex;

  const AdminHomeDashboard({super.key, this.initialSelectedIndex = 0});

  @override
  State<AdminHomeDashboard> createState() => _AdminHomeDashboardState();
}

class _AdminHomeDashboardState extends State<AdminHomeDashboard>
    with AutomaticKeepAliveClientMixin {
  final supabase = Supabase.instance.client;

  int _selectedIndex = 0;

  static const String ADMIN_USERNAME = 'admin';

  // Campaigns State
  bool _isLoadingCampaigns = true;
  List<Map<String, dynamic>> _campaigns = [];

  // News State
  bool _isLoadingNews = true;
  List<Map<String, dynamic>> _featuredNews = [];
  List<Map<String, dynamic>> _popularNews = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
    _loadCampaigns();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);
    try {
      final response = await supabase
          .from('news')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> allNews =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        _popularNews = allNews.where((n) => n['is_popular'] == true).toList();
        _featuredNews = allNews.where((n) => n['is_popular'] != true).toList();

        if (_popularNews.isEmpty && allNews.isNotEmpty) {
          _popularNews = allNews.take(3).toList();
          _featuredNews = allNews.skip(3).toList();
        }
      });
    } catch (e) {
      print('[AdminDashboard] Error loading news: $e');
    } finally {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoadingCampaigns = true);
    try {
      final response = await supabase
          .from('donation_campaigns')
          .select(
            'id, title, cover_image_url, end_time, description, target_amount, collected_amount, location, location_name',
          )
          .eq('status', 'active')
          .gt('end_time', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(50);

      setState(() => _campaigns = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      print('[AdminDashboard] Error loading campaigns: $e');
      setState(() => _campaigns = []);
    } finally {
      if (mounted) setState(() => _isLoadingCampaigns = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  Map<String, dynamic> _remainingUntil(String? endTimeStr) {
    if (endTimeStr == null) return {'text': 'Tidak tersedia', 'days': null};
    try {
      final end = DateTime.parse(endTimeStr).toLocal();
      final now = DateTime.now();
      final diff = end.difference(now);
      if (diff.isNegative) return {'text': 'Selesai', 'days': diff.inDays};
      if (diff.inDays >= 1) {
        return {'text': '${diff.inDays} hari lagi', 'days': diff.inDays};
      }
      return {'text': '${diff.inHours} jam lagi', 'days': 0};
    } catch (e) {
      return {'text': 'Tidak tersedia', 'days': null};
    }
  }

  void _navigateToNewsDetail(Map<String, dynamic> news) async {
    final beritaData = BeritaModel(
      id: news['id'].toString(),
      judul: news['title'] ?? 'Tanpa Judul',
      tanggal: _formatDate(news['created_at']),
      category: news['category'] ?? 'Umum',
      image: news['image_url'] ?? '',
      source: news['source'] ?? 'Admin',
      isi: news['content'] ?? 'Konten tidak tersedia.',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailBeritaScreen(
          berita: beritaData,
          isAdmin: true,
        ),
      ),
    );

    _loadNews();
  }

  void _onNavTap(int index) async {
    if (index == _selectedIndex) return;

    if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
      return;
    }
    if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(isAdmin: true),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Selamat pagi,';
    if (hour >= 11 && hour < 15) return 'Selamat siang,';
    if (hour >= 15 && hour < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  // ─── BERANDA TAB ────────────────────────────────────────────────────────────
  Widget _buildBerandaTab() {
    final totalBerita = _featuredNews.length + _popularNews.length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                _buildStatCard(
                  Icons.newspaper_rounded,
                  '$totalBerita',
                  'Berita',
                  AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  Icons.volunteer_activism,
                  '${_campaigns.length}',
                  'Kampanye Aktif',
                  const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),

          // Campaigns section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kampanye Donasi Aktif',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF364057),
                          fontFamily: 'CircularStd',
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadCampaigns,
                        child: Text(
                          _isLoadingCampaigns ? 'Memuat...' : 'Refresh',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontFamily: 'CircularStd',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: _isLoadingCampaigns
                        ? const Center(child: CircularProgressIndicator())
                        : _campaigns.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada kampanye aktif',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _campaigns.length,
                            itemBuilder: (context, idx) {
                              final c = _campaigns[idx];
                              final rem = _remainingUntil(c['end_time']);
                              return GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BerikanDonasiScreen(donation: c),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 300,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          child: c['cover_image_url'] != null
                                              ? Image.network(
                                                  c['cover_image_url'],
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, e, s) =>
                                                      Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.image_not_supported,
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.image),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c['title'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              rem['text'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Quick actions
                  const Text(
                    'Aksi Cepat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF364057),
                      fontFamily: 'CircularStd',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          Icons.add_circle_outline,
                          'Tambah Berita',
                          AppTheme.primaryColor,
                          () async {
                            final added = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TambahBeritaScreen(),
                              ),
                            );
                            if (added == true) _loadNews();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          Icons.verified_user_outlined,
                          'Verifikasi Org',
                          const Color(0xFF4CAF50),
                          () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminDashboardScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── BERITA TAB ─────────────────────────────────────────────────────────────
  Widget _buildBeritaTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Telusuri Berita (Admin Mode)',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontFamily: 'CircularStd',
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Banner Carousel (same as personal/org dashboard)
          if (BannerConfig.isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  BannerCarousel(
                    banners: [
                      BannerItem(
                        title: 'Donasi MBG',
                        subtitle: 'Bantu masyarakat',
                        buttonText: 'Donasi Sekarang',
                        gradientColors: [Color(0xFF4A7FBD), Color(0xFF8FA3CC)],
                        icon: Icons.volunteer_activism_rounded,
                        imageAsset: 'assets/banners/banjir.png',
                        imageType: BannerImageType.asset,
                        showTextOverImage: false,
                        onTap: () {},
                      ),
                      BannerItem(
                        title: 'Bencana Aceh',
                        subtitle: 'Ringankan beban saudara kita di Aceh',
                        buttonText: 'Bantu Sekarang',
                        gradientColors: [Color(0xFF8B2500), Color(0xFFD9614C)],
                        icon: Icons.warning_rounded,
                        imageAsset: 'assets/banners/aceh.png',
                        imageType: BannerImageType.asset,
                        showTextOverImage: false,
                        onTap: () {},
                      ),
                      BannerItem(
                        title: 'Bencana Sawit',
                        subtitle: 'Dukung pemulihan masyarakat terdampak sawit',
                        buttonText: 'Bantu Sekarang',
                        gradientColors: [Color(0xFF2E6B2E), Color(0xFF66BB6A)],
                        icon: Icons.nature_rounded,
                        imageAsset: 'assets/banners/sawit.png',
                        imageType: BannerImageType.asset,
                        showTextOverImage: false,
                        onTap: () {},
                      ),
                      BannerItem(
                        title: 'Bantu Aceh',
                        subtitle: 'Ayo bergabung jadi relawan kemanusiaan di Aceh',
                        buttonText: 'Gabung Relawan',
                        gradientColors: [Color(0xFF8B2500), Color(0xFFE8A45A)],
                        icon: Icons.volunteer_activism_rounded,
                        imageAsset: 'assets/banners/aksiaceh.png',
                        imageType: BannerImageType.asset,
                        showTextOverImage: false,
                        onTap: () {},
                      ),
                      BannerItem(
                        title: 'Bersih Sungai',
                        subtitle: 'Ayo ikut bakti sosial membersihkan aliran sungai',
                        buttonText: 'Gabung Relawan',
                        gradientColors: [Color(0xFF1D8348), Color(0xFF52BE80)],
                        icon: Icons.nature_people_rounded,
                        imageAsset: 'assets/banners/aksisungai.png',
                        imageType: BannerImageType.asset,
                        showTextOverImage: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                  if (AppTheme.currentName() == AppTheme.merdekaName)
                    Positioned(
                      top: -10,
                      left: 0,
                      child: Image.asset(
                        'assets/pita_bendera.png',
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                  if (AppTheme.currentName() == AppTheme.merdekaName)
                    Positioned(
                      bottom: 10,
                      right: 0,
                      child: Transform.rotate(
                        angle: 3.14159,
                        child: Image.asset(
                          'assets/pita_bendera.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Title + Tambah Berita button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kelola Berita',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF364057),
                    fontFamily: 'CircularStd',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final added = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TambahBeritaScreen(),
                      ),
                    );
                    if (added == true) _loadNews();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Berita'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF364057),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'CircularStd',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable news content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured News (horizontal scroll)
                  SizedBox(
                    height: 200,
                    child: _isLoadingNews
                        ? const Center(child: CircularProgressIndicator())
                        : _featuredNews.isEmpty
                        ? const Center(child: Text('Belum ada berita'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _featuredNews.length,
                            itemBuilder: (context, index) {
                              final news = _featuredNews[index];
                              return GestureDetector(
                                onTap: () => _navigateToNewsDetail(news),
                                child: Container(
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A5E7C),
                                    borderRadius: BorderRadius.circular(16),
                                    image: news['image_url'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              news['image_url'],
                                            ),
                                            fit: BoxFit.cover,
                                            colorFilter: ColorFilter.mode(
                                              Colors.black.withValues(alpha: 0.4),
                                              BlendMode.darken,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          news['title'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDate(news['created_at']),
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.8),
                                                fontSize: 11,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Popular News Grid
                  const Text(
                    'Daftar Berita Lainnya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF364057),
                      fontFamily: 'CircularStd',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingNews
                      ? const Center(child: CircularProgressIndicator())
                      : _popularNews.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada berita lainnya',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: _popularNews.length,
                          itemBuilder: (context, index) {
                            final news = _popularNews[index];
                            return GestureDetector(
                              onTap: () => _navigateToNewsDetail(news),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                ),
                                            child: news['image_url'] != null
                                                ? Image.network(
                                                    news['image_url'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, e, s) =>
                                                            Container(
                                                              color: Colors
                                                                  .grey[300],
                                                              child: const Icon(
                                                                Icons.image,
                                                              ),
                                                            ),
                                                  )
                                                : Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.image,
                                                    ),
                                                  ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.4),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                news['title'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              news['source'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MAIN BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'CircularStd',
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        ADMIN_USERNAME,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontFamily: 'CircularStd',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (AppTheme.currentName() == AppTheme.merdekaName)
                        Image.asset(
                          'assets/boy_merdeka.png',
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF364057),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedIndex == 0 ? 'Admin' : 'Kelola Berita',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'CircularStd',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedIndex == 0
                    ? KeyedSubtree(key: const ValueKey(0), child: _buildBerandaTab())
                    : KeyedSubtree(key: const ValueKey(1), child: _buildBeritaTab()),
              ),
            ),

            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Beranda', 0),
                  _buildNavItem(Icons.newspaper, 'Berita', 1),
                  _buildNavItem(Icons.verified_user_outlined, 'Verifikasi', 2),
                  _buildNavItem(Icons.person_outline_rounded, 'Profil', 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
