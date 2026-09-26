import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _empCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      if (auth.errorMessage.isNotEmpty) {
        auth.logout();
      }
    });
  }

  @override
  void dispose() {
    _empCodeController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final size = MediaQuery.of(context).size;

    return UpgradeAlert(
      upgrader: Upgrader(durationUntilAlertAgain: Duration.zero),
      showIgnore: false,
      showLater: false,
      shouldPopScope: () => false,
      child: Scaffold(
        backgroundColor: AppColors.charcoal,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Stack(
            children: [
              // ── Background Gradient ─────────────────────────────────────
              Container(
                decoration: const BoxDecoration(gradient: AppGradients.hero),
              ),

              // ── Decorative Circles ───────────────────────────────────────
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.coral.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: size.height * 0.38,
                left: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.coral.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Logo & branding section
                    SizedBox(
                      height: size.height * 0.38,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: 92,
                              height: 92,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.coral.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.business_center_rounded,
                                  size: 40,
                                  color: AppColors.coral,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Indigi HRM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Human Resource Management',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Login Card ──────────────────────────────────────────
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                32,
                                28,
                                32,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Enter your credentials to continue',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Employee Code
                                    _FieldLabel(label: 'Employee Code'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _empCodeController,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. EMP001',
                                        prefixIcon: const Icon(
                                          Icons.badge_outlined,
                                          color: AppColors.textHint,
                                          size: 20,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.surfaceSecondary,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFEEEFF4),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.coral,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.error,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Please enter your employee code'
                                          : null,
                                    ),

                                    const SizedBox(height: 20),

                                    // Password
                                    _FieldLabel(label: 'Password'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Your password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: AppColors.textHint,
                                          size: 20,
                                        ),
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.textHint,
                                            size: 20,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.surfaceSecondary,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFEEEFF4),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.coral,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.error,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      onFieldSubmitted: (_) => _submit(auth),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Please enter your password'
                                          : null,
                                    ),

                                    // Error message
                                    if (auth.errorMessage.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          border: Border.all(
                                            color: AppColors.error.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: AppColors.error,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                auth.errorMessage,
                                                style: const TextStyle(
                                                  color: AppColors.error,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 32),

                                    // Login Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: auth.isLoading
                                              ? null
                                              : AppGradients.coral,
                                          color: auth.isLoading
                                              ? AppColors.surfaceSecondary
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          boxShadow: auth.isLoading
                                              ? null
                                              : AppShadows.coral,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: auth.isLoading
                                              ? null
                                              : () => _submit(auth),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.md,
                                                  ),
                                            ),
                                          ),
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color: AppColors.coral,
                                                      ),
                                                )
                                              : const Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Footer
                                    Center(
                                      child: Text(
                                        '© Indigi Consulting & Solutions Pvt. Ltd.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint.withValues(
                                            alpha: 0.7,
                                          ),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }

  Future<void> _submit(AuthController auth) async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      await auth.login(
        _empCodeController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }
}
