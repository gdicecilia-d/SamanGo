import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controllers/notificacion_controller.dart';
import '../../shared/widgets/custom_dialog.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificacionController>(
      builder: (context, notificacionController, child) {
        final notificaciones = notificacionController.notificaciones;
        
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFC6707),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Notificaciones',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, 
                  children: [
                    if (notificaciones.isNotEmpty)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          CustomConfirmDialog.show(
                            context: context,
                            title: 'Borrar todo',
                            message: '¿Estás seguro de que deseas eliminar todas las notificaciones? Esta acción no se puede deshacer.',
                            confirmText: 'Borrar',
                            icon: Icons.delete_sweep,
                          ).then((confirm) {
                            if (confirm == true) {
                              notificacionController.eliminarTodasNotificaciones();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Se borraron de forma correcta',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                                  ),
                                  backgroundColor: const Color(0xFFFC6707),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          });
                        },
                        child: Text(
                          'Borrar todo',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFC6707),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              if (notificaciones.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No hay notificaciones por el momento',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: notificaciones.length,
                  itemBuilder: (context, index) {
                    final notificacion = notificaciones[index];
                    final isLast = index == notificaciones.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFFFC6707).withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        borderRadius: isLast
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              )
                            : null,
                      ),
                      child: InkWell(
                        onTap: () {
                          if (!notificacion.leida) {
                            notificacionController.marcarComoLeida(notificacion.id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notificacion.titulo,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: notificacion.leida ? FontWeight.w500 : FontWeight.bold,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Builder(
                                      builder: (context) {
                                        final match = RegExp(r'"?([a-zA-Z0-9]{20})"?').firstMatch(notificacion.mensaje);
                                        final extractedId = match?.group(1);
                                        final idToFetch = (notificacion.idPaquete != null && notificacion.idPaquete!.isNotEmpty)
                                            ? notificacion.idPaquete!
                                            : extractedId;

                                        return FutureBuilder<String?>(
                                          future: idToFetch != null && idToFetch.isNotEmpty
                                              ? notificacionController.obtenerNombreRealDestino(idToFetch)
                                              : null,
                                          builder: (context, snapshot) {
                                            String finalMensaje = notificacion.mensaje;
                                            if (snapshot.hasData && snapshot.data != null) {
                                              final nombre = snapshot.data!;
                                              if (nombre.isNotEmpty && idToFetch != null) {
                                                finalMensaje = notificacion.mensaje.replaceAll(idToFetch, nombre);
                                              }
                                            }
                                            return Text(
                                              finalMensaje,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: const Color(0xFF666666),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  notificacionController.eliminarNotificacion(notificacion.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: const Color(0xFFFC6707).withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}