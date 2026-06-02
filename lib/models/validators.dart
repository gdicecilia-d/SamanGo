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

  // Validación de email para OPERADOR (cualquier dominio válido)
  static String? validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio';
    }
    // Acepta cualquier email con formato válido: ejemplo@cualquier-dominio.com
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) {
      return 'Formato de email inválido (ejemplo@dominio.com)';
    }
    return null;
  }

  // Validación de correo UNIMET para ESTUDIANTE
  static String? validarCorreoUnimet(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es obligatorio';
    }
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@correo\.unimet\.edu\.ve$');
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
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
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

  // Validación de carnet UNIMET (solo números, 7-8 dígitos)
  static String? validarCarnet(String? value) {
    if (value == null || value.isEmpty) {
      return 'El carnet es obligatorio';
    }
    final regex = RegExp(r'^\d{7,8}$');
    if (!regex.hasMatch(value)) {
      return 'El carnet debe tener 7 u 8 números (solo dígitos)';
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
    return null;
  }
}