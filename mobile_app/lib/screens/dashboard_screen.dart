import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/user_service.dart';
import '../utils/app_colors.dart';
import '../utils/business_rules.dart';
import '../widgets/dashboard_action_center.dart';
import '../widgets/dashboard_bottom_nav.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/firebase_error_view.dart';
import '../widgets/school_card.dart';
import '../widgets/school_search_bar.dart';
import '../widgets/stat_card.dart';
import 'district/attendance_list_screen.dart';
import 'district/exams_list_screen.dart';
import 'district/fees_list_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

enum DashboardSortOption {
  needsAttentionFirst,
  lowestAttendance,
  highestAttendance,
  highestPendingFees,
  name,
  studentCount,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final UserService _userService = UserService();
  UserModel? _userProfile;
  late Future<DistrictDashboardSummary> _dashboardFuture;
  late final Timer _refreshTimer;
  int _currentIndex = 0;

  // ── Search & Decision Filter state for Board tab ────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DashboardTriageFilter _triageFilter = DashboardTriageFilter.all;
  DashboardSortOption _sortOption = DashboardSortOption.needsAttentionFirst;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboardData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _reload();
    });
  }

  Future<DistrictDashboardSummary> _fetchDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not logged in. Please sign in to access the district dashboard.');
    }

    final profile = await _userService.getUserProfile(
      user.uid,
      defaultEmail: user.email,
      defaultName: user.displayName,
    );

    _userProfile = profile;

    final districtId = profile.districtId.trim();
    if (districtId.isEmpty) {
      throw Exception(
        'No District ID associated with your account. Please log in with a registered district administrator account.',
      );
    }

    return await _dashboardService.getDistrictSummary(districtId);
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      if (_userProfile != null && _userProfile!.districtId.trim().isNotEmpty) {
        _dashboardFuture = _dashboardService.getDistrictSummary(_userProfile!.districtId.trim());
      } else {
        _dashboardFuture = _fetchDashboardData();
      }
    });
  }

  Future<void> _handleLogout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  List<SchoolDashboardData> _getFilteredBoardSchools(List<SchoolDashboardData> schools) {
    final q = _searchQuery.trim().toLowerCase();

    // 1. Filter by Search Query & Triage Category
    final filtered = schools.where((s) {
      if (q.isNotEmpty) {
        final matchesName = s.school.name.toLowerCase().contains(q);
        final matchesId = s.school.schoolId.toLowerCase().contains(q);
        if (!matchesName && !matchesId) return false;
      }

      final isCriticalAtt = s.attendanceStatus == KPIStatus.critical;
      final isLaggingExam = s.examKPIStatus != KPIStatus.healthy;
      final isNeedsAttention = s.overallStatus != KPIStatus.healthy;

      switch (_triageFilter) {
        case DashboardTriageFilter.all:
          return true;
        case DashboardTriageFilter.needsAttention:
          return isNeedsAttention;
        case DashboardTriageFilter.criticalAttendance:
          return isCriticalAtt;
        case DashboardTriageFilter.laggingExams:
          return isLaggingExam;
        case DashboardTriageFilter.onTrack:
          return !isNeedsAttention;
      }
    }).toList();

    // 2. Sort by Decision Option
    filtered.sort((a, b) {
      switch (_sortOption) {
        case DashboardSortOption.needsAttentionFirst:
          final aSev = a.overallStatus.severity;
          final bSev = b.overallStatus.severity;
          if (aSev != bSev) return bSev.compareTo(aSev); // Highest severity (Critical=2, Warning=1) first
          return a.latestAttendancePercentage.compareTo(b.latestAttendancePercentage);
        case DashboardSortOption.lowestAttendance:
          return a.latestAttendancePercentage.compareTo(b.latestAttendancePercentage);
        case DashboardSortOption.highestAttendance:
          return b.latestAttendancePercentage.compareTo(a.latestAttendancePercentage);
        case DashboardSortOption.highestPendingFees:
          return b.feesPending.compareTo(a.feesPending);
        case DashboardSortOption.name:
          return a.school.name.compareTo(b.school.name);
        case DashboardSortOption.studentCount:
          return b.school.studentCount.compareTo(a.school.studentCount);
      }
    });

    return filtered;
  }

  String _getSortLabel(DashboardSortOption opt) {
    switch (opt) {
      case DashboardSortOption.needsAttentionFirst:
        return 'Priority Risk';
      case DashboardSortOption.lowestAttendance:
        return 'Lowest Attendance';
      case DashboardSortOption.highestAttendance:
        return 'Highest Attendance';
      case DashboardSortOption.highestPendingFees:
        return 'Highest Pending Fees';
      case DashboardSortOption.name:
        return 'Name (A-Z)';
      case DashboardSortOption.studentCount:
        return 'Student Count';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Priya');

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FutureBuilder<DistrictDashboardSummary>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return FirebaseErrorView(
                  title: 'Unable to Load Dashboard Data',
                  message: snapshot.error.toString().replaceAll('Exception: ', ''),
                  onRetry: _reload,
                  onLogout: _handleLogout,
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.card),
                );
              }

              final summary = snapshot.data!;

              return Stack(
                children: [
                  // ── Active Tab Page via IndexedStack to retain scroll states ──
                  IndexedStack(
                    index: _currentIndex,
                    children: [
                      // Tab 0: Board Overview
                      _buildBoardTab(summary, userName),

                      // Tab 1: Attendance List Screen
                      AttendanceListScreen(
                        summary: summary,
                        onRefresh: () async {
                          _reload();
                          await _dashboardFuture;
                        },
                      ),

                      // Tab 2: Fees List Screen
                      FeesListScreen(
                        summary: summary,
                        onRefresh: () async {
                          _reload();
                          await _dashboardFuture;
                        },
                      ),

                      // Tab 3: Exams List Screen
                      ExamsListScreen(
                        summary: summary,
                        onRefresh: () async {
                          _reload();
                          await _dashboardFuture;
                        },
                      ),

                      // Tab 4: Account Profile Screen
                      ProfileScreen(
                        userProfile: _userProfile,
                        onLogout: _handleLogout,
                        onBack: () => setState(() => _currentIndex = 0),
                      ),
                    ],
                  ),

                  // Floating Pill Bottom Navigation Bar Overlay
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DashboardBottomNav(
                      currentIndex: _currentIndex,
                      onTap: (index) => setState(() => _currentIndex = index),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoardTab(DistrictDashboardSummary summary, String userName) {
    final schools = summary.schoolsData;
    final filteredSchools = _getFilteredBoardSchools(schools);

    final criticalAttendanceCount = schools.where((s) => s.attendanceStatus == KPIStatus.critical).length;
    final laggingExamsCount = schools.where((s) => s.examKPIStatus != KPIStatus.healthy).length;
    final needsAttentionCount = schools.where((s) => s.overallStatus != KPIStatus.healthy).length;

    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _dashboardFuture;
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: userName,
              districtId: _userProfile?.districtId,
              onLogout: _handleLogout,
              onProfileTap: () => setState(() => _currentIndex = 4),
            ),

            const SizedBox(height: 20),

            // ── Executive Decision & Action Center (Alert Hub) ────────
            DashboardActionCenter(
              schools: schools,
              onFilterSelected: (f) => setState(() => _triageFilter = f),
            ),

            const SizedBox(height: 20),

            // ── Stat Summary Cards (Interactive navigation) ─────────
            Row(
              children: [
                StatCard(
                  value: '${summary.averageAttendanceToday.toStringAsFixed(0)}%',
                  label: 'Attendance today',
                  percentage: summary.averageAttendanceToday / 100.0,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                StatCard(
                  value: _formatCurrency(summary.totalFeesCollected),
                  label: 'Fees collected',
                  percentage: (summary.totalFeesCollected + summary.totalFeesPending) > 0
                      ? summary.totalFeesCollected /
                          (summary.totalFeesCollected + summary.totalFeesPending)
                      : 0.0,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                StatCard(
                  value: summary.examProgressStatus == 'Lagging' ? 'Lagging' : 'On track',
                  label: 'Exams this week',
                  isArrow: true,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── School Search Bar ───────────────────────────
            SchoolSearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: (q) => setState(() => _searchQuery = q.trim()),
            ),

            const SizedBox(height: 16),

            // ── Decision-Making Triage Filter Chips ─────────
            FilterChipRow<DashboardTriageFilter>(
              items: [
                FilterChipItem(
                  value: DashboardTriageFilter.all,
                  label: 'All Schools',
                  count: schools.length,
                ),
                FilterChipItem(
                  value: DashboardTriageFilter.needsAttention,
                  label: '⚠️ Action Needed',
                  count: needsAttentionCount,
                ),
                FilterChipItem(
                  value: DashboardTriageFilter.criticalAttendance,
                  label: '🚨 Critical Att (<75%)',
                  count: criticalAttendanceCount,
                ),
                FilterChipItem(
                  value: DashboardTriageFilter.laggingExams,
                  label: '⏳ Due Exams',
                  count: laggingExamsCount,
                ),
                FilterChipItem(
                  value: DashboardTriageFilter.onTrack,
                  label: '✅ Healthy',
                  count: schools.length - needsAttentionCount,
                ),
              ],
              selectedValue: _triageFilter,
              onSelected: (val) => setState(() => _triageFilter = val),
            ),

            const SizedBox(height: 16),

            // ── Sort & Results Count Bar ────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredSchools.length} OF ${schools.length} SCHOOLS',
                  style: const TextStyle(
                    color: Color(0xFFC7BDB3),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                PopupMenuButton<DashboardSortOption>(
                  initialValue: _sortOption,
                  onSelected: (val) => setState(() => _sortOption = val),
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x22000000),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, color: AppColors.card, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _getSortLabel(_sortOption),
                          style: const TextStyle(
                            color: AppColors.card,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.card, size: 18),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: DashboardSortOption.needsAttentionFirst,
                      child: Text('Priority Risk (Attention First)'),
                    ),
                    PopupMenuItem(
                      value: DashboardSortOption.lowestAttendance,
                      child: Text('Lowest Attendance First'),
                    ),
                    PopupMenuItem(
                      value: DashboardSortOption.highestAttendance,
                      child: Text('Highest Attendance First'),
                    ),
                    PopupMenuItem(
                      value: DashboardSortOption.highestPendingFees,
                      child: Text('Highest Pending Fees First'),
                    ),
                    PopupMenuItem(
                      value: DashboardSortOption.name,
                      child: Text('School Name (A-Z)'),
                    ),
                    PopupMenuItem(
                      value: DashboardSortOption.studentCount,
                      child: Text('Student Count (High-Low)'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Grid or empty states ────────────────────────
            if (schools.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No schools found for this district.',
                    style: TextStyle(color: AppColors.card),
                  ),
                ),
              )
            else if (filteredSchools.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        color: Color(0xFFC7BDB3),
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No schools match "$_searchQuery".'
                            : 'No schools match the selected triage filter.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFC7BDB3),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _triageFilter = DashboardTriageFilter.all;
                            _sortOption = DashboardSortOption.needsAttentionFirst;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.card, size: 16),
                        label: const Text(
                          'Reset Filters',
                          style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0x66FFFFFF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSchools.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, idx) => SchoolCard(
                  schoolData: filteredSchools[idx],
                  index: idx,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }
}
