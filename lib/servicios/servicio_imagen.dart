/// Servicio de imágenes.
///
/// Encapsula image_picker: tomar foto (cámara) o elegir de la galería.
/// La UI no habla con el plugin directamente; así el video se explica fácil.
library;

import 'package:image_picker/image_picker.dart';

/// Resultado de una captura o selección.
class ResultadoImagen {
  const ResultadoImagen({
    this.archivo,
    required this.mensaje,
    this.cancelado = false,
    this.error = false,
  });

  final XFile? archivo;
  final String mensaje;
  final bool cancelado;
  final bool error;
}

class ServicioImagen {
  ServicioImagen({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Abre la cámara nativa (o el flujo web del navegador) y devuelve la foto.
  Future<ResultadoImagen> tomarFoto() async {
    try {
      final archivo = await _picker.pickImage(source: ImageSource.camera);
      if (archivo == null) {
        return const ResultadoImagen(
          cancelado: true,
          mensaje: 'Acción cancelada: no se tomó ninguna foto.',
        );
      }
      return ResultadoImagen(
        archivo: archivo,
        mensaje: 'Foto lista: ${archivo.name}',
      );
    } catch (e) {
      // En Web, si el usuario niega el permiso del navegador, suele caer aquí.
      return ResultadoImagen(
        error: true,
        mensaje: 'Error o permiso negado al usar la cámara: $e',
      );
    }
  }

  /// Abre la galería / selector de fotos.
  Future<ResultadoImagen> elegirDeGaleria() async {
    try {
      final archivo = await _picker.pickImage(source: ImageSource.gallery);
      if (archivo == null) {
        return const ResultadoImagen(
          cancelado: true,
          mensaje: 'Acción cancelada: no se eligió ninguna imagen.',
        );
      }
      return ResultadoImagen(
        archivo: archivo,
        mensaje: 'Imagen de galería lista: ${archivo.name}',
      );
    } catch (e) {
      return ResultadoImagen(
        error: true,
        mensaje: 'Error o permiso negado al abrir la galería: $e',
      );
    }
  }
}
