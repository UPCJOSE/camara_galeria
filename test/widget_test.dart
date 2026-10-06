import 'package:flutter_test/flutter_test.dart';

import 'package:camara_y_galeria/main.dart';

void main() {
  testWidgets('Muestra título y botones de Galería rápida', (tester) async {
    await tester.pumpWidget(const GaleriaRapidaApp());

    expect(find.text('Galería rápida'), findsOneWidget);
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de galería'), findsOneWidget);
  });
}
