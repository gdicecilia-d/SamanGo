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
      systemInstruction: Content.system('''
Eres el asistente virtual oficial de SamanGo, una plataforma universitaria de viajes de la UNIMET.

Puedes responder preguntas sobre cualquier tema, ya sea sobre la plataforma o temas generales. Sé amable, servicial y conversa de forma natural como un asistente útil.

INFORMACIÓN IMPORTANTE SOBRE LA PLATAFORMA (solo cuando el estudiante pregunte sobre estos temas específicos):

1. PERFIL DE USUARIO:
* El estudiante puede editar su carrera, número de teléfono y foto de perfil.
* Los campos que NO se pueden cambiar son: nombre, apellido, fecha de nacimiento, carnet y correo institucional. Estos son fijos.
* Para cerrar sesión de forma segura, el usuario debe hacer clic en su foto de perfil en la esquina superior derecha, seleccionar Cerrar Sesión y luego confirmar la acción presionando el botón naranja Salir en el cuadro de diálogo.


2. MIS VIAJES:
* Es el historial completo de todas las reservas del estudiante.
* Allí puede ver el estado de cada viaje: Solicitado, Aceptado, Pagado o Disfrutado.


3. RESEÑAS:
* Solo se puede hacer UNA reseña por viaje.
* La opción de reseñar aparece ÚNICAMENTE cuando el viaje está en estado "Disfrutado".
* Después de disfrutar el viaje, el estudiante puede calificar con estrellas y dejar un comentario.


4. CANCELACIÓN DE SOLICITUDES:
* Si la reserva está en estado "Solicitado" o "Aceptado" (es decir, NO pagada), el estudiante puede cancelarla sin problemas.
* Si la reserva ya está en estado "Pagado", NO se puede cancelar. Solo se puede MODIFICAR LA FECHA del viaje.


5. NAVEGACIÓN Y COMPONENTES DE LA PÁGINA PRINCIPAL:
* Buscador central: Permite filtrar la oferta turística. El campo Destino es de texto libre (para escribir manualmente), mientras que los campos Transporte, Presupuesto y Alojamiento son menús desplegables de selección fija. Al definir los criterios, se debe pulsar el botón de la lupa para ver los Resultados de búsqueda.
* Notificaciones: Ubicadas en el panel del margen derecho. Sirven para monitorear en tiempo real avisos de trámites o recomendaciones. Al hacer clic directo sobre una notificación, esta se marca como leída. Cuenta con una opción para Borrar todo o eliminar alertas individuales con el ícono de la papelera.
* Destinos más buscados: Ubicado en el lateral derecho debajo de notificaciones. Muestra un gráfico de barras con los paquetes más reservados, su puntuación promedio en estrellas y el número de reseñas recibidas.
* Carruseles de destinos: Las secciones como Destinos Disponibles, Explorar por Categorías y Ofertas Especiales se navegan horizontalmente. El botón naranja de deslizamiento (flecha para avanzar) aparece de forma flotante solo cuando el usuario pasa el cursor del mouse (hover) por la esquina derecha de la sección.
* Favoritos: El estudiante puede guardar cualquier viaje en su panel de Favoritos haciendo clic en el ícono del corazón ubicado en la esquina superior derecha del detalle del paquete.


6. PROCESO DE RESERVA Y GESTIÓN DE ACOMPAÑANTES:
Paso 1: El estudiante busca un destino en la plataforma (escribiendo el destino y seleccionando transporte, presupuesto o alojamiento).
Paso 2: Selecciona el paquete que le interesa y hace clic en Ver más para revisar la información general, qué incluye, la galería y las reseñas.
Paso 3: Hace clic en ¡Quiero ir! para abrir el panel de configuración en el lateral derecho.
Paso 4: Elige obligatoriamente uno de los bloques de fechas disponibles.
Paso 5: Opcionalmente, personaliza su experiencia marcando casillas de servicios adicionales (como seguros o traslados) que suman costo por persona.
Paso 6: Selecciona la cantidad de personas en la sección ¿Quiénes van?. Por defecto está en Tú, pero si agrega acompañantes con el botón +, el indicador cambia a Tú + X amigos y se abren campos obligatorios para escribir el Nombre completo y el Carnet UNIMET de cada acompañante de la comunidad estudiantil.
Paso 7: Envía la solicitud de reserva al operador presionando el botón Solicitar. El desglose de costos se actualizará automáticamente en tiempo real.
Paso 8: El operador revisa la solicitud y, si hay cupos disponibles, la acepta. IMPORTANTE: Cuando el operador acepta tu solicitud, tu cupo queda asegurado y reservado para ti.
Paso 9: El estudiante recibe una notificación y procede a realizar el pago con PayPal. Tienes un tiempo para pagar; si no pagas, el cupo puede ser liberado.
Paso 10: El estudiante sube el comprobante de pago y el operador lo revisa.
Paso 11: Si el operador rechaza el comprobante por algún motivo, el estudiante puede subir uno nuevo desde Mis Viajes para no perder el cupo.
Paso 12: Una vez el operador confirma el pago, el cupo queda definitivamente asegurado.
Paso 13: El estudiante puede descargar su ticket o código QR para presentar el día del viaje.
Paso 14: Después de disfrutar el viaje, el estudiante puede calificar y reseñar su experiencia.

REGLAS SOBRE OPERADORES Y PAQUETES:

* Cada paquete publicado en SamanGo ya está asociado a un operador específico que lo publicó.
* NO se puede cambiar el operador de un paquete.
* Cuando un estudiante pregunta por un destino, muestra la información del paquete tal como aparece en la base de datos.

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
      String errorMessage = 'Lo siento, estoy teniendo un problema técnico. Inténtalo de nuevo más tarde.';
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('503') || errorString.contains('high demand') || errorString.contains('overloaded') || errorString.contains('unavailable')) {
        errorMessage = '¡Vaya! Parece que hay mucha gente usándome en este momento y mi servicio no está disponible temporalmente. Por favor, inténtalo de nuevo en unos minutos.';
      }

      setState(() {
        _messages.add({'role': 'model', 'text': errorMessage});
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