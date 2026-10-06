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
  /// - iOS: usamos [Permission.photos].
  /// - Android 13+ (API 33+): image_picker usa el Photo Picker del sistema
  ///   y normalmente NO requiere permiso de lectura. Por eso en Android
  ///   moderno podemos continuar sin bloquear por Permission.photos.
  /// - Android 12 o inferior: a veces hace falta almacenamiento; image_picker
  ///   suele gestionar el acceso. Pedimos photos/storage solo si aplica.
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
      // En Android, Permission.photos puede no ser el mismo flujo que iOS.
      // Si ya está concedido o limitado, seguimos.
      var estado = await Permission.photos.status;

      if (!estado.isGranted && !estado.isLimited) {
        estado = await Permission.photos.request();
      }

      // Si el SO no aplica el permiso (p. ej. Photo Picker en Android 13+),
      // permission_handler a veces reporta denegado aunque el picker funcione.
      // En ese caso dejamos continuar y image_picker abrirá el selector.
      if (defaultTargetPlatform == TargetPlatform.android &&
          (estado.isDenied || estado.isPermanentlyDenied)) {
        return const RespuestaPermiso(
          resultado: ResultadoPermiso.concedido,
          mensaje:
              'Android: con image_picker (Photo Picker en API 33+) '
              'suele no hacer falta permiso. Continuamos a la galería.',
        );
      }

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
