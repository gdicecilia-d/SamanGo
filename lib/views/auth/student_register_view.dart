// Abraham
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudentRegisterView extends StatefulWidget {
  const StudentRegisterView({super.key});

  @override
  State<StudentRegisterView> createState() => _StudentRegisterViewState();
}

class _StudentRegisterViewState extends State<StudentRegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _carnetController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _carnetController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Eliminamos appTheme de aquí (se configura globalmente en el main.dart si es necesario)
      body: Center(
        child: Container(
          // La forma correcta de limitar la altura en un Container:
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Registro de Estudiante - EcoRutas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 1. Validación de Correo UNIMET
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Institucional',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El correo es obligatorio';
                    }
                    if (!value.trim().endsWith('@correo.unimet.edu.ve')) {
                      return 'Debe terminar en @correo.unimet.edu.ve';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Validación de Carnet (8 dígitos strictly numéricos)
                TextFormField(
                  controller: _carnetController,
                  decoration: const InputDecoration(
                    labelText: 'Carnet',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El carnet es obligatorio';
                    }
                    if (value.length < 8) {
                      return 'El carnet debe tener exactamente 8 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Validación de Teléfono (11 dígitos, ej: 04121234567)
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono Celular',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El teléfono es obligatorio';
                    }
                    if (value.length < 11) {
                      return 'El teléfono debe tener 11 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Aquí se conectará con el controlador de autenticación más adelante
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Validación web exitosa...'),
                        ),
                      );
                    }
                  },
                  child: const Text('Registrarse'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
