/// Punto de entrada de "Galería rápida".
///
/// Solo arranca la app y define el tema Material 3.
/// La pantalla y los servicios están en otras carpetas de lib/.
library;

import 'package:flutter/material.dart';

import 'pantallas/pantalla_inicio.dart';

void main() {
  // Necesario antes de plugins (permisos / image_picker) en algunas plataformas.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GaleriaRapidaApp());
}

class GaleriaRapidaApp extends StatelessWidget {
  const GaleriaRapidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galería rápida',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const PantallaInicio(),
    );
  }
}
