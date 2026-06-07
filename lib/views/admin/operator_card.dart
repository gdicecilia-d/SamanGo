import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/usuario.dart';

class OperatorCard extends StatefulWidget {
  final Map<String, dynamic> operadorMap;
  final Usuario operadorObj;
  final int selectedTab;
  final bool isMobile;
  final Function(String) onMessage;

  const OperatorCard({
    super.key,
    required this.operadorMap,
    required this.operadorObj,
    required this.selectedTab,
    required this.isMobile,
    required this.onMessage,
  });

  @override
  State<OperatorCard> createState() => _OperatorCardState();
}

class _OperatorCardState extends State<OperatorCard> {
  bool _isHoveringAceptar = false;
  bool _isHoveringRechazar = false;
  bool _isProcessing = false;

  void _verLicencia(String url) {
    if (url.isEmpty) {
      widget.onMessage('Este operador no tiene licencia cargada.');
      return;
    }
    try {
      if (url.startsWith('data:image')) {
        final bytes = base64Decode(url.split(',').last);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Image.memory(bytes),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar', style: TextStyle(color: Color(0xFFFC6707))),
              )
            ],
          ),
        );
      } else {
        widget.onMessage('Formato de licencia no soportado o inválido.');
      }
    } catch (e) {
      widget.onMessage('Error al abrir la licencia.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        key: PageStorageKey(widget.operadorMap['id']),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFDDBB3),
              ),
              child: const Icon(Icons.business_center, color: Color(0xFFFC6707), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.operadorMap['empresa']!,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    widget.operadorMap['nombre']!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.selectedTab == 0) ...[
              GestureDetector(
                onTap: _isProcessing ? null : () async {
                  setState(() => _isProcessing = true);
                  final error = await Provider.of<AuthController>(context, listen: false).approveOperator(widget.operadorObj);
                  if (mounted) setState(() => _isProcessing = false);
                  if (error != null) widget.onMessage(error);
                  else widget.onMessage('Operador aprobado correctamente');
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isHoveringAceptar = true),
                  onExit: (_) => setState(() => _isHoveringAceptar = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isHoveringAceptar ? const Color(0xFF45A049) : const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Aceptar',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isProcessing ? null : () async {
                  setState(() => _isProcessing = true);
                  final error = await Provider.of<AuthController>(context, listen: false).rejectOperator(widget.operadorObj);
                  if (mounted) setState(() => _isProcessing = false);
                  if (error != null) widget.onMessage(error);
                  else widget.onMessage('Operador rechazado');
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isHoveringRechazar = true),
                  onExit: (_) => setState(() => _isHoveringRechazar = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isHoveringRechazar ? const Color(0xFFE53935) : const Color(0xFFF44336),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Rechazar',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else if (widget.selectedTab == 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Aprobado',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rechazado',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF44336),
                  ),
                ),
              ),
            ],
          ],
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow('Representante:', widget.operadorMap['nombre']!),
              _buildInfoRow('Correo:', widget.operadorMap['correo']!),
              _buildInfoRow('Teléfono:', widget.operadorMap['telefono']!),
              _buildInfoRow('RIF:', widget.operadorMap['rif']!),
              _buildInfoRow('Descripción:', widget.operadorMap['descripcion']!),
              _buildInfoRow('Fecha de Nac.:', widget.operadorMap['fechaSolicitud']!),
              _buildLicenciaRow(widget.operadorMap['licenciaUrl']!),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenciaRow(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 120,
            child: Text(
              'Licencia:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _verLicencia(url),
              child: Text(
                url.isNotEmpty ? 'Ver documento cargado' : 'No hay documento',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: url.isNotEmpty ? const Color(0xFFFC6707) : const Color(0xFF999999),
                  decoration: url.isNotEmpty ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
