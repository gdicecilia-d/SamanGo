// Validaciones de formularios
import 'package:flutter/services.dart';

class FormValidators {
  // Validación de nombre de empresa
  static String? validarEmpresa(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre de la empresa es obligatorio';
    }
    if (value.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    return null;
  }

  // Validación de número de RIF (solo números, 8-9 dígitos)
  static String? validarRifNumero(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de RIF es obligatorio';
    }
    final regex = RegExp(r'^\d{8,9}$');
    if (!regex.hasMatch(value)) {
      return 'Debe tener entre 8 y 9 dígitos (solo números)';
    }
    return null;
  }

  // Validación de representante legal
  static String? validarRepresentante(String? value) {
    if (value == null || value.isEmpty) {
      return 'El representante legal es obligatorio';
    }
    if (value.length < 5) {
      return 'Mínimo 5 caracteres';
    }
    return null;
  }

  // Validación de número de teléfono (solo números, 7 dígitos)
  static String? validarTelefonoNumero(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de teléfono es obligatorio';
    }
    final regex = RegExp(r'^\d{7}$');
    if (!regex.hasMatch(value)) {
      return 'Debe tener 7 dígitos (ej: 1234567)';
    }
    return null;
  }

  // Lista de dominios permitidos para el Operador
  static const List<String> dominiosPermitidosOperador = ['.com', '.ve', '.com.ve', '.org', '.net', '.edu', '.gob.ve'];

  // Validación de email para OPERADOR (permite números)
  static String? validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio';
    }
    // Ya no se valida que no tenga números
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) {
      return 'Formato de email inválido (ejemplo@dominio.com)';
    }

    bool hasValidDomain = dominiosPermitidosOperador.any((domain) => value.toLowerCase().endsWith(domain));
    if (!hasValidDomain) {
      return 'Dominio inválido. Permitidos: ${dominiosPermitidosOperador.join(", ")}';
    }

    return null;
  }

  // Validación de correo UNIMET para ESTUDIANTE (NO permite números)
  static String? validarCorreoUnimet(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es obligatorio';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'El correo no puede contener números';
    }
    final regex = RegExp(r'^[a-zA-Z._%+-]+@correo\.unimet\.edu\.ve$');
    if (!regex.hasMatch(value)) {
      return 'Debe ser un correo UNIMET válido (@correo.unimet.edu.ve)';
    }
    return null;
  }

  // Validación de contraseña
  static String? validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSymbol = RegExp(r'[!@#\$%\^&\*\(\)_\+\-\=\[\]\{\};:\x27",\.<>\/?\\|`~]').hasMatch(value);
    
    List<String> faltantes = [];
    if (!hasUpper) faltantes.add('una mayúscula');
    if (!hasLower) faltantes.add('una minúscula');
    if (!hasNumber) faltantes.add('un número');
    if (!hasSymbol) faltantes.add('un símbolo');
    
    if (faltantes.isNotEmpty) {
      return 'Falta: ${faltantes.join(', ')}';
    }
    return null;
  }

  // Validación de descripción
  static String? validarDescripcion(String? value) {
    if (value == null || value.isEmpty) {
      return 'La descripción es obligatoria';
    }
    if (value.length < 10) {
      return 'Mínimo 10 caracteres';
    }
    return null;
  }

  // Validación de archivo subido
  static String? validarArchivo(String? fileName) {
    if (fileName == null || fileName.isEmpty) {
      return 'Debes subir la licencia de turismo';
    }
    return null;
  }

  // Validación de carnet UNIMET (solo números, 7-11 dígitos)
  static String? validarCarnet(String? value) {
    if (value == null || value.isEmpty) {
      return 'El carnet es obligatorio';
    }
    final regex = RegExp(r'^\d{7,11}$');
    if (!regex.hasMatch(value)) {
      return 'El carnet debe tener entre 7 y 11 números (solo dígitos)';
    }
    return null;
  }

  // Validación de nombre completo
  static String? validarNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'No puede contener números';
    }
    return null;
  }
}
