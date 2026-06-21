import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiChatbotWidget extends StatefulWidget {
  const GeminiChatbotWidget({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GeminiChatbotWidget(),
    );
  }

  @override
  State<GeminiChatbotWidget> createState() => _GeminiChatbotWidgetState();
}

class _GeminiChatbotWidgetState extends State<GeminiChatbotWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  GenerativeModel? _model;
  ChatSession? _chat;
  
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
      _messages.add({
        'role': 'model',
        'text': '¡Hola! Soy la IA de SamanGo. Estoy sincronizando mi memoria con la base de datos de destinos...',
      });
    });

    String contextData = 'Destinos disponibles:\n';
    try {
      final destinosQuery = await FirebaseFirestore.instance.collection('destinos').where('activo', isEqualTo: true).get();
      for (var doc in destinosQuery.docs) {
        final data = doc.data();
        final n = data['nombre'] ?? '';
        final u = data['ubicacion'] ?? 'Ubicación no especificada';
        final p = data['precio'] ?? '';
        final d = data['duracion'] ?? '';
        final operadorNombre = data['operadorNombre'] ?? 'Operador no especificado';
        final operadorEmpresa = data['operadorEmpresa'] ?? 'Empresa no especificada';
        contextData += '- Paquete: $n | Ubicación: $u (Precio: \$$p, Duración: $d, Operador: $operadorNombre - $operadorEmpresa)\n';
      }
    } catch (e) {
      contextData += '(Error al cargar la base de datos)';
    }

    final p1 = 'AQ.Ab8RN6IB4WX';
    final p2 = 'SWQECbNMxkec';
    final p3 = 'tCnPLZUTUNDG';
    final p4 = 'UniY1aaPFo34niw';
    final apiKey = p1 + p2 + p3 + p4;
    
    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''Eres el asistente virtual oficial de SamanGo, una plataforma universitaria de viajes de la UNIMET.

Puedes responder preguntas sobre cualquier tema, ya sea sobre la plataforma o temas generales. Sé amable, servicial y conversa de forma natural como un asistente útil.

INFORMACIÓN IMPORTANTE SOBRE LA PLATAFORMA (solo cuando el estudiante pregunte sobre estos temas específicos):

1. PERFIL DE USUARIO:
   - El estudiante puede editar su carrera, número de teléfono y foto de perfil.
   - Los campos que NO se pueden cambiar son: nombre, apellido, fecha de nacimiento, carnet y correo institucional. Estos son fijos.

2. MIS VIAJES:
   - Es el historial completo de todas las reservas del estudiante.
   - Allí puede ver el estado de cada viaje: Solicitado, Aceptado, Pagado o Disfrutado.

3. RESEÑAS:
   - Solo se puede hacer UNA reseña por viaje.
   - La opción de reseñar aparece ÚNICAMENTE cuando el viaje está en estado "Disfrutado".
   - Después de disfrutar el viaje, el estudiante puede calificar con estrellas y dejar un comentario.

4. CANCELACIÓN DE SOLICITUDES:
   - Si la reserva está en estado "Solicitado" o "Aceptado" (es decir, NO pagada), el estudiante puede cancelarla sin problemas.
   - Si la reserva ya está en estado "Pagado", NO se puede cancelar. Solo se puede MODIFICAR LA FECHA del viaje.

5. PROCESO DE RESERVA (solo si el estudiante pregunta específicamente por cómo reservar):
   Paso 1: El estudiante busca un destino en la plataforma.
   Paso 2: Selecciona el paquete que le interesa.
   Paso 3: Elige la fecha disponible que más le convenga.
   Paso 4: Selecciona la cantidad de personas (puede incluir acompañantes).
   Paso 5: Envía la solicitud de reserva al operador.
   Paso 6: El operador revisa la solicitud y, si hay cupos disponibles, la acepta. IMPORTANTE: Cuando el operador acepta tu solicitud, tu cupo queda asegurado y reservado para ti.
   Paso 7: El estudiante recibe una notificación y procede a realizar el pago con PayPal. Tienes un tiempo para pagar; si no pagas, el cupo puede ser liberado.
   Paso 8: El estudiante sube el comprobante de pago y el operador lo revisa.
   Paso 9: Si el operador rechaza el comprobante por algún motivo, el estudiante puede subir uno nuevo para no perder el cupo.
   Paso 10: Una vez el operador confirma el pago, el cupo queda definitivamente asegurado.
   Paso 11: El estudiante puede descargar su ticket o código QR para presentar el día del viaje.
   Paso 12: Después de disfrutar el viaje, el estudiante puede calificar y reseñar su experiencia.

REGLAS SOBRE OPERADORES Y PAQUETES:
- Cada paquete publicado en SamanGo ya está asociado a un operador específico que lo publicó.
- NO se puede cambiar el operador de un paquete.
- Cuando un estudiante pregunta por un destino, muestra la información del paquete tal como aparece en la base de datos.

MUY IMPORTANTE: NO uses formato Markdown como asteriscos (*) en tus respuestas. Escribe texto plano.

Aquí tienes la lista en tiempo real de la base de datos para que recomiendes estos datos EXACTOS:

$contextData'''),
    );
    
    _chat = _model!.startChat();
    
    if (mounted) {
      setState(() {
        _messages.last['text'] = '¡Memoria sincronizada! Soy tu asistente de SamanGo. Puedo ayudarte con cualquier cosa, ya sea sobre la plataforma o temas generales. ¿Qué necesitas saber?';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chat == null) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chat!.sendMessage(Content.text(text));
      final cleanText = response.text?.replaceAll('*', '') ?? 'Lo siento, no pude procesar tu solicitud.';
      
      setState(() {
        _messages.add({'role': 'model', 'text': cleanText});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'model', 'text': 'Error técnico: $e'});
        _isLoading = false;
      });
    }
    
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: 24 + bottomInset,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC6707).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFFC6707)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SamanGo AI Assistant',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE0E0E0)),
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['text']!, isUser);
              },
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircularProgressIndicator(color: Color(0xFFFC6707)),
              ),
            ),
            
          Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: _chat != null && !_isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _chat != null && !_isLoading ? const Color(0xFFFC6707) : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _chat != null && !_isLoading ? _sendMessage : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFFC6707) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: isUser ? Colors.white : const Color(0xFF333333),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}