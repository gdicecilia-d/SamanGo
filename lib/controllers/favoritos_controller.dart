import 'dart:async';
import 'package:flutter/material.dart';
import '../services/favoritos_service.dart';

class FavoritosController extends ChangeNotifier {
  final FavoritosService _favoritosService = FavoritosService();
  String _userId = '';
  List<String> _favoritos = [];
  StreamSubscription<List<String>>? _subscription;

  List<String> get favoritos => _favoritos;

  void updateUsuario(String userId) {
    if (_userId != userId) {
      _userId = userId;
      _subscription?.cancel();
      
      if (_userId.isNotEmpty) {
        _subscription = _favoritosService.obtenerFavoritosStream(_userId).listen((favs) {
          _favoritos = favs;
          notifyListeners();
        });
      } else {
        _favoritos = [];
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool esFavorito(String destinoId) {
    return _favoritos.contains(destinoId);
  }

  Future<void> toggleFavorito(String destinoId) async {
    if (_userId.isEmpty) return;
    
    final eraFavorito = esFavorito(destinoId);
    
    // Actualización optimista local para que la UI se sienta instantánea
    if (eraFavorito) {
      _favoritos.remove(destinoId);
    } else {
      _favoritos.add(destinoId);
    }
    notifyListeners();

    try {
      if (eraFavorito) {
        await _favoritosService.eliminarFavorito(_userId, destinoId);
      } else {
        await _favoritosService.agregarFavorito(_userId, destinoId);
      }
    } catch (e) {
      // Revertir en caso de error
      if (eraFavorito) {
        _favoritos.add(destinoId);
      } else {
        _favoritos.remove(destinoId);
      }
      notifyListeners();
      rethrow;
    }
  }
}
