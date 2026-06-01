class FormValidators {
  // 1. Validación de Correo Institucional (Estudiante UNIMET)
  static String? validarCorreoUnimet(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es obligatorio';
    }
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@correo\.unimet\.edu\.ve$');
    if (!regex.hasMatch(value)) {
      return 'Debe ser un correo válido (@correo.unimet.edu.ve)';
    }
    return null;
  }

  // 2. Validación de Carnet UNIMET (Permite 7 u 8 dígitos)
  static String? validarCarnet(String? value) {
    if (value == null || value.isEmpty) {
      return 'El carnet es obligatorio';
    }
    final regex = RegExp(r'^\d{7,8}$');
    if (!regex.hasMatch(value)) {
      return 'El carnet debe contener entre 7 y 8 números';
    }
    return null;
  }

  // 3. Validación de Teléfono (Guion opcional)
  static String? validarTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    final regex = RegExp(r'^(0414|0424|0412|0416|0426|0212)-?\d{7}$');
    if (!regex.hasMatch(value)) {
      return 'Formato inválido. Ejemplo: 04121234567 o 0412-1234567';
    }
    return null;
  }

  // 4. Validación de RIF Venezolano (Guiones opcionales)
  static String? validarRif(String? value) {
    if (value == null || value.isEmpty) {
      return 'El RIF es obligatorio';
    }
    final regex = RegExp(r'^[JVEGP]-?\d{8}-?\d{1}$');
    if (!regex.hasMatch(value.toUpperCase())) {
      return 'Formato de RIF inválido. Ejemplo: J123456789 o J-12345678-9';
    }
    return null;
  }
}
