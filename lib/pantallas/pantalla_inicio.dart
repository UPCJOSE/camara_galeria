/// Pantalla principal de "Galería rápida".
///
/// Solo se ocupa de la UI: botones, vista previa, mensaje de estado
/// e indicador de carga. La lógica vive en los servicios.
///
/// En Web, "Tomar foto" abre [PantallaCamaraWeb] (getUserMedia).
/// En Android/iOS usa permission_handler + image_picker.
library;

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../servicios/servicio_imagen.dart';
import '../servicios/servicio_permisos.dart';
import 'pantalla_camara_web.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final _permisos = ServicioPermisos();
  final _imagenes = ServicioImagen();

  /// Bytes de la imagen: funciona igual en Web, Android e iOS
  /// (evita importar dart:io / File, que rompe la compilación web).
  Uint8List? _bytesImagen;
  String _mensajeEstado =
      'Pulsa un botón. Verás si el permiso se concede, se niega o se cancela.';
  bool _cargando = false;

  Future<void> _tomarFoto() async {
    // Web: cámara real con getUserMedia (muestra el permiso del navegador).
    if (kIsWeb) {
      setState(() {
        _cargando = true;
        _mensajeEstado = 'Abriendo cámara web (permiso del navegador)…';
      });

      final foto = await Navigator.push<XFile?>(
        context,
        MaterialPageRoute(builder: (_) => const PantallaCamaraWeb()),
      );

      if (!mounted) return;

      if (foto == null) {
        setState(() {
          _cargando = false;
          _mensajeEstado =
              'Acción cancelada o permiso denegado en Web. '
              'Si bloqueaste la cámara, restablécela con el candado de la URL.';
        });
        return;
      }

      final bytes = await foto.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytesImagen = bytes;
        _cargando = false;
        _mensajeEstado =
            'Permiso concedido en Web (getUserMedia). Foto: ${foto.name}';
      });
      return;
    }

    // Android e iOS: permission_handler + image_picker.
    setState(() => _cargando = true);

    final permiso = await _permisos.asegurarCamara();
    if (!mounted) return;

    if (permiso.resultado == ResultadoPermiso.denegadoPermanentemente) {
      setState(() {
        _cargando = false;
        _mensajeEstado = permiso.mensaje;
      });
      await _mostrarDialogoAjustes();
      return;
    }

    if (!permiso.puedeContinuar) {
      setState(() {
        _cargando = false;
        _mensajeEstado = permiso.mensaje;
      });
      return;
    }

    final resultado = await _imagenes.tomarFoto();
    if (!mounted) return;

    await _aplicarResultadoImagen(
      resultado,
      mensajePermisoPrevio: permiso.mensaje,
    );
  }

  Future<void> _elegirGaleria() async {
    setState(() => _cargando = true);

    final permiso = await _permisos.asegurarGaleria();
    if (!mounted) return;

    if (permiso.resultado == ResultadoPermiso.denegadoPermanentemente) {
      setState(() {
        _cargando = false;
        _mensajeEstado = permiso.mensaje;
      });
      await _mostrarDialogoAjustes();
      return;
    }

    if (!permiso.puedeContinuar) {
      setState(() {
        _cargando = false;
        _mensajeEstado = permiso.mensaje;
      });
      return;
    }

    final resultado = await _imagenes.elegirDeGaleria();
    if (!mounted) return;

    await _aplicarResultadoImagen(
      resultado,
      mensajePermisoPrevio: permiso.mensaje,
    );
  }

  Future<void> _aplicarResultadoImagen(
    ResultadoImagen resultado, {
    required String mensajePermisoPrevio,
  }) async {
    if (resultado.archivo != null) {
      final bytes = await resultado.archivo!.readAsBytes();
      setState(() {
        _bytesImagen = bytes;
        _mensajeEstado = '${resultado.mensaje} ($mensajePermisoPrevio)';
        _cargando = false;
      });
      return;
    }

    setState(() {
      _mensajeEstado = resultado.mensaje;
      _cargando = false;
    });
  }

  Future<void> _mostrarDialogoAjustes() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permiso bloqueado'),
          content: const Text(
            'Negaste el permiso de forma permanente. '
            'Galería rápida necesita este acceso para la demo. '
            'Puedes activarlo manualmente en los ajustes del sistema.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () async {
                await _permisos.abrirAjustes();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Abrir ajustes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Galería rápida',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: esquema.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _mensajeEstado,
                    style: const TextStyle(fontSize: 18, height: 1.35),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _cargando ? null : _tomarFoto,
                icon: const Icon(Icons.photo_camera, size: 28),
                label: const Text('Tomar foto'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _cargando ? null : _elegirGaleria,
                icon: const Icon(Icons.photo_library, size: 28),
                label: const Text('Elegir de galería'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: esquema.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: esquema.outlineVariant),
                  ),
                  child: Center(
                    child: _cargando
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Abriendo cámara o galería…',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : _bytesImagen == null
                            ? const Text(
                                'Sin imagen\nAquí verás la vista previa',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  _bytesImagen!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
