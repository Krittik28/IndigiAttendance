
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:indigi_attendance/controllers/attendance_controller.dart';
import 'package:indigi_attendance/controllers/auth_controller.dart';
import 'package:indigi_attendance/theme/app_theme.dart';
import 'package:indigi_attendance/views/holiday_screen.dart';
import 'package:indigi_attendance/views/leave/leave_approval_list_screen.dart';
import 'package:indigi_attendance/views/leave/leave_dashboard_screen.dart';
import 'package:indigi_attendance/widgets/app_shell.dart';

// ─── Profile Tab ─────────────────────────────────────────────────────────────

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _pickAndUploadImage(AuthController auth) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    final success = await auth.updateProfileImage(picked.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile photo updated!'
                : auth.errorMessage.isNotEmpty
                    ? auth.errorMessage
                    : 'Failed to update photo.',
          ),
        ),
      );
    }
  }

  // ── dialogs ────────────────────────────────────────────────────────────────

  Future<void> _showChangePasswordDialog(AuthController auth) async {
    final formKey = GlobalKey<FormState>();
    final pwController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    bool confirmObscure = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.elevated,
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon badge
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppGradients.coral,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: AppShadows.coral,
                        ),
                        child: const Icon(Icons.lock_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Change Password', style: AppText.headingLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Enter a strong new password.',
                          style: AppText.bodySmall),
                      const SizedBox(height: AppSpacing.lg),

                      // New password
                      TextFormField(
                        controller: pwController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setDialogState(() => obscure = !obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) {
                            return 'Min 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Confirm password
                      TextFormField(
                        controller: confirmController,
                        obscureText: confirmObscure,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              confirmObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(
                                () => confirmObscure = !confirmObscure),
                          ),
                        ),
                        validator: (v) {
                          if (v != pwController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                Navigator.pop(ctx);
                                final ok = await auth
                                    .changePassword(pwController.text.trim());
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Password changed successfully!'
                                            : auth.errorMessage.isNotEmpty
                                                ? auth.errorMessage
                                                : 'Failed to change password.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Update'),
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
        );
      },
    );
  }

  Future<void> _showLogoutDialog(AuthController auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.elevated,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 26),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Sign Out?', style: AppText.headingLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You will be returned to the login screen.',
                style: AppText.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await auth.logout();
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final attendance = Provider.of<AttendanceController>(context);
    final user = auth.currentUser;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero header ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroSection(
                  user: user,
                  initials:
                      user != null ? _initials(user.name) : '?',
                  onCameraPressed: () => _pickAndUploadImage(auth),
                  isUploading: auth.isLoading,
                  todayStatus: attendance.todayStatus,
                ),
              ),

              // ── Spacing ───────────────────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // ── Account group ─────────────────────────────────────────────
              _SliverSection(
                title: 'Account',
                items: [
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.purpleAccent,
                    label: 'Change Password',
                    onTap: () => _showChangePasswordDialog(auth),
                  ),
                  _MenuItem(
                    icon: Icons.photo_camera_outlined,
                    iconColor: AppColors.tealAccent,
                    label: 'Update Profile Photo',
                    onTap: () => _pickAndUploadImage(auth),
                    showDivider: false,
                  ),
                ],
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ── Leave group ───────────────────────────────────────────────
              _SliverSection(
                title: 'Leave',
                items: [
                  _MenuItem(
                    icon: Icons.beach_access_outlined,
                    iconColor: AppColors.emerald,
                    label: 'Leave Management',
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).push(
                      AppPageRoute(page: const LeaveDashboardScreen()),
                    ),
                    showDivider: user != null && user.canApproveLeave,
                  ),
                  if (user != null && user.canApproveLeave)
                    _MenuItem(
                      icon: Icons.approval_outlined,
                      iconColor: AppColors.amberAccent,
                      label: 'Leave Approvals',
                      badge: user.pendingLeaveCount > 0
                          ? '${user.pendingLeaveCount}'
                          : null,
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).push(
                        AppPageRoute(page: const LeaveApprovalListScreen()),
                      ),
                      showDivider: false,
                    ),
                ],
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ── Other group ───────────────────────────────────────────────
              _SliverSection(
                title: 'Other',
                items: [
                  _MenuItem(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.success,
                    label: 'Holiday List',
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).push(
                      AppPageRoute(page: const HolidayScreen()),
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ── Danger zone ───────────────────────────────────────────────
              _SliverSection(
                title: 'Danger Zone',
                items: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    label: 'Sign Out',
                    labelColor: AppColors.error,
                    onTap: () => _showLogoutDialog(auth),
                    showDivider: false,
                    showChevron: false,
                  ),
                ],
              ),

              // ── Bottom padding for nav bar ─────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final dynamic user; // User? from auth
  final String initials;
  final VoidCallback onCameraPressed;
  final bool isUploading;
  final Map<String, dynamic>? todayStatus;

  const _HeroSection({
    required this.user,
    required this.initials,
    required this.onCameraPressed,
    required this.isUploading,
    required this.todayStatus,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPad + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: AppShadows.card,
                ),
                child: ClipOval(
                  child: _buildAvatar(),
                ),
              ),
              // Camera badge
              GestureDetector(
                onTap: isUploading ? null : onCameraPressed,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Name ────────────────────────────────────────────────────────
          Text(
            user?.name ?? '—',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // ── ID Badge ────────────────────────────────────────────────────
          if (user != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
                boxShadow: AppShadows.card,
              ),
              child: Text(
                'EMP • ${user.employeeCode}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

          // ── Email ────────────────────────────────────────────────────────
          if ((user?.email ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ── Stats Row ────────────────────────────────────────────────────
          if (todayStatus != null) _StatsRow(todayStatus: todayStatus ?? const {}),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = user?.empAttachmentUrl;
    if (url != null && url.toString().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url.toString(),
        fit: BoxFit.cover,
        placeholder: (_, __) => _initialsWidget(),
        errorWidget: (_, __, ___) => _initialsWidget(),
      );
    }
    return _initialsWidget();
  }

  Widget _initialsWidget() {
    return Container(
      color: AppColors.surfaceSecondary,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> todayStatus;

  const _StatsRow({required this.todayStatus});

  @override
  Widget build(BuildContext context) {
    final checkinCount = (todayStatus['checkinCount'] as int?) ?? 0;
    final checkoutCount = (todayStatus['checkoutCount'] as int?) ?? 0;
    final hasCheckedIn = checkinCount > 0;
    final isPresent = hasCheckedIn && checkoutCount < checkinCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            label: 'STATUS',
            value: isPresent
                ? 'Present'
                : hasCheckedIn
                    ? 'Checked Out'
                    : 'Not In',
            color: isPresent
                ? AppColors.emerald
                : hasCheckedIn
                    ? AppColors.amber
                    : AppColors.textHint,
          ),
          Container(height: 28, width: 0.5, color: AppColors.cardBorder),
          _StatChip(
            label: 'CHECK-INS',
            value: '$checkinCount',
            color: AppColors.emerald,
          ),
          Container(height: 28, width: 0.5, color: AppColors.cardBorder),
          _StatChip(
            label: 'CHECK-OUTS',
            value: '$checkoutCount',
            color: AppColors.amber,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ─── Section (sliver wrapper) ─────────────────────────────────────────────────

class _SliverSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _SliverSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.xs, bottom: AppSpacing.xs),
              child: Text(
                title.toUpperCase(),
                style: AppText.label,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: items,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String? badge;
  final bool showDivider;
  final bool showChevron;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.badge,
    this.showDivider = true,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            color: _pressed
                ? AppColors.surfaceSecondary
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),

                // Label
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppText.body.copyWith(
                      color: widget.labelColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Badge
                if (widget.badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      widget.badge ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],

                // Chevron
                if (widget.showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (widget.showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: AppSpacing.md + 36 + AppSpacing.md,
            color: const Color(0xFFEEEFF4),
          ),
      ],
    );
  }
}
