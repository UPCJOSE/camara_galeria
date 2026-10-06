/// Pantalla de cámara solo para Web.
///
/// Usa el paquete [camera] (camera_web) para activar getUserMedia.
/// Al llamar a initialize(), el navegador muestra su cuadro
/// de permiso: "Permitir" o "Bloquear".
library;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PantallaCamaraWeb extends StatefulWidget {
  const PantallaCamaraWeb({super.key});

  @override
  State<PantallaCamaraWeb> createState() => _PantallaCamaraWebState();
}

class _PantallaCamaraWebState extends State<PantallaCamaraWeb> {
  CameraController? _controlador;
  String _estado = 'Solicitando permiso de cámara...';
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _iniciarCamara();
  }

  Future<void> _iniciarCamara() async {
    try {
      // 1. Lista las cámaras disponibles.
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        setState(() => _estado = 'No se encontró ninguna cámara.');
        return;
      }

      // 2. initialize() dispara el cuadro de permiso del navegador (getUserMedia).
      // enableAudio: false → solo pide CÁMARA, no micrófono (por defecto es true).
      final controlador = CameraController(
        camaras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controlador.initialize();

      if (!mounted) return;
      setState(() {
        _controlador = controlador;
        _listo = true;
        _estado = 'Permiso concedido.';
      });
    } on CameraException catch (e) {
      // 3. Si el usuario bloquea el permiso, llega aquí.
      // Mira e.code en la consola para ajustar el mensaje si hace falta.
      debugPrint('CameraException: ${e.code} - ${e.description}');
      setState(() {
        _estado =
            'Permiso denegado o cámara no disponible (${e.code}). '
            'Restablece el permiso con el candado de la barra de direcciones.';
      });
    } catch (e) {
      setState(() => _estado = 'Error inesperado: $e');
    }
  }

  Future<void> _capturar() async {
    final controlador = _controlador;
    if (controlador == null || !controlador.value.isInitialized) return;

    try {
      final foto = await controlador.takePicture();
      // En Web, foto.path es una URL blob: que también se puede leer con bytes.
      if (mounted) Navigator.pop(context, foto);
    } on CameraException catch (e) {
      setState(() => _estado = 'No se pudo capturar (${e.code}).');
    }
  }

  @override
  void dispose() {
    _controlador?.dispose(); // Libera la cámara al salir.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cámara web')),
      body: Center(
        child: _listo
            ? Column(
                children: [
                  Expanded(child: CameraPreview(_controlador!)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _estado,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _capturar,
                          icon: const Icon(Icons.camera),
                          label: const Text('Capturar'),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _estado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
      ),
    );
  }
}
