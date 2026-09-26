import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

/// Modern iOS-style floating pill navbar with elevated liquid glass morphing lens.
class AppShell extends StatefulWidget {
  final List<AppShellDestination> destinations;
  final int initialIndex;

  const AppShell({
    super.key,
    required this.destinations,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  late int _selectedIndex;
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _navigatorKeys = List.generate(
      widget.destinations.length,
      (_) => GlobalKey<NavigatorState>(),
    );
  }

  void _onTap(int index) {
    if (index == _selectedIndex) {
      // Pop to root of nested navigator on double-tap
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // Pages (keep alive using Offstage)
          ...List.generate(widget.destinations.length, (i) {
            return Offstage(
              offstage: i != _selectedIndex,
              child: _NestedNavigator(
                navigatorKey: _navigatorKeys[i],
                child: widget.destinations[i].page,
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: _FloatingNavBar(
        destinations: widget.destinations,
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }
}

/// Wraps each tab page in its own Navigator so each tab maintains its own
/// navigation stack independently.
class _NestedNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _NestedNavigator({required this.navigatorKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child),
    );
  }
}

// ─── Destination Model ───────────────────────────────────────────────────────
class AppShellDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;
  final Color? activeColor;

  const AppShellDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
    this.activeColor,
  });
}

// ─── Liquid Glass Floating Pill Nav Bar ─────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final List<AppShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomInset > 0 ? bottomInset + 6.0 : 16.0;

    const barHeight = 64.0;
    const barPadding = 5.0;
    const lensHeight = barHeight - (barPadding * 2); // 54.0

    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, bottomMargin),
      child: SizedBox(
        height: barHeight,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0E12),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final slotWidth = barWidth / destinations.length;
              final lensWidth = (slotWidth - 6.0).clamp(52.0, 72.0);
              final lensLeft = (selectedIndex * slotWidth) +
                  ((slotWidth - lensWidth) / 2);

              final activeDestination = destinations[selectedIndex];
              final isProfileActive = selectedIndex == 4 ||
                  activeDestination.label.toLowerCase() == 'profile';

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // 1. Inactive items layer
                  Positioned.fill(
                    child: Row(
                      children: List.generate(destinations.length, (i) {
                        final isSelected = i == selectedIndex;
                        final isProfile = i == 4 ||
                            destinations[i].label.toLowerCase() == 'profile';

                        return Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 0.0 : 1.0,
                            child: Center(
                              child: isProfile
                                  ? const _NavBarAvatar(isSelected: false, size: 24)
                                  : Icon(
                                      destinations[i].icon,
                                      color: const Color(0xFF8E929B),
                                      size: 22,
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // 2. Focused Liquid Glass Morphing Lens (contained inside navbar boundaries)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    top: barPadding,
                    left: lensLeft,
                    width: lensWidth,
                    height: lensHeight,
                    child: _LiquidGlassLens(
                      destination: activeDestination,
                      isProfile: isProfileActive,
                    ),
                  ),

                  // 3. Touch targets
                  Positioned.fill(
                    child: Row(
                      children: List.generate(destinations.length, (i) {
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(i),
                            child: const SizedBox.expand(),
                          ),
                        );
                      }),
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
}

// ─── Contained Liquid Glass Morphing Lens ───────────────────────────────────
class _LiquidGlassLens extends StatelessWidget {
  final AppShellDestination destination;
  final bool isProfile;

  const _LiquidGlassLens({
    required this.destination,
    required this.isProfile,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = destination.activeColor ?? AppColors.coral;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF020232C), // Smoky elevated glass layer
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: activeColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Top specular highlight gradient arc
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.40),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Top specular crisp highlight line (opalescent rim)
            Positioned(
              top: 0,
              left: 14,
              right: 14,
              height: 1.2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.70),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom subtle caustic reflection highlight
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 14,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // Active tab content: icon + label
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: isProfile
                        ? const _NavBarAvatar(
                            key: ValueKey('avatar_active'),
                            isSelected: true,
                            size: 22,
                          )
                        : Icon(
                            destination.activeIcon,
                            key: ValueKey(destination.label),
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      destination.label,
                      key: ValueKey(destination.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.15,
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
  }
}

// ─── Circular Avatar Icon for Profile Slot ──────────────────────────────────
class _NavBarAvatar extends StatelessWidget {
  final bool isSelected;
  final double size;

  const _NavBarAvatar({
    super.key,
    required this.isSelected,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthController>(context, listen: false).currentUser;
    final picUrl = user?.empAttachmentUrl;
    final hasValidPic = picUrl != null &&
        picUrl.isNotEmpty &&
        picUrl != 'NA' &&
        picUrl.startsWith('http');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.35),
          width: isSelected ? 1.8 : 1.2,
        ),
      ),
      child: ClipOval(
        child: hasValidPic
            ? CachedNetworkImage(
                imageUrl: picUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _initials(user?.name ?? ''),
                errorWidget: (_, __, ___) => _initials(user?.name ?? ''),
              )
            : _initials(user?.name ?? ''),
      ),
    );
  }

  Widget _initials(String name) {
    final trimmed = name.trim();
    final letter = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'U';
    return Container(
      color: const Color(0xFF2C2F38),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Page Transition ─────────────────────────────────────────────────────────
/// Smooth fade+slide transition for use in push navigations within tabs.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, _) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: Offset.zero,
            ).animate(curvedAnimation);

            final secondaryCurve = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInCubic,
            );
            final secondarySlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0),
            ).animate(secondaryCurve);

            return SlideTransition(
              position: secondarySlide,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Fade-only transition (good for modal-like pushes).
class AppFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, _) => page,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
}
