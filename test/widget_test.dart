import 'package:flutter_test/flutter_test.dart';
import 'package:recursos_dispositivo/main.dart';

void main() {
  testWidgets('Verifica se a tela de Geolocalizacao inicializa corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MeuApp());

    // Verifica se a AppBar com título 'Check-in & GPS' está presente
    expect(find.text('Check-in & GPS'), findsOneWidget);

    // Verifica se os botões principais de localização estão visíveis
    expect(find.text('Capturar Localização Atual'), findsOneWidget);
    expect(find.text('Iniciar Rastreamento Contínuo'), findsOneWidget);
  });
}
