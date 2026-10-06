# Galería rápida

App de ejemplo para el curso **Programación Móvil SS603**.

Demuestra cómo usar la **cámara** y la **galería** con Flutter, y cómo se configuran los **permisos en Android, iOS y Web**.

## Paquetes usados

| Paquete | Para qué |
|---|---|
| `image_picker` | Cámara/galería en Android e iOS; galería en Web |
| `permission_handler` | Consultar y pedir permisos en Android e iOS |
| `camera` | Cámara real en Web (`getUserMedia` / popup del navegador) |

## Estructura

```
lib/
  main.dart                            # Entrada y tema
  pantallas/pantalla_inicio.dart       # UI
  pantallas/pantalla_camara_web.dart   # Cámara Web (getUserMedia)
  servicios/servicio_permisos.dart     # Flujo de permisos
  servicios/servicio_imagen.dart       # image_picker
```

## Permisos por plataforma

| Plataforma | Dónde se configura | Qué se configura |
|---|---|---|
| **Android** | `android/app/src/main/AndroidManifest.xml` | `CAMERA`, `uses-feature` cámara, `READ_EXTERNAL_STORAGE` (≤ API 32). Los permisos peligrosos también se piden en ejecución. |
| **iOS** | `ios/Runner/Info.plist` | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`. En CocoaPods (`ios/Podfile`): `PERMISSION_CAMERA=1` y `PERMISSION_PHOTOS=1`. |
| **Web** | No hay archivo de permisos | El navegador usa `getUserMedia` / file picker. Requiere **HTTPS** o **localhost**. El usuario acepta o bloquea en el prompt del navegador. |

## Cómo ejecutar

```bash
# Dependencias
flutter pub get

# Android (recomendado para la demo de aceptar / negar)
flutter run -d android

# Web (Chrome). Localhost ya es contexto seguro.
flutter run -d chrome

# iOS (requiere macOS + Xcode)
flutter run -d ios
```

## Flujo de permisos (resumen para el video)

1. Antes de abrir la cámara se consulta `Permission.camera.status`.
2. Si no está concedido, se llama a `request()`.
3. Casos: concedido, denegado, denegado permanentemente (diálogo → `openAppSettings()`), restringido / limitado.
4. Galería: en iOS `Permission.photos`. En Android 13+ el Photo Picker suele no exigir permiso.
5. En Web se omite `permission_handler` (`kIsWeb`) y se deja al navegador.

## Capturas sugeridas para el video

1. Pantalla inicial con los dos botones.
2. Diálogo del sistema al conceder la cámara.
3. Vista previa con una foto tomada.
4. Caso denegado / denegado permanentemente y botón “Abrir ajustes”.
5. `AndroidManifest.xml` e `Info.plist` con zoom.
6. Web en Chrome explicando `getUserMedia` + HTTPS/localhost.

## Limitaciones conocidas

- En **Web**, “Tomar foto” usa `camera` (`PantallaCamaraWeb`) para mostrar el permiso real del navegador. La galería sigue con `image_picker` (selector de archivos).
- Funciona en **localhost** sin HTTPS; en producción sí requiere HTTPS.
- Si ya diste o bloqueaste el permiso, restablécelo con el candado de la barra de direcciones para volver a ver el cuadro.
- En **Web**, `permission_handler` no gestiona cámara/fotos como en móvil.
- iOS físico requiere Mac para compilar; se puede explicar `Info.plist` aunque la demo corra en Android.

## Créditos

Proyecto de ejemplo para tutorial universitario — SS603.
