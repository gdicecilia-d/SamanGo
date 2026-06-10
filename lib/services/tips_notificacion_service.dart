import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notificacion_service.dart';

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

  static Timer? _timer;
  static int _tipIndex = 0;
  static const String _keyLastWeek = 'tips_last_week';
  static const String _keyTipIndex = 'tips_index';

  static Future<void> iniciarTipsAutomaticos() async {
    _timer?.cancel();
    
    await _cargarEstado();
    
    final now = DateTime.now();
    final currentWeek = _getWeekNumber(now);
    final int? lastWeek = await _getLastWeek();
    
    print('=== TIPS SERVICE ===');
    print('Semana actual: $currentWeek');
    print('Última semana enviada: $lastWeek');
    
    if (lastWeek == null || currentWeek != lastWeek) {
      print('Enviando nuevo tip de la semana...');
      await _enviarTip();
      await _guardarLastWeek(currentWeek);
    } else {
      print('Ya se envió un tip esta semana. No se enviará otro hasta la semana que viene.');
    }
    
    // Revisar cada hora si cambió de semana
    _timer = Timer.periodic(const Duration(hours: 1), (timer) async {
      final now = DateTime.now();
      final currentWeek = _getWeekNumber(now);
      final int? lastWeek = await _getLastWeek();
      
      if (lastWeek == null || currentWeek != lastWeek) {
        print('Nueva semana detectada. Enviando tip...');
        await _enviarTip();
        await _guardarLastWeek(currentWeek);
      }
    });
  }

  static Future<void> _cargarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    _tipIndex = prefs.getInt(_keyTipIndex) ?? 0;
    print('Tip index cargado: $_tipIndex');
  }

  static Future<void> _guardarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTipIndex, _tipIndex);
  }

  static Future<int?> _getLastWeek() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastWeek);
  }

  static Future<void> _guardarLastWeek(int week) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastWeek, week);
    print('Guardada semana: $week');
  }

  static int _getWeekNumber(DateTime date) {
    // Semana 1 = primera semana del año 
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  static Future<void> _enviarTip() async {
    final tip = _tips[_tipIndex % _tips.length];
    _tipIndex++;
    await _guardarEstado();
    
    final notificacionService = NotificacionService();
    
    await notificacionService.notificarAEstudiantes(
      titulo: tip['titulo']!,
      mensaje: tip['mensaje']!,
      tipo: 'tip',
    );
    
    print('Tip enviado: ${tip['mensaje']} (Índice: ${_tipIndex - 1})');
  }

  static void detenerTips() {
    _timer?.cancel();
    _timer = null;
  }
}