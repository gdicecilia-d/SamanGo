import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_header.dart';
import 'student_home_view.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLargeScreen = screenWidth > 1400;
    
    final double titleFontSize = isMobile ? 24 : (isLargeScreen ? 32 : 28);
    final double sectionFontSize = isMobile ? 18 : (isLargeScreen ? 22 : 20);
    final double bodyFontSize = isMobile ? 14 : (isLargeScreen ? 16 : 15);
    final double paddingHorizontal = isMobile ? 20 : (isLargeScreen ? 60 : 40);
    final double containerWidth = isMobile ? double.infinity : (isLargeScreen ? 1000 : 800);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Términos y Condiciones',
          style: GoogleFonts.outfit(
            fontSize: titleFontSize - 4,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFC6707),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFC6707),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFC6707)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 24),
        child: Center(
          child: Container(
            width: containerWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título principal
                Text(
                  'Términos y Condiciones de Uso',
                  style: GoogleFonts.outfit(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFC6707),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido a SamanGo',
                  style: GoogleFonts.outfit(
                    fontSize: bodyFontSize,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Introducción
                Text(
                  'Al acceder y utilizar nuestra plataforma móvil y web de gestión de turismo económico, aceptas cumplir y estar sujeto a los siguientes Términos y Condiciones de Uso. Si no estás de acuerdo con alguna de estas disposiciones, te solicitamos que no utilices la aplicación.',
                  style: GoogleFonts.outfit(
                    fontSize: bodyFontSize,
                    color: const Color(0xFF444444),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Sección 1
                _buildSection(
                  '1. Definición del Servicio',
                  'SamanGo es una plataforma tecnológica diseñada para la comunidad universitaria de la Universidad Metropolitana (UNIMET) que facilita la visualización, búsqueda y organización de destinos turísticos económicos, ofertas especiales y gestión de itinerarios. SamanGo actúa exclusivamente como intermediario e informativo y no como agencia de viajes directa.',
                  sectionFontSize,
                  bodyFontSize,
                ),
                
                // Sección 2
                _buildSection(
                  '2. Elegibilidad y Cuentas de Usuario',
                  'Acceso Restringido: El uso de la plataforma está dirigido principalmente a estudiantes, profesores y personal de la comunidad UNIMET.\n\nRegistro: Para utilizar ciertas funciones (como guardar favoritos, gestionar viajes o recibir notificaciones), el usuario debe registrarse aportando datos verídicos, exactos y actualizados (Nombre, Apellido, correo electrónico, etc.).\n\nSeguridad de la Cuenta: El usuario es el único responsable de mantener la confidencialidad de sus credenciales de acceso y de todas las actividades que ocurran bajo su cuenta.',
                  sectionFontSize,
                  bodyFontSize,
                ),
                
                // Sección 3
                _buildSection(
                  '3. Uso Aceptable de la Plataforma',
                  'Al utilizar SamanGo, te comprometes a:\n\n• No utilizar la aplicación con fines ilegales o no autorizados.\n• No alterar, vulnerar o intentar acceder a áreas protegidas del código o bases de datos de la aplicación.\n• No publicar ni difundir comentarios ofensivos, acosadores o inapropiados en los módulos comunitarios o de soporte.\n• No suplantar la identidad de otros estudiantes o administradores del sistema.',
                  sectionFontSize,
                  bodyFontSize,
                ),
                
                // Sección 4
                _buildSection(
                  '4. Propiedad Intelectual',
                  'Todo el contenido visual, interfaces de usuario, modelados, logotipos, código fuente, marcas y textos de SamanGo son propiedad intelectual exclusiva de los desarrolladores del proyecto y la Comunidad UNIMET, protegidos por las leyes de propiedad intelectual vigentes. Queda prohibida su reproducción, distribución o modificación sin autorización previa.',
                  sectionFontSize,
                  bodyFontSize,
                ),
                
                // Sección 5
                _buildSection(
                  '5. Cupos y Ofertas Disponibles',
                  'Actualización de Datos: La información sobre la disponibilidad de cupos turísticos y precios de ofertas especiales se actualiza periódicamente en la base de datos. Sin embargo, SamanGo no se hace responsable por discrepancias temporales en tiempo real antes de que se procese una reserva externa.\n\nPrecios: Todos los precios se muestran en la moneda indicada en la app y corresponden exclusivamente a estimaciones de turismo económico.',
                  sectionFontSize,
                  bodyFontSize,
                ),
                
                // Sección 6
                _buildSection(
                  '6. Limitación de Responsabilidad',
                  'SamanGo proporciona la plataforma "tal cual" y "según disponibilidad". Los desarrolladores y la institución no garantizan que el servicio sea ininterrumpido o libre de errores.\n\nSamanGo no se hace responsable por:\n\n• Pérdidas de conectividad, fallas en el servidor de base de datos o mal funcionamiento técnico en pantallas web/móviles.\n• Incidentes, accidentes o inconvenientes que ocurran durante el desarrollo de las actividades turísticas publicadas, ya que la ejecución de los viajes corresponde a terceros u organizadores independientes.',
                  sectionFontSize,
                  bodyFontSize,
                ),
                
                // Sección 7
                _buildSection(
                  '7. Modificación de los Términos',
                  'Nos reservamos el derecho de modificar o reemplazar estos Términos y Condiciones en cualquier momento. Las modificaciones se harán efectivas inmediatamente después de su publicación en la aplicación. El uso continuado de SamanGo constituye la aceptación de los nuevos términos.',
                  sectionFontSize,
                  bodyFontSize,
                ),
                
                // Sección 8
                _buildSection(
                  '8. Ley Aplicable y Jurisdicción',
                  'Estos términos se rigen e interpretan de conformidad con las leyes vigentes de la República Bolivariana de Venezuela. Cualquier disputa relacionada con el uso de la plataforma será sometida a los tribunales competentes de la ciudad de Caracas.',
                  sectionFontSize,
                  bodyFontSize,
                ),
                
                const SizedBox(height: 24),
                
                // Fecha de actualización
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDDBB3).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.update, color: const Color(0xFFFC6707), size: isMobile ? 18 : 20),
                      const SizedBox(width: 8),
                      Text(
                        'Última actualización: Junio, 2026',
                        style: GoogleFonts.outfit(
                          fontSize: bodyFontSize - 2,
                          color: const Color(0xFFFC6707),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Botón Aceptar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6707),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'He leído y acepto los términos',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, double titleSize, double bodySize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFC6707),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: bodySize,
              color: const Color(0xFF444444),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}