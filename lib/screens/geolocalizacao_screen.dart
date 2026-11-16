import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';

class GeolocalizacaoScreen extends StatefulWidget {
  const GeolocalizacaoScreen({super.key});

  @override
  State<GeolocalizacaoScreen> createState() => _GeolocalizacaoScreenState();
}

class _GeolocalizacaoScreenState extends State<GeolocalizacaoScreen> {
  final _locationService = LocationService();
  Position? _posicaoAtual;
  bool _carregando = false;
  String? _mensagemErro;
  StreamSubscription<Position>? _positionStreamSub;
  bool _rastreando = false;

  // Desafio Intermediário: Coordenadas da Fatec Matão
  static const double fatecMataoLat = -21.6148;
  static const double fatecMataoLng = -48.3596;

  Future<void> _buscarLocalizacao() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });
    try {
      final posicao = await _locationService.obterPosicaoAtual();
      setState(() => _posicaoAtual = posicao);
    } catch (e) {
      setState(() => _mensagemErro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _alternarRastreamento() {
    if (_rastreando) {
      _positionStreamSub?.cancel();
      setState(() => _rastreando = false);
    } else {
      setState(() => _rastreando = true);
      _positionStreamSub = _locationService.monitorarPosicao().listen(
        (pos) => setState(() => _posicaoAtual = pos),
        onError: (err) => setState(() => _mensagemErro = err.toString()),
      );
    }
  }

  // Desafio Avançado: Abrir no Google Maps usando url_launcher
  Future<void> _abrirNoGoogleMaps(double latitude, double longitude) async {
    final uri = Uri.parse('https://maps.google.com/?q=$latitude,$longitude');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o link do mapa.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o mapa: $e')),
        );
      }
    }
  }

  // Desafio Básico: Indicador visual com Chip conforme a precisão
  Widget _buildChipPrecisao(double accuracy) {
    Color corFundo;
    Color corTexto;
    IconData icone;
    String rotulo;

    if (accuracy < 15) {
      corFundo = Colors.green.shade100;
      corTexto = Colors.green.shade900;
      icone = Icons.check_circle;
      rotulo = 'Precisão Alta (< 15m): ${accuracy.toStringAsFixed(1)}m';
    } else if (accuracy <= 50) {
      corFundo = Colors.amber.shade100;
      corTexto = Colors.amber.shade900;
      icone = Icons.warning_amber_rounded;
      rotulo = 'Precisão Média (15-50m): ${accuracy.toStringAsFixed(1)}m';
    } else {
      corFundo = Colors.red.shade100;
      corTexto = Colors.red.shade900;
      icone = Icons.error_outline;
      rotulo = 'Precisão Baixa (> 50m): ${accuracy.toStringAsFixed(1)}m';
    }

    return Chip(
      avatar: Icon(icone, color: corTexto, size: 18),
      backgroundColor: corFundo,
      label: Text(
        rotulo,
        style: TextStyle(color: corTexto, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Desafio Intermediário: Cálculo de Distância até a Fatec Matão
  double? _calcularDistanciaAteFatec() {
    if (_posicaoAtual == null) return null;
    return Geolocator.distanceBetween(
      _posicaoAtual!.latitude,
      _posicaoAtual!.longitude,
      fatecMataoLat,
      fatecMataoLng,
    );
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distanciaFatec = _calcularDistanciaAteFatec();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in & GPS'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            if (_mensagemErro != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _mensagemErro!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            if (_posicaoAtual != null) ...[
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.my_location, color: Colors.blue),
                        title: const Text('Latitude'),
                        subtitle: Text('${_posicaoAtual!.latitude}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.green),
                        title: const Text('Longitude'),
                        subtitle: Text('${_posicaoAtual!.longitude}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.speed, color: Colors.orange),
                        title: const Text('Precisão / Altitude'),
                        subtitle: Text(
                          'Precisão: ${_posicaoAtual!.accuracy.toStringAsFixed(1)}m | Alt: ${_posicaoAtual!.altitude.toStringAsFixed(1)}m',
                        ),
                      ),
                      // Desafio Básico: Medidor de Precisão
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildChipPrecisao(_posicaoAtual!.accuracy),
                        ),
                      ),
                      const Divider(),
                      // Desafio Intermediário: Distância até a Fatec Matão
                      if (distanciaFatec != null)
                        ListTile(
                          leading: const Icon(Icons.school, color: Colors.indigo),
                          title: const Text('Distância até a Fatec Matão'),
                          subtitle: Text(
                            distanciaFatec >= 1000
                                ? '${(distanciaFatec / 1000).toStringAsFixed(2)} km (${distanciaFatec.toStringAsFixed(0)} m)'
                                : '${distanciaFatec.toStringAsFixed(1)} metros',
                          ),
                        ),
                      // Desafio Avançado: Botão para abrir no Google Maps
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () => _abrirNoGoogleMaps(
                              _posicaoAtual!.latitude,
                              _posicaoAtual!.longitude,
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Abrir no Google Maps'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _carregando ? null : _buscarLocalizacao,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Capturar Localização Atual'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _alternarRastreamento,
                icon: Icon(_rastreando ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _rastreando
                      ? 'Parar Rastreamento'
                      : 'Iniciar Rastreamento Contínuo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
