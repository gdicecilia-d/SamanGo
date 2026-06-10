// Base para todas las pantallas de autenticación usando Template Method
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_view.dart';
import '../../utils/responsive.dart';

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
    final isMobile = screenWidth < Responsive.designWidth * 0.6;

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
            padding: EdgeInsets.all(Responsive.padding(context, 24)),
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
    final double scale = (screenWidth / Responsive.designWidth).clamp(0.55, 1.25);
    
    // Ancho del formulario 
    final double formWidth = 520 * scale;
    // Tamaño del círculo 
    final double circleSize = 580 * scale;
    // Posición izquierda 
    final double leftOffset = -85 * scale;
    // Padding laterales 
    final double leftPadding = 40 * scale;
    final double rightPadding = 60 * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: leftPadding,
                    right: rightPadding,
                    top: Responsive.padding(context, 40),
                    bottom: Responsive.padding(context, 40),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: formWidth,
                      child: _buildFormCard(context, isMobile: false, scale: scale),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: _buildRightSection(context, circleSize: circleSize, leftOffset: leftOffset),
              ),
            ],
          ),
          Positioned(
            top: 20 * scale,
            left: 20 * scale,
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
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 8 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8 * scale,
                        offset: Offset(0, 2 * scale),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: const Color(0xFFFC6707),
                        size: 18 * scale,
                      ),
                      SizedBox(width: 4 * scale),
                      Text(
                        'Volver',
                        style: GoogleFonts.outfit(
                          fontSize: 14 * scale,
                          color: const Color(0xFFFC6707),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, {required bool isMobile, double scale = 1.0}) {
    final double logoWidth = isMobile ? Responsive.width(context, 70) : 75 * scale;
    final double nombreHeight = isMobile ? Responsive.height(context, 35) : 40 * scale;
    final double topPadding = isMobile ? Responsive.padding(context, 12) : 20 * scale;
    final double spacing = isMobile ? Responsive.padding(context, 24) : 32 * scale;
    final double innerPadding = isMobile ? Responsive.padding(context, 28) : 40 * scale;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28 * scale),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      padding: EdgeInsets.all(innerPadding),
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
                          scale: 1.5,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: logoWidth,
                            height: logoWidth,
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        Padding(
                          padding: EdgeInsets.only(top: topPadding),
                          child: Image.asset(
                            'assets/images/Nombre.png',
                            height: nombreHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ]
                    : [
                        Transform.scale(
                          scale: 2.2,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: logoWidth,
                            height: logoWidth,
                          ),
                        ),
                        SizedBox(width: 15 * scale),
                        Padding(
                          padding: EdgeInsets.only(top: topPadding),
                          child: Image.asset(
                            'assets/images/Nombre.png',
                            height: nombreHeight,
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
            SizedBox(height: 28 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bottomText!,
                  style: GoogleFonts.outfit(
                    fontSize: 14 * scale,
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
                          fontSize: 14 * scale,
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

  Widget _buildRightSection(BuildContext context, {required double circleSize, required double leftOffset}) {
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
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
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