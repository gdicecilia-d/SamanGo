// Header para usuarios autenticados (Estudiante, Operador, Admin)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/custom_dialog.dart';

class UserHeader extends StatefulWidget {
  final String activeMenu;
  final Function(String) onMenuSelected;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final List<String> menuItems;
  final bool isMobile;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onMenuTap;

  const UserHeader({
    super.key,
    required this.activeMenu,
    required this.onMenuSelected,
    required this.onEditProfile,
    required this.onLogout,
    required this.menuItems,
    required this.isMobile,
    this.onNotificationsTap,
    this.onMenuTap,
  });

  @override
  State<UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<UserHeader> {
  final GlobalKey _avatarKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showMenu() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    final RenderBox renderBox = _avatarKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

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
                      Column(
                        children: [
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFC6707), width: 2.5),
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFFFDDBB3),
                              child: Icon(Icons.person, color: Color(0xFFFC6707), size: 35),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '---',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
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
                            _mostrarDialogoCerrarSesion();
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

  void _mostrarDialogoCerrarSesion() {
    CustomConfirmDialog.show(
      context: context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Salir',
      icon: Icons.logout,
    ).then((confirm) {
      if (confirm == true) {
        widget.onLogout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cell 
    if (widget.isMobile) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            InkWell(
              onTap: () => widget.onMenuSelected('Inicio'),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.5,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.asset(
                      'assets/images/Nombre.png',
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            // Menú móvil (3 rayas)
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFFFC6707), size: 28),
              onPressed: widget.onMenuTap,
            ),
          ],
        ),
      );
    }

    // Compu 
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
          // Logo
          Row(
            children: [
              Transform.scale(
                scale: 1.5,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.asset(
                  'assets/images/Nombre.png',
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          const SizedBox(width: 115),
          // Menú horizontal
          Row(
            children: widget.menuItems.map((title) {
              final isActive = title == widget.activeMenu;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onMenuSelected(title),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? const Color(0xFFFC6707) : const Color(0xFF555555),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 20,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFC6707),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Avatar con menú desplegable
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
                child: const CircleAvatar(
                  backgroundColor: Color(0xFFFDDBB3),
                  child: Icon(Icons.person, color: Color(0xFFFC6707), size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}