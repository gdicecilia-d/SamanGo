/// Header universal para usuarios autenticados (Estudiante, Operador, Admin)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserHeader extends StatefulWidget {
  final String activeMenu;
  final Function(String) onMenuSelected;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final List<String> menuItems;

  const UserHeader({
    super.key,
    required this.activeMenu,
    required this.onMenuSelected,
    required this.onEditProfile,
    required this.onLogout,
    required this.menuItems,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, color: Color(0xFFFC6707), size: 45),
            const SizedBox(height: 12),
            Text(
              'Cerrar Sesión',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Estás seguro de que deseas cerrar sesión?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6707),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Salir',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      foregroundColor: const Color(0xFF666666),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide.none,
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Logo sin cursor mano ni funcionalidad
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
          const SizedBox(width: 100),
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