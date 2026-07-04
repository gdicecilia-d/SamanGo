// Sistema de diseño compartido del panel de administración de SamanGo.
// Colócalo en: lib/views/shared/admin_theme.dart
//
// Centraliza colores, tipografía y widgets reutilizados por todas las
// vistas admin_*.dart (dashboard, gestión, operadores, reportes,
// estudiantes, usuarios), para no repetir la misma paleta/drawer/tabs en
// cada archivo y poder ajustar el look completo desde un solo lugar.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de color del panel admin.
/// El naranja sigue siendo el acento principal (color de marca), y se
/// suma un verde petróleo como acento secundario para dar personalidad
/// visual propia sin perder coherencia con el resto de la app.
class AdminPalette {
  AdminPalette._();

  static const primary = Color(0xFFFC6707);
  static const primaryDark = Color(0xFFE0550A);
  static const primaryLight = Color(0xFFFFE8D6);

  static const secondary = Color(0xFF12756B);
  static const secondaryLight = Color(0xFFD9EFEC);

  static const ink = Color(0xFF23262B);
  static const slate = Color(0xFF5B6470);
  static const mist = Color(0xFF9AA3AD);
  static const cloud = Color(0xFFF3F4F6);
  static const line = Color(0xFFE7E9EC);

  static const success = Color(0xFF1FA97A);
  static const warning = Color(0xFFF5A524);
  static const danger = Color(0xFFE5484D);

  /// Paleta cíclica usada en gráficos y badges de tarjetas de métricas.
  static const chartColors = [primary, secondary, warning, Color(0xFF6C63FF)];

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFFF9142)],
  );

  static BoxShadow softShadow([Color? tint]) => BoxShadow(
        color: (tint ?? Colors.black).withOpacity(tint != null ? 0.18 : 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      );

  static BoxDecoration card({Color? accent, double radius = 20}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line, width: 1),
        boxShadow: [softShadow()],
      );
}

/// Estilos de texto (Google Fonts Outfit) compartidos por todo el panel.
class AdminStyles {
  AdminStyles._();

  static TextStyle title(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 22 : 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AdminPalette.ink,
      );

  static final subtitle = GoogleFonts.outfit(fontSize: 14, color: AdminPalette.slate);

  static final cardValue = GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AdminPalette.ink);

  static final cardLabel = GoogleFonts.outfit(fontSize: 13, color: AdminPalette.slate);

  /// Título fijo usado en cabeceras de tarjetas (gráficos, bloques).
  static final cardTitle =
      GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AdminPalette.ink);

  /// Título de sección que escala con el tamaño de pantalla (tablas admin).
  static TextStyle tableTitle(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 16 : 19,
        fontWeight: FontWeight.bold,
        color: AdminPalette.ink,
      );

  static final chartRowLabel = GoogleFonts.outfit(fontSize: 13, color: AdminPalette.ink);

  static final chartRowValue =
      GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AdminPalette.primaryDark);

  static final emptyState = GoogleFonts.outfit(fontSize: 13, color: AdminPalette.mist);

  static final drawerName = GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AdminPalette.ink);

  static final drawerRole = GoogleFonts.outfit(fontSize: 12, color: AdminPalette.slate);

  static TextStyle drawerItem(bool isActive) => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive ? AdminPalette.primaryDark : AdminPalette.ink,
      );

  static TextStyle infoLabel(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 11 : 12,
        fontWeight: FontWeight.w600,
        color: AdminPalette.slate,
      );

  static TextStyle infoValue(bool isMobile, {Color? color}) => GoogleFonts.outfit(
        fontSize: isMobile ? 11 : 12,
        color: color ?? AdminPalette.ink,
      );

  static TextStyle footer(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 10 : 12,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      );
}

/// Entrada de menú del panel admin: título, ícono, vista destino y si la
/// navegación debe reemplazar la pantalla actual (`pushReplacement`) o
/// apilarse (`push`). Cada vista admin_*.dart arma su propia lista de
/// entradas y decide el comportamiento de navegación.
class AdminMenuEntry {
  final String title;
  final IconData icon;
  final WidgetBuilder? viewBuilder;
  final bool replace;

  const AdminMenuEntry(this.title, this.icon, [this.viewBuilder, this.replace = false]);
}

// ===========================================================================
// Widgets compartidos
// ===========================================================================

/// Encabezado de sección con una barra de acento en degradado antes del
/// título (en vez de un texto en negrita "pelado").
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final bool isMobile;
  final Widget? trailing;

  const AdminSectionHeader({super.key, required this.title, required this.isMobile, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: isMobile ? 22 : 26,
              decoration:
                  const BoxDecoration(gradient: AdminPalette.gradient, borderRadius: BorderRadius.all(Radius.circular(4))),
            ),
            const SizedBox(width: 10),
            Text(title, style: AdminStyles.title(isMobile)),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Badge de estado con color + ícono opcional (en vez de solo un punto de
/// color, para que el estado se lea también por forma, no solo por color).
class AdminStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AdminStatusBadge({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Estado vacío estándar: ícono dentro de un círculo suave + mensaje.
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final EdgeInsets padding;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AdminPalette.cloud, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: AdminPalette.mist),
            ),
            const SizedBox(height: 12),
            Text(message, style: AdminStyles.emptyState, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Fila "label: valor" reutilizada en tarjetas de detalle (operadores,
/// reportes...).
class AdminInfoRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool isMobile;

  const AdminInfoRow({super.key, required this.label, required this.value, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: isMobile ? 80 : 100, child: Text(label, style: AdminStyles.infoLabel(isMobile))),
          Expanded(child: value),
        ],
      ),
    );
  }
}

/// Botón flotante "Volver" con sombra de tinte naranja en vez de negra.
class AdminBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const AdminBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AdminPalette.line),
            boxShadow: [AdminPalette.softShadow(AdminPalette.primary)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded, color: AdminPalette.primary, size: 16),
              const SizedBox(width: 6),
              Text('Volver',
                  style: GoogleFonts.outfit(fontSize: 14, color: AdminPalette.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selector de pestañas tipo "segmented control" con relleno en
/// degradado para la pestaña activa (en vez de un naranja plano).
class AdminSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isMobile;

  const AdminSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AdminPalette.cloud, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: selectedIndex == i ? AdminPalette.gradient : null,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: selectedIndex == i
                        ? [BoxShadow(color: AdminPalette.primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: selectedIndex == i ? FontWeight.bold : FontWeight.w500,
                        color: selectedIndex == i ? Colors.white : AdminPalette.slate,
                      ),
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

/// Barra de pie de página compartida por todas las vistas admin: mismo
/// degradado y texto legal que el dashboard, para no repetirlo a mano en
/// cada archivo.
class AdminFooter extends StatelessWidget {
  final bool isMobile;

  const AdminFooter({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
      decoration: const BoxDecoration(
        gradient: AdminPalette.gradient,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Center(
        child: Text(
          '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
          textAlign: TextAlign.center,
          style: AdminStyles.footer(isMobile),
        ),
      ),
    );
  }
}

/// Panel lateral con la imagen del campus, usado en desktop junto al
/// contenido principal (dashboard, usuarios...) para dar un toque visual
/// además de las tarjetas/tablas.
class AdminCampusPanel extends StatelessWidget {
  final double width;

  const AdminCampusPanel({super.key, this.width = 320});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5)),
      ),
      child: Image.asset(
        'assets/images/campus_admin.png',
        width: width,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AdminPalette.primaryLight,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 48, color: AdminPalette.primary),
                SizedBox(height: 8),
                Text('Imagen del Campus'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ítem individual del drawer: pastilla de fondo cuando está activo, en
/// vez de solo texto en negrita.
class _AdminDrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _AdminDrawerItem({required this.icon, required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isActive ? AdminPalette.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: isActive ? AdminPalette.primaryDark : AdminPalette.slate, size: 20),
                const SizedBox(width: 12),
                Text(title, style: AdminStyles.drawerItem(isActive)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Drawer completo del panel admin: encabezado con avatar del usuario +
/// menú de navegación + cerrar sesión. Compartido por las 6 vistas admin
/// para no repetir la misma estructura (y para poder rediseñarla en un
/// solo lugar).
class AdminDrawer extends StatelessWidget {
  final List<AdminMenuEntry> menu;
  final String activeMenu;
  final String? userName;
  final String? userFotoBase64;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final ValueChanged<String> onMenuSelected;

  const AdminDrawer({
    super.key,
    required this.menu,
    required this.activeMenu,
    required this.onEditProfile,
    required this.onLogout,
    required this.onMenuSelected,
    this.userName,
    this.userFotoBase64,
  });

  @override
  Widget build(BuildContext context) {
    final tieneFoto = userFotoBase64 != null && userFotoBase64!.isNotEmpty;

    return Drawer(
      backgroundColor: Colors.white,
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onEditProfile,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AdminPalette.gradient,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: tieneFoto
                            ? Image.memory(base64Decode(userFotoBase64!), width: 46, height: 46, fit: BoxFit.cover)
                            : Container(
                                color: Colors.white,
                                child: const Icon(Icons.admin_panel_settings, color: AdminPalette.primary, size: 26),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName ?? 'Administrador', style: AdminStyles.drawerName),
                        Text('Administrador', style: AdminStyles.drawerRole),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AdminPalette.line),
            const SizedBox(height: 8),
            for (final entry in menu)
              _AdminDrawerItem(
                icon: entry.icon,
                title: entry.title,
                isActive: entry.title == activeMenu,
                onTap: () {
                  Navigator.pop(context);
                  if (entry.title != activeMenu) onMenuSelected(entry.title);
                },
              ),
            const Spacer(),
            const Divider(height: 1, color: AdminPalette.line),
            const SizedBox(height: 8),
            _AdminDrawerItem(
              icon: Icons.logout_outlined,
              title: 'Cerrar Sesión',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}