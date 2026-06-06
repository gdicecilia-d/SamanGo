// Header universal para toda la app (Estudiante, Operador, Admin)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'widgets/custom_dialog.dart';

class AppHeader extends StatefulWidget {
  final String activeMenu;
  final Function(String) onMenuSelected;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final List<String> menuItems;
  final bool isMobile;
  final VoidCallback? onMenuTap;

  const AppHeader({
    super.key,
    required this.activeMenu,
    required this.onMenuSelected,
    required this.onEditProfile,
    required this.onLogout,
    required this.menuItems,
    required this.isMobile,
    this.onMenuTap,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final GlobalKey _avatarKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showMenu() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    final RenderBox renderBox = _avatarKey.currentContext!.findRenderObject() as RenderBox;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.only(top: 65, right: 20, bottom: 20, left: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFC6707), width: 2.5),
                        ),
                        child: ClipOval(
                          child: Consumer<AuthController>(
                            builder: (context, auth, _) {
                              final foto = auth.usuarioActual?.fotoBase64;
                              if (foto != null && foto.isNotEmpty) {
                                return Image.memory(
                                  base64Decode(foto),
                                  width: 65,
                                  height: 65,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                );
                              }
                              return Container(
                                color: const Color(0xFFFDDBB3),
                                child: const Icon(Icons.person, color: Color(0xFFFC6707), size: 35),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer<AuthController>(
                        builder: (context, auth, _) {
                          final user = auth.usuarioActual;
                          final nombreCompleto = user != null 
                              ? '${user.nombre} ${user.apellido ?? ''}' 
                              : 'Usuario';
                          return Text(
                            nombreCompleto.trim().isEmpty ? 'Usuario' : nombreCompleto,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            _overlayEntry?.remove();
                            _overlayEntry = null;
                            widget.onEditProfile();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.settings_outlined, color: Color(0xFFFC6707), size: 22),
                                const SizedBox(width: 14),
                                Text(
                                  'Editar Perfil',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            _overlayEntry?.remove();
                            _overlayEntry = null;
                            widget.onLogout();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.logout_outlined, color: Color(0xFFFC6707), size: 22),
                                const SizedBox(width: 14),
                                Text(
                                  'Cerrar Sesión',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    // MÓVIL
    if (widget.isMobile) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => widget.onMenuSelected('Inicio'),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.5,
                    child: Image.asset('assets/images/logo.png', width: 60, height: 60),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.asset('assets/images/Nombre.png', height: 25),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFFFC6707), size: 28),
              onPressed: widget.onMenuTap,
            ),
          ],
        ),
      );
    }

    // ESCRITORIO
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => widget.onMenuSelected('Inicio'),
            child: Row(
              children: [
                Transform.scale(scale: 1.5, child: Image.asset('assets/images/logo.png', width: 60, height: 60)),
                const SizedBox(width: 4),
                Padding(padding: const EdgeInsets.only(top: 8), child: Image.asset('assets/images/Nombre.png', height: 25)),
              ],
            ),
          ),
          const SizedBox(width: 115),
          Row(
            children: widget.menuItems.map((title) {
              final isActive = title == widget.activeMenu;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onMenuSelected(title),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? const Color(0xFFFC6707) : const Color(0xFF555555),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: _avatarKey,
              onTap: _showMenu,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFC6707), width: 2),
                ),
                child: ClipOval(
                  child: Consumer<AuthController>(
                    builder: (context, auth, _) {
                      final foto = auth.usuarioActual?.fotoBase64;
                      if (foto != null && foto.isNotEmpty) {
                        return Image.memory(
                          base64Decode(foto),
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        );
                      }
                      return Container(
                        color: const Color(0xFFFDDBB3),
                        child: const Icon(Icons.person, color: Color(0xFFFC6707), size: 24),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}