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

  // 2. Validación de Carnet UNIMET
  static String? validarCarnet(String? value) {
    if (value == null || value.isEmpty) {
      return 'El carnet es obligatorio';
    }
    final regex = RegExp(r'^\d{8}$');
    if (!regex.hasMatch(value)) {
      return 'El carnet debe contener exactamente 8 números';
    }
    return null;
  }

  // 3. Validación de Teléfono (Formato Venezolano)
  static String? validarTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    final regex = RegExp(r'^(0414|0424|0412|0416|0426|0212)-\d{7}$');
    if (!regex.hasMatch(value)) {
      return 'Formato inválido. Ejemplo: 0412-1234567';
    }
    return null;
  }

  // 4. Validación de RIF Venezolano
  static String? validarRif(String? value) {
    if (value == null || value.isEmpty) {
      return 'El RIF es obligatorio';
    }
    final regex = RegExp(r'^[JVEGP]-\d{8}-\d{1}$');
    if (!regex.hasMatch(value.toUpperCase())) {
      return 'Formato de RIF inválido. Ejemplo: J-12345678-9';
    }
    return null;
  }
}
