import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class TipsNotificacionService {
  static final List<Map<String, String>> _tips = [
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Siempre lleva protector solar, incluso en días nublados.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Lleva una copia física de tus documentos importantes.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Hidrátate constantemente durante tus excursiones.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Usa ropa cómoda y calzado adecuado para caminar.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Lleva efectivo por si no aceptan tarjetas.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Carga tu teléfono y lleva un power bank.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Infórmate sobre el clima antes de viajar.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Respeta el medio ambiente: no dejes basura.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Lleva un botiquín básico con medicamentos esenciales.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Llega temprano a los puntos de encuentro.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Aprende algunas frases básicas del lugar que visitas.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Haz una lista de lo que necesitas empacar con anticipación.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Lleva una muda de ropa extra en tu mochila de mano.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Descarga mapas offline antes de viajar.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Avisa a familiares o amigos sobre tu itinerario.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Lleva snacks saludables para el camino.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Usa protector solar resistente al agua en la playa.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'No olvides tu carnet de estudiante para descuentos.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Lleva una bolsa para la basura y mantén todo limpio.'},
    {'titulo': '💡 Tip de viaje', 'mensaje': 'Toma fotos, pero también disfruta el momento sin pantallas.'},
  ];

  static Future<void> enviarTipSiCorresponde(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentWeek = _getWeekNumber(now);

    final String keyLastWeek = 'tips_last_week_$uid';
    final String keySentCount = 'tips_sent_count_$uid';
    final String keySentIds = 'tips_sent_ids_$uid';

    int lastWeek = prefs.getInt(keyLastWeek) ?? -1;
    int sentCount = prefs.getInt(keySentCount) ?? 0;
    List<String> sentIds = prefs.getStringList(keySentIds) ?? [];

    if (lastWeek != currentWeek) {
      lastWeek = currentWeek;
      sentCount = 0;
      await prefs.setInt(keyLastWeek, lastWeek);
    }

    if (sentCount >= 2) {
      print('Ya se enviaron 2 tips esta semana al usuario $uid');
      return;
    }

    // Seleccionamos un tip que no se haya enviado antes
    final availableTips = List<int>.generate(_tips.length, (i) => i)
        .where((i) => !sentIds.contains(i.toString()))
        .toList();

    if (availableTips.isEmpty) {
      // Si ya se enviaron todos, reiniciamos el historial
      sentIds.clear();
      availableTips.addAll(List<int>.generate(_tips.length, (i) => i));
    }

    final random = Random();
    final selectedTipIndex = availableTips[random.nextInt(availableTips.length)];
    final tip = _tips[selectedTipIndex];

    // Notificar solo a este estudiante
    final notifRef = FirebaseFirestore.instance.collection('estudiantes').doc(uid).collection('notificaciones').doc();
    final notificacion = Notificacion(
      id: notifRef.id,
      titulo: tip['titulo']!,
      mensaje: tip['mensaje']!,
      fechaCreacion: DateTime.now(),
      leida: false,
      tipo: 'tip',
    );

    await notifRef.set(notificacion.toMap());

    sentCount++;
    sentIds.add(selectedTipIndex.toString());

    await prefs.setInt(keySentCount, sentCount);
    await prefs.setStringList(keySentIds, sentIds);

    print('Tip enviado al usuario $uid: ${tip['mensaje']}');
  }

  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  // Se mantiene vacío por si algún código lo sigue llamando. 
  // La lógica real ahora se dispara en AuthController.login
  static Future<void> iniciarTipsAutomaticos() async {}
  static void detenerTips() {}
}