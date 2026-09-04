import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? userProfile;
  final VoidCallback? onLogout;
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    this.userProfile,
    this.onLogout,
    this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  UserModel? _profile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.userProfile;
    if (_profile == null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final p = await _userService.getUserProfile(
        user.uid,
        defaultEmail: user.email,
        defaultName: user.displayName,
      );
      if (mounted) {
        setState(() {
          _profile = p;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmAndLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.pink, size: 24),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your SchoolSync district administrator account?',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (widget.onLogout != null) {
        widget.onLogout!();
      } else {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppColors.text,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = _profile?.name.isNotEmpty == true
        ? _profile!.name
        : (user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : (user?.email?.split('@').first ?? 'Administrator'));
    final email = _profile?.email.isNotEmpty == true
        ? _profile!.email
        : (user?.email ?? 'No email');
    final districtId = _profile?.districtId.isNotEmpty == true
        ? _profile!.districtId
        : 'DIST001';
    final role = _profile?.role.isNotEmpty == true
        ? _profile!.role
        : 'district_admin';

    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : (name.isNotEmpty ? name.toUpperCase() : 'AD');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.card),
          tooltip: 'Back',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Account Profile',
          style: TextStyle(
            color: AppColors.card,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.card),
            tooltip: 'Sign Out',
            onPressed: _confirmAndLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.card),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Profile Header Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2A000000),
                          offset: Offset(0, 6),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with ring
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.yellow,
                            border: Border.all(color: AppColors.text, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                offset: Offset(0, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Badges Row: Role and Live Sync
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFE8DA),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFDDD3C1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.text),
                                  const SizedBox(width: 5),
                                  Text(
                                    role == 'district_admin'
                                        ? 'District Administrator'
                                        : 'School Staff',
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA5D6A7)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF43A047),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Active Live Sync',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── District Information Card ─────────────────────────────
                  _buildSectionHeader('DISTRICT ASSIGNMENT'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.location_city_rounded,
                          title: 'District ID',
                          value: districtId,
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.secondaryText),
                            tooltip: 'Copy District ID',
                            onPressed: () => _copyToClipboard(districtId, 'District ID'),
                          ),
                        ),
                        const Divider(height: 16, color: Color(0xFFE8E2D4)),
                        _buildInfoTile(
                          icon: Icons.shield_outlined,
                          title: 'Access Level',
                          value: 'District-Wide Administration & Supervision',
                        ),
                        const Divider(height: 16, color: Color(0xFFE8E2D4)),
                        _buildInfoTile(
                          icon: Icons.sync_rounded,
                          title: 'Sync Interval',
                          value: 'Every 30 seconds (Automatic live sync)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Account Details Card ──────────────────────────────────
                  _buildSectionHeader('ACCOUNT CREDENTIALS'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Full Name',
                          value: name,
                        ),
                        const Divider(height: 16, color: Color(0xFFE8E2D4)),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          title: 'Official Email',
                          value: email,
                        ),
                        if (user?.uid != null) ...[
                          const Divider(height: 16, color: Color(0xFFE8E2D4)),
                          _buildInfoTile(
                            icon: Icons.fingerprint_rounded,
                            title: 'Account UID',
                            value: user!.uid,
                            trailing: IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.secondaryText),
                              tooltip: 'Copy UID',
                              onPressed: () => _copyToClipboard(user.uid, 'User UID'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── App Settings / Preferences ────────────────────────────
                  _buildSectionHeader('PREFERENCES'),
                  const SizedBox(height: 8),
                  Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 2,
                    shadowColor: const Color(0x1F000000),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.info_outline_rounded, color: AppColors.secondaryText),
                        title: Text(
                          'Application Version',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          'v1.0.0 (Build 2026)',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Logout Button ─────────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: _confirmAndLogout,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Log Out of Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC75D6A),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Center(
                    child: Text(
                      'SchoolSync · Educational Operations Platform',
                      style: TextStyle(
                        color: Color(0xFFC7BDB3),
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFC7BDB3),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE8DA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.text),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
