import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:indigi_attendance/controllers/auth_controller.dart';
import 'package:indigi_attendance/controllers/client_visit_controller.dart';
import 'package:indigi_attendance/theme/app_theme.dart';
import 'package:indigi_attendance/views/client_visit_history_screen.dart';
import 'package:indigi_attendance/views/leave/leave_approval_list_screen.dart';
import 'package:indigi_attendance/widgets/app_shell.dart';

// ─── More Tab ─────────────────────────────────────────────────────────────────

class MoreTab extends StatefulWidget {
  const MoreTab({super.key});

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> with TickerProviderStateMixin {
  late final List<AnimationController> _cardControllers;
  late final AnimationController _headerController;

  static const _maxCards = 2;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _cardControllers = List.generate(
      _maxCards,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    // Stagger card entrances
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 80), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final user = auth.currentUser;
    final clientVisit = Provider.of<ClientVisitController>(context);

    final isManager = user != null && user.canApproveLeave;
    final pendingApprovals = user?.pendingLeaveCount ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _headerController,
                  curve: Curves.easeOut,
                ),
                child: Container(
                  color: AppColors.background,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MODULES', style: AppText.sectionHeader),
                          const SizedBox(height: 2),
                          const Text(
                            'More',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Module Cards Grid (Square 1:1 Aspect Ratio) ─────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildListDelegate([
                  // Card 1: Client Visits
                  _AnimatedCard(
                    controller: _cardControllers[0],
                    child: _SquareModuleCard(
                      icon: Icons.business_center_outlined,
                      iconColor: AppColors.emerald,
                      title: 'Client Visits',
                      subtitle: 'Track check-ins & scheduled visits',
                      badge: clientVisit.ongoingVisit != null ? 'Active' : null,
                      badgeColor: AppColors.emerald,
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).push(
                        AppPageRoute(page: const ClientVisitHistoryScreen()),
                      ),
                    ),
                  ),

                  // Card 2: Leave Approvals (ONLY visible for managers)
                  if (isManager)
                    _AnimatedCard(
                      controller: _cardControllers[1],
                      child: _SquareModuleCard(
                        icon: Icons.fact_check_outlined,
                        iconColor: AppColors.coral,
                        title: 'Leave Approvals',
                        subtitle: 'Review & approve team leaves',
                        badge: pendingApprovals > 0
                            ? '$pendingApprovals Pending'
                            : null,
                        badgeColor: AppColors.amber,
                        onTap: () =>
                            Navigator.of(context, rootNavigator: true).push(
                          AppPageRoute(page: const LeaveApprovalListScreen()),
                        ),
                      ),
                    ),
                ]),
              ),
            ),

            // ── Bottom padding for nav bar ──────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

// ─── Animated Card Wrapper ────────────────────────────────────────────────────

class _AnimatedCard extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _AnimatedCard({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}

// ─── Square Module Card (1:1 Aspect Ratio) ────────────────────────────────────

class _SquareModuleCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const _SquareModuleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.onTap,
  });

  @override
  State<_SquareModuleCard> createState() => _SquareModuleCardState();
}

class _SquareModuleCardState extends State<_SquareModuleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon + Badge / Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 22,
                    ),
                  ),
                  if (widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: (widget.badgeColor ?? widget.iconColor)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        widget.badge!,
                        style: TextStyle(
                          color: widget.badgeColor ?? widget.iconColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 2),
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                    ),
                ],
              ),

              // Bottom Section: Title + Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
