// Abraham

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OperatorRegisterView extends StatefulWidget {
  const OperatorRegisterView({super.key});

  @override
  State<OperatorRegisterView> createState() => _OperatorRegisterViewState();
}

class _OperatorRegisterViewState extends State<OperatorRegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _rifController = TextEditingController();
  bool _isUploading = false;
  String? _fileName;
  File? _selectedFile;

  @override
  void dispose() {
    _rifController.dispose();
    super.dispose();
  }

  // Lógica para seleccionar el archivo de la Licencia de Turismo
  Future<void> _pickLicenseFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  // Conexión con Firebase Storage para la subida del documento
  Future<void> _uploadLicenseToFirebase() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'licencias_turismo/operador_${DateTime.now().millisecondsSinceEpoch}_$_fileName',
      );

      await storageRef.putFile(_selectedFile!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Licencia de Turismo subida exitosamente!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir archivo a Firebase: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Operador - EcoRutas'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos del Prestador de Servicio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 1. Validación de Formato RIF (J-XXXXXXXX-X)
                TextFormField(
                  controller: _rifController,
                  decoration: const InputDecoration(
                    labelText: 'RIF (Ej: J-12345678-9)',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El RIF es requerido';
                    }
                    final rifRegex = RegExp(r'^J-\d{8}-\d$');
                    if (!rifRegex.hasMatch(value.trim())) {
                      return 'Formato inválido. Debe ser J-XXXXXXXX-X';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Componente de Subida de Licencia de Turismo
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Licencia de Turismo (Obligatoria)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _pickLicenseFile,
                          icon: const Icon(Icons.attach_file),
                          label: const Text(
                            'Seleccionar archivo (PDF, JPG, PNG)',
                          ),
                        ),
                        if (_fileName != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Listo: $_fileName',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Botón de Registro final
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isUploading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor, selecciona el archivo de tu licencia.',
                                  ),
                                ),
                              );
                              return;
                            }
                            await _uploadLicenseToFirebase();
                          }
                        },
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrar Operador y Subir Documento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
