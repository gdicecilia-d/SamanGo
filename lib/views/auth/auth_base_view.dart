// Base para todas las pantallas de autenticación usando Template Method
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_view.dart';

class AuthBaseView extends StatelessWidget {
  final Widget formContent;
  final String? bottomText;
  final String? bottomLinkText;
  final VoidCallback? onBottomLinkTap;
  final VoidCallback? onBackPressed;

  const AuthBaseView({
    super.key,
    required this.formContent,
    this.bottomText,
    this.bottomLinkText,
    this.onBottomLinkTap,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    if (isMobile) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFC6707), size: 24),
          onPressed: () {
            if (onBackPressed != null) {
              onBackPressed!();
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeView()),
                (route) => false,
              );
            }
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowIndicator();
            return true;
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildFormCard(context, isMobile: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Escala base: tu medida original para un ancho de referencia de 1200px
    final double scaleFactor = (screenWidth / 1200).clamp(0.9, 1.4);
    
    // Tus medidas escaladas
    final double formWidth = 500 * scaleFactor; // Un pelín más ancho
    final double circleSize = 650 * scaleFactor; // Círculo gigante de vuelta
    final double leftOffset = -150 * scaleFactor; // Ajuste para el círculo gigante
    final double logoScale = 2.0;
    final double logoWidth = 65;
    final double nombreHeight = 35;
    final double topPadding = 20;
    final int leftFlex = 6;
    final int rightFlex = 4;
    final double leftPadding = 30 * scaleFactor;
    final double rightPadding = 50 * scaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: leftFlex,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(left: leftPadding, right: rightPadding, top: 40, bottom: 40),
                  child: Center(
                    child: SizedBox(
                      width: formWidth,
                      child: _buildFormCard(context, isMobile: false),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: rightFlex,
                child: _buildRightSection(circleSize: circleSize, leftOffset: leftOffset),
              ),
            ],
          ),
          Positioned(
            top: 20,
            left: 20,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeView()),
                      (route) => false,
                    );
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFC6707),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Volver',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFFFC6707),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, {required bool isMobile}) {
    final double logoScaleValue = isMobile ? 1.5 : 2.0;
    final double logoWidthValue = isMobile ? 60 : 65;
    final double nombreHeightValue = isMobile ? 30 : 35;
    final double topPaddingValue = isMobile ? 12 : 20;
    final double spacing = isMobile ? 20 : 28;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 32,
        vertical: isMobile ? 32 : 56, // Padding vertical mucho mayor para que sea más largo
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeView()),
                  (route) => false,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: isMobile
                    ? [
                        Transform.scale(
                          scale: logoScaleValue,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 60,
                            height: 60,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Image.asset(
                            'assets/images/Nombre.png',
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ]
                    : [
                        Transform.scale(
                          scale: logoScaleValue,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: logoWidthValue,
                            height: logoWidthValue,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Padding(
                          padding: EdgeInsets.only(top: topPaddingValue),
                          child: Image.asset(
                            'assets/images/Nombre.png',
                            height: nombreHeightValue,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
              ),
            ),
          ),
          SizedBox(height: spacing),

          formContent,

          if (bottomText != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bottomText!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                ),
                if (bottomLinkText != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onBottomLinkTap,
                      child: Text(
                        bottomLinkText!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFFFC6707),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightSection({required double circleSize, required double leftOffset}) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFC6707),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: leftOffset,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/campus.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              'Copyright © 2026 - SamanGo',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}