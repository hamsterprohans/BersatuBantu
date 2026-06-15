import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:bersatubantu/fitur/widgets/bottom_navbar.dart';
import 'package:bersatubantu/fitur/widgets/banner_carousel.dart';
import 'package:bersatubantu/config/banner_config.dart';
import 'package:bersatubantu/fitur/donasi/donasi_screen.dart';
import 'package:bersatubantu/fitur/berikandonasi/berikandonasi.dart';
import 'dart:async';
import 'package:bersatubantu/fitur/aturprofile/aturprofile.dart';
import 'package:bersatubantu/fitur/aksi/aksi_screen.dart';
import 'package:provider/provider.dart';
import 'package:bersatubantu/providers/volunteer_event_provider.dart';
import 'package:bersatubantu/fitur/pilihdaftar/register_volunteer_screen.dart'
    show EventDetailBottomSheet;
import 'package:bersatubantu/theme/app_theme.dart';
import 'package:bersatubantu/fitur/berita_sosial/models/berita_model.dart';
import 'package:bersatubantu/fitur/berita_sosial/screens/detail_berita.dart';
import 'package:bersatubantu/fitur/postingkegiatandonasi/postingkegiatandonasi.dart';

class DashboardScreenOrganisasi extends StatefulWidget {
  final int requestId;
  final String organizationName;

  const DashboardScreenOrganisasi({
    super.key,
    required this.requestId,
    this.organizationName = '',
  });

  @override
  State<DashboardScreenOrganisasi> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreenOrganisasi>
    with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSubscription;

  int _selectedIndex = 0;
  String _selectedCategory = 'Semua';
  String _userName = '';
  bool _isLoadingUser = true;
  // Campaigns
  bool _isLoadingCampaigns = true;
  List<Map<String, dynamic>> _campaigns = [];

  final List<String> _categories = [
    'Semua',
    'Bencana Alam',
    'Kemiskinan',
    'Hak Asasi',
  ];

  bool _isLoadingNews = true;
  List<Map<String, dynamic>> _featuredNews = [];
  List<Map<String, dynamic>> _popularNews = [];

  bool _isLoadingEvents = true;
  List<Map<String, dynamic>> _myEvents = [];

  @override
  void initState() {
    super.initState();

    // Register WidgetsBindingObserver untuk track lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Org users don't use Supabase Auth — ignore auth state changes for name
    _authSubscription = supabase.auth.onAuthStateChange.listen((_) {});

    // Initial load: prefer passed name, fallback to DB lookup by requestId
    if (widget.organizationName.isNotEmpty) {
      _userName = widget.organizationName;
      _isLoadingUser = false;
    } else {
      _loadOrgName();
    }
    _loadCampaigns();
    _loadNews();
    _loadMyEvents();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      // Get current user ID from auth
      final user = supabase.auth.currentUser;

      if (user == null) {
        print('[Dashboard] No authenticated user found');
        setState(() {
          _userName = 'Pengguna';
          _isLoadingUser = false;
        });
        return;
      }

      print('[Dashboard] Current user ID: ${user.id}');
      print('[Dashboard] User email: ${user.email}');

      // Query profiles table with the user ID - ALWAYS CHECK DATABASE FIRST
      print(
        '[Dashboard] Querying profiles table for fresh data from user ID: ${user.id}',
      );

      final response = await supabase
          .from('profiles')
          .select('full_name, email, id')
          .eq('id', user.id)
          .maybeSingle();

      print('[Dashboard] Query response: $response');

      if (response != null) {
        print('[Dashboard] Profile found in database');

        final fullName = response['full_name'];
        print(
          '[Dashboard] Full name value: "$fullName" (type: ${fullName.runtimeType})',
        );

        if (fullName != null) {
          final nameString = fullName.toString().trim();
          print('[Dashboard] After trim: "$nameString"');

          if (nameString.isNotEmpty) {
            setState(() {
              _userName = nameString;
              _isLoadingUser = false;
            });
            print(
              '[Dashboard] Successfully loaded user name from DB: $_userName',
            );
            return;
          }
        }

        // Fallback: Try email prefix
        print(
          '[Dashboard] full_name is null or empty, using email prefix fallback',
        );
        final email = response['email'] ?? user.email;
        final nameFromEmail = email?.split('@')[0] ?? 'Pengguna';
        setState(() {
          _userName = nameFromEmail;
          _isLoadingUser = false;
        });
        print('[Dashboard] Using email prefix: $_userName');
      } else {
        // Profile not found in database
        print(
          '[Dashboard] No profile found in database for user ID: ${user.id}',
        );

        final email = user.email;
        final nameFromEmail = email?.split('@')[0] ?? 'Pengguna';
        setState(() {
          _userName = nameFromEmail;
          _isLoadingUser = false;
        });
        print('[Dashboard] Using email prefix as fallback: $_userName');
      }
    } catch (e, stackTrace) {
      print('[Dashboard] Error loading user data: $e');
      print('[Dashboard] Stack trace: $stackTrace');

      // Fallback to email prefix
      final user = supabase.auth.currentUser;
      final email = user?.email;
      final nameFromEmail = email?.split('@')[0] ?? 'Pengguna';

      setState(() {
        _userName = nameFromEmail;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadOrgName() async {
    try {
      final response = await supabase
          .from('organization_request')
          .select('nama_organisasi')
          .eq('request_id', widget.requestId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _userName = (response?['nama_organisasi'] as String?)?.trim().isNotEmpty == true
              ? response!['nama_organisasi'] as String
              : 'Organisasi';
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Organisasi';
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoadingCampaigns = true;
    });

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

      setState(() {
        _campaigns = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('[Dashboard] Error loading campaigns: $e');
      setState(() {
        _campaigns = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCampaigns = false;
        });
      }
    }
  }

  // Returns a pair: formatted string and daysLeft (rounded down)
  Map<String, dynamic> _remainingUntil(String? endTimeStr) {
    if (endTimeStr == null) return {'text': 'Tidak tersedia', 'days': null};

    try {
      final end = DateTime.parse(endTimeStr).toLocal();
      final now = DateTime.now();
      final diff = end.difference(now);
      final days = diff.inDays;
      if (diff.isNegative) {
        return {'text': 'Selesai', 'days': days};
      }
      if (days >= 1) {
        return {'text': '$days hari lagi', 'days': days};
      }
      final hours = diff.inHours;
      if (hours >= 1) return {'text': '$hours jam lagi', 'days': 0};
      final minutes = diff.inMinutes;
      return {'text': '$minutes menit lagi', 'days': 0};
    } catch (e) {
      return {'text': 'Tidak tersedia', 'days': null};
    }
  }

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);
    try {
      final response = await supabase
          .from('news')
          .select()
          .order('created_at', ascending: false);
      final allNews = List<Map<String, dynamic>>.from(response);
      setState(() {
        _popularNews = allNews.where((n) => n['is_popular'] == true).toList();
        _featuredNews = allNews.where((n) => n['is_popular'] != true).toList();
        if (_popularNews.isEmpty && allNews.isNotEmpty) {
          _popularNews = allNews.take(3).toList();
          _featuredNews = allNews.skip(3).toList();
        }
      });
    } catch (e) {
      // silent fail
    } finally {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  Widget _eventImagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xFFEEF1F7),
      child: Icon(Icons.volunteer_activism_outlined, color: Colors.grey[400], size: 32),
    );
  }

  Future<void> _loadMyEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await supabase
          .from('events')
          .select('id, title, cover_image_url, start_time, location, status, category')
          .eq('organization_id', userId)
          .order('created_at', ascending: false);
      setState(() {
        _myEvents = List<Map<String, dynamic>>.from(response);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d/M/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  void _navigateToNewsDetail(Map<String, dynamic> news) {
    final berita = BeritaModel(
      id: news['id'].toString(),
      judul: news['title'] ?? 'Tanpa Judul',
      tanggal: _formatDate(news['created_at']),
      category: news['category'] ?? 'Umum',
      image: news['image_url'] ?? '',
      source: news['source'] ?? 'Admin',
      isi: news['content'] ?? '',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailBeritaScreen(berita: berita, isAdmin: false),
      ),
    );
  }

  Future<void> _openCampaignById(String campaignId) async {
    try {
      final data = await supabase
          .from('donation_campaigns')
          .select('*')
          .eq('id', campaignId)
          .maybeSingle();
      if (!mounted) return;
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kampanye tidak ditemukan'), backgroundColor: Colors.orange),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BerikanDonasiScreen(donation: data)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka kampanye: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openEventById(String eventId) async {
    try {
      final user = supabase.auth.currentUser;
      final userId = user?.id ?? '';
      if (!mounted) return;
      final provider = Provider.of<VolunteerEventProvider>(context, listen: false);
      provider.loadEventDetails(eventId: eventId, userId: userId);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => EventDetailBottomSheet(eventId: eventId, userId: userId),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka kegiatan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return 'Selamat pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat sore,';
    } else {
      return 'Selamat malam,';
    }
  }

  // Refresh user data when returning from other screens
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('[Dashboard] App resumed - Refreshing user data');
      _loadUserData();
    }
  }

  void _onNavTap(int index) async {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        // Already on Beranda, do nothing
        setState(() {
          _selectedIndex = index;
        });
        break;
      case 1:
        // Navigate to Donasi screen
        print('[Dashboard] Navigate to Donasi');
        setState(() { _selectedIndex = index; });
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DonasiScreen(fromOrganization: true)),
        );
        setState(() { _selectedIndex = 0; });
        break;
      case 2:
        // Navigate to Aksi screen
        print('[Dashboard] Navigate to Aksi');
        setState(() { _selectedIndex = index; });
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AksiScreen(forceOrganizationMode: true),
          ),
        );
        setState(() { _selectedIndex = 0; });
        break;
      case 3:
        // Navigate to Profil (Atur Profil)
        print('[Dashboard] Navigate to Profil');
        setState(() { _selectedIndex = index; });
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              fromOrganization: true,
              organizationName: _userName,
              requestId: widget.requestId,
            ),
          ),
        );
        setState(() { _selectedIndex = 0; });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _isLoadingUser
                        ? Row(
                            children: [
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Memuat...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'CircularStd',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'CircularStd',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontFamily: 'CircularStd',
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                  ),
                  Image.asset(
                    'assets/boy_merdeka.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF364057),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Beritaku',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'CircularStd',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Container
            Expanded(
              child: Container(
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
                                  hintText: 'Telusuri',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontFamily: 'CircularStd',
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Berita Title
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Berita',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF364057),
                            fontFamily: 'CircularStd',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Chips
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final isSelected =
                              _selectedCategory == _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(_categories[index]),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF364057),
                                fontFamily: 'CircularStd',
                                fontSize: 13,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF364057),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF364057)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              onSelected: (value) {
                                setState(() {
                                  _selectedCategory = _categories[index];
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // === BANNER CAROUSEL ===
                            if (BannerConfig.isEnabled)
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  BannerCarousel(
                                    banners: [
                                      BannerItem(
                                        title: 'Donasi MBG',
                                        subtitle: 'Bantu masyarakat',
                                        buttonText: 'Donasi Sekarang',
                                        gradientColors: [const Color(0xFF4A7FBD), const Color(0xFF8FA3CC)],
                                        icon: Icons.volunteer_activism_rounded,
                                        imageAsset: 'assets/banners/banjir.png',
                                        imageType: BannerImageType.asset,
                                        showTextOverImage: false,
                                        onTap: () => _openCampaignById('490d6abe-8332-446d-befa-1875ae71671d'),
                                      ),
                                      BannerItem(
                                        title: 'Bencana Aceh',
                                        subtitle: 'Ringankan beban saudara kita di Aceh',
                                        buttonText: 'Bantu Sekarang',
                                        gradientColors: [const Color(0xFF8B2500), const Color(0xFFD9614C)],
                                        icon: Icons.warning_rounded,
                                        imageAsset: 'assets/banners/aceh.png',
                                        imageType: BannerImageType.asset,
                                        showTextOverImage: false,
                                        onTap: () => _openCampaignById('5716ea27-7e7b-4688-8eba-00a9c7020a64'),
                                      ),
                                      BannerItem(
                                        title: 'Bencana Sawit',
                                        subtitle: 'Dukung pemulihan masyarakat terdampak sawit',
                                        buttonText: 'Bantu Sekarang',
                                        gradientColors: [const Color(0xFF2E6B2E), const Color(0xFF66BB6A)],
                                        icon: Icons.nature_rounded,
                                        imageAsset: 'assets/banners/sawit.png',
                                        imageType: BannerImageType.asset,
                                        showTextOverImage: false,
                                        onTap: () => _openCampaignById('9378ceff-d1e0-4241-93b1-df622eca4571'),
                                      ),
                                      BannerItem(
                                        title: 'Bantu Aceh',
                                        subtitle: 'Ayo bergabung jadi relawan kemanusiaan di Aceh',
                                        buttonText: 'Gabung Relawan',
                                        gradientColors: [const Color(0xFF8B2500), const Color(0xFFE8A45A)],
                                        icon: Icons.volunteer_activism_rounded,
                                        imageAsset: 'assets/banners/aksiaceh.png',
                                        imageType: BannerImageType.asset,
                                        showTextOverImage: false,
                                        onTap: () => _openEventById('e5fe54f5-c0e9-4df7-b8d8-10f448a151cd'),
                                      ),
                                      BannerItem(
                                        title: 'Bersih Sungai',
                                        subtitle: 'Ayo ikut bakti sosial membersihkan aliran sungai',
                                        buttonText: 'Gabung Relawan',
                                        gradientColors: [const Color(0xFF1D8348), const Color(0xFF52BE80)],
                                        icon: Icons.nature_people_rounded,
                                        imageAsset: 'assets/banners/aksisungai.png',
                                        imageType: BannerImageType.asset,
                                        showTextOverImage: false,
                                        onTap: () => _openEventById('a4f1ab38-f2bf-456c-bf5c-190065b1ae3c'),
                                      ),
                                    ],
                                  ),
                                  if (AppTheme.currentName() == AppTheme.merdekaName)
                                    Positioned(
                                      top: -10, left: 0,
                                      child: Image.asset('assets/pita_bendera.png', height: 60, fit: BoxFit.contain),
                                    ),
                                  if (AppTheme.currentName() == AppTheme.merdekaName)
                                    Positioned(
                                      bottom: 10, right: 0,
                                      child: Transform.rotate(
                                        angle: 3.14159,
                                        child: Image.asset('assets/pita_bendera.png', height: 60, fit: BoxFit.contain),
                                      ),
                                    ),
                                ],
                              ),

                            // Berita Terbaru Section
                            const Text(
                              'Berita Terbaru',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF364057),
                                fontFamily: 'CircularStd',
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Featured News Cards (dynamic dari Supabase)
                            SizedBox(
                              height: 200,
                              child: _isLoadingNews
                                  ? const Center(child: CircularProgressIndicator())
                                  : _featuredNews.isEmpty
                                  ? const Center(child: Text('Belum ada berita terbaru'))
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
                                              image: (news['image_url'] != null && (news['image_url'] as String).isNotEmpty)
                                                  ? DecorationImage(
                                                      image: NetworkImage(news['image_url'] as String),
                                                      fit: BoxFit.cover,
                                                      colorFilter: const ColorFilter.mode(Color(0x66000000), BlendMode.darken),
                                                    )
                                                  : null,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    news['title'] ?? '',
                                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'CircularStd'),
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _formatDate(news['created_at']),
                                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontFamily: 'CircularStd'),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    news['source'] ?? '',
                                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontFamily: 'CircularStd'),
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

                            // Kegiatan Relawan Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Kegiatan Relawan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF364057),
                                    fontFamily: 'CircularStd',
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PostingKegiatanDonasiScreen(),
                                      ),
                                    );
                                    if (result == true) _loadMyEvents();
                                  },
                                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                  label: const Text(
                                    'Tambah',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontFamily: 'CircularStd',
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF364057),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _isLoadingEvents
                                ? const Center(child: CircularProgressIndicator())
                                : _myEvents.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F6FA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE0E4ED)),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.volunteer_activism_outlined, size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Belum ada kegiatan relawan',
                                          style: TextStyle(color: Colors.grey[500], fontFamily: 'CircularStd'),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tekan "Tambah" untuk memposting kegiatan',
                                          style: TextStyle(color: Colors.grey[400], fontSize: 12, fontFamily: 'CircularStd'),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _myEvents.length,
                                    itemBuilder: (context, i) {
                                      final ev = _myEvents[i];
                                      final imageUrl = ev['cover_image_url'] as String?;
                                      final status = ev['status'] as String? ?? '';
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFE0E4ED)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                                bottomLeft: Radius.circular(14),
                                              ),
                                              child: imageUrl != null && imageUrl.isNotEmpty
                                                  ? Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => _eventImagePlaceholder())
                                                  : _eventImagePlaceholder(),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ev['title'] ?? 'Tanpa Judul',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Color(0xFF364057),
                                                        fontFamily: 'CircularStd',
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          _formatDate(ev['start_time']),
                                                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'CircularStd'),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: status == 'open'
                                                            ? Colors.green.shade50
                                                            : status == 'closed'
                                                            ? Colors.red.shade50
                                                            : Colors.grey.shade100,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        status == 'open' ? 'Aktif' : status == 'closed' ? 'Selesai' : status,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: status == 'open'
                                                              ? Colors.green.shade700
                                                              : status == 'closed'
                                                              ? Colors.red.shade700
                                                              : Colors.grey.shade700,
                                                          fontFamily: 'CircularStd',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 20),

                            // Donasi Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Donasi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF364057),
                                    fontFamily: 'CircularStd',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _loadCampaigns(),
                                  child: Text(
                                    _isLoadingCampaigns
                                        ? 'Memuat...'
                                        : 'Lihat Semua',
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
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _campaigns.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Tidak ada kampanye aktif',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _campaigns.length,
                                      itemBuilder: (context, idx) {
                                        final c = _campaigns[idx];
                                        final rem = _remainingUntil(
                                          c['end_time'] as String?,
                                        );
                                        final days = rem['days'];
                                        final remText = rem['text'] as String;
                                        final highlight =
                                            days != null &&
                                            days >= 1 &&
                                            days <= 5;
                                        final canDonate = c['end_time'] != null
                                            ? (DateTime.tryParse(
                                                    c['end_time'],
                                                  )?.isAfter(DateTime.now()) ??
                                                  true)
                                            : true;

                                        return GestureDetector(
                                          onTap: () async {
                                            if (!canDonate) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Donasi ini sudah selesai',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                              return;
                                            }

                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BerikanDonasiScreen(
                                                      donation: c,
                                                    ),
                                              ),
                                            );

                                            if (result == true) {
                                              _loadCampaigns();
                                            }
                                          },
                                          child: Container(
                                            width: 300,
                                            height: 140,
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                              border: highlight
                                                  ? Border.all(
                                                      color: Colors.redAccent,
                                                      width: 2,
                                                    )
                                                  : null,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: 84,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                    image:
                                                        c['cover_image_url'] !=
                                                            null
                                                        ? DecorationImage(
                                                            image: NetworkImage(
                                                              c['cover_image_url'],
                                                            ),
                                                            fit: BoxFit.cover,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              c['title'] ??
                                                                  'Kegiatan',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Color(
                                                                  0xFF364057,
                                                                ),
                                                                fontFamily:
                                                                    'CircularStd',
                                                              ),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                              height: 6,
                                                            ),
                                                            Text(
                                                              remText,
                                                              style: TextStyle(
                                                                color: highlight
                                                                    ? Colors
                                                                          .redAccent
                                                                    : Colors
                                                                          .grey[700],
                                                                fontWeight:
                                                                    highlight
                                                                    ? FontWeight
                                                                          .bold
                                                                    : FontWeight
                                                                          .w500,
                                                                fontFamily:
                                                                    'CircularStd',
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () {
                                                          print(
                                                            "[Dashboard] Open campaign ${c['id']}",
                                                          );
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFF8FA3CC,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'Donasi',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
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

                            // Terpopuler Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Terpopuler',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF364057),
                                    fontFamily: 'CircularStd',
                                  ),
                                ),
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'CircularStd',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Popular News Grid
                            GridView.builder(
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
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.image,
                                              color: Colors.grey[600],
                                              size: 40,
                                            ),
                                          ),
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
                                                  news['title'],
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF364057),
                                                    fontFamily: 'CircularStd',
                                                  ),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                news['source'],
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.grey[600],
                                                  fontFamily: 'CircularStd',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
              ),
            ),

            // Bottom Navigation - Using BottomNavBar widget
            BottomNavBar(currentIndex: _selectedIndex, onTap: _onNavTap),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () async {
        if (index == 3) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                fromOrganization: true,
                organizationName: _userName,
                requestId: widget.requestId,
              ),
            ),
          );
          return;
        }
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8FA3CC) : Colors.transparent,
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
                  fontFamily: 'CircularStd',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
