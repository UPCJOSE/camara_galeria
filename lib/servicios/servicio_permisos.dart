/// Servicio de permisos.
///
/// Centraliza la consulta y solicitud de permisos de cámara y fotos
/// con [permission_handler], para poder explicarlo aparte de la UI.
///
/// En Web este servicio no pide nada: el navegador gestiona el permiso
/// cuando se usa image_picker (getUserMedia / file picker).
library;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Resultado amigable del flujo de permisos (fácil de mostrar en pantalla).
enum ResultadoPermiso {
  concedido,
  denegado,
  denegadoPermanentemente,
  restringido,
  limitado,
  omitidoEnWeb,
  error,
}

/// Envuelve el resultado con un mensaje listo para el video / la UI.
class RespuestaPermiso {
  const RespuestaPermiso({
    required this.resultado,
    required this.mensaje,
  });

  final ResultadoPermiso resultado;
  final String mensaje;

  /// true solo si podemos continuar y abrir cámara o galería.
  bool get puedeContinuar =>
      resultado == ResultadoPermiso.concedido ||
      resultado == ResultadoPermiso.limitado ||
      resultado == ResultadoPermiso.omitidoEnWeb;
}

class ServicioPermisos {
  /// Flujo de permiso de CÁMARA:
  /// 1) Si es Web → omitir (el navegador preguntará después).
  /// 2) Consultar status.
  /// 3) Si no está concedido → request().
  /// 4) Traducir el estado a un mensaje claro.
  Future<RespuestaPermiso> asegurarCamara() async {
    if (kIsWeb) {
      return const RespuestaPermiso(
        resultado: ResultadoPermiso.omitidoEnWeb,
        mensaje:
            'Web: permission_handler no aplica. El navegador pedirá el '
            'permiso al abrir la cámara (getUserMedia; HTTPS o localhost).',
      );
    }

    try {
      // Paso 1: consultar el estado actual sin molestar al usuario todavía.
      var estado = await Permission.camera.status;

      // Paso 2: si aún no está concedido, pedirlo en tiempo de ejecución.
      if (!estado.isGranted && !estado.isLimited) {
        estado = await Permission.camera.request();
      }

      return _mapear(estado, recurso: 'cámara');
    } catch (e) {
      return RespuestaPermiso(
        resultado: ResultadoPermiso.error,
        mensaje: 'Error al solicitar permiso de cámara: $e',
      );
    }
  }

  /// Flujo de permiso de GALERÍA / fotos.
  ///
  /// - iOS y Android: usamos [Permission.photos] (o el equivalente del SO).
  /// - Si el usuario niega o cancela, NO abrimos la galería: respetamos
  ///   su decisión (importante para la demo de aceptar / negar).
  /// - Nota: en Android 13+ el Photo Picker de image_picker podría abrir
  ///   sin este permiso, pero nosotros pedimos permiso primero a propósito
  ///   para mostrar el diálogo y el caso "denegado".
  Future<RespuestaPermiso> asegurarGaleria() async {
    if (kIsWeb) {
      return const RespuestaPermiso(
        resultado: ResultadoPermiso.omitidoEnWeb,
        mensaje:
            'Web: no hay permiso de fotos del SO. Se usa el selector '
            'de archivos del navegador.',
      );
    }

    try {
      // 1) Consultar estado actual.
      var estado = await Permission.photos.status;

      // 2) Si aún no está concedido, pedirlo (aquí sale el diálogo).
      if (!estado.isGranted && !estado.isLimited) {
        estado = await Permission.photos.request();
      }

      // 3) Mapear el resultado. Si negaron/cancelaron, puedeContinuar = false
      //    y la UI no llama a image_picker.
      return _mapear(estado, recurso: 'fotos / galería');
    } catch (e) {
      return RespuestaPermiso(
        resultado: ResultadoPermiso.error,
        mensaje: 'Error al solicitar permiso de galería: $e',
      );
    }
  }

  /// Abre los ajustes del sistema (útil si el permiso quedó denegado
  /// permanentemente y el usuario debe reactivarlo a mano).
  Future<bool> abrirAjustes() => openAppSettings();

  RespuestaPermiso _mapear(PermissionStatus estado, {required String recurso}) {
    if (estado.isGranted) {
      return RespuestaPermiso(
        resultado: ResultadoPermiso.concedido,
        mensaje: 'Permiso concedido ($recurso).',
      );
    }
    if (estado.isLimited) {
      return RespuestaPermiso(
        resultado: ResultadoPermiso.limitado,
        mensaje:
            'Permiso limitado ($recurso): acceso parcial (típico en iOS). '
            'Se puede continuar.',
      );
    }
    if (estado.isPermanentlyDenied) {
      return RespuestaPermiso(
        resultado: ResultadoPermiso.denegadoPermanentemente,
        mensaje:
            'Permiso denegado permanentemente ($recurso). '
            'Actívalo en Ajustes del sistema.',
      );
    }
    if (estado.isRestricted) {
      return RespuestaPermiso(
        resultado: ResultadoPermiso.restringido,
        mensaje:
            'Permiso restringido ($recurso). El dispositivo o un control '
            'parental no permite cambiarlo.',
      );
    }
    // isDenied u otros
    return RespuestaPermiso(
      resultado: ResultadoPermiso.denegado,
      mensaje: 'Permiso denegado ($recurso). Puedes volver a intentarlo.',
    );
  }
}
