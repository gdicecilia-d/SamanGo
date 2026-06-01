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
}
