import 'package:flutter/material.dart';
import 'package:escaner_qr/estante/mobile_scanner_overlay.dart';
import 'package:escaner_qr/maquinado/maquinado_main.dart';
import 'package:escaner_qr/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EstanteHome extends StatefulWidget {
  const EstanteHome({Key? key}) : super(key: key);

  @override
  _EstanteHomeState createState() => _EstanteHomeState();
}

class _EstanteHomeState extends State<EstanteHome> {
  String? selectedEstanteId;

  late List<Map<String, String>> estantes = [];

  @override
  void initState() {
    super.initState();
    fetchEstantes();
  }

  Future<void> fetchEstantes() async {
    final response = await http.get(Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/obtener-estantes.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['estantes'];
      setState(() {
        estantes = data
            .map((dynamic item) => {
                  'id': item['id'] as String,
                  'nombre': item['nombre'] as String,
                })
            .toList();
        if (estantes.isNotEmpty) {
          selectedEstanteId = estantes[0]['id'];
        }
      });
    } else {
      throw Exception('Failed to load estantes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaner Móvil'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String mode) {
              // Navegar al archivo principal correspondiente según el modo seleccionado
              if (mode == 'maquinado') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MaquinadoHome()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'maquinado',
                child: Text('Maquinado'),
              ),
            ],
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navegar al main principal del proyecto
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              estantes.isEmpty
                  ? CircularProgressIndicator()
                  : Container(
                      width: MediaQuery.of(context).size.width * 1, // Por ejemplo, el 80% del ancho de la pantalla
                      child: DropdownButton<String>(
                        value: selectedEstanteId,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedEstanteId = newValue;
                            });
                          }
                        },
                        items: estantes
                            .map<DropdownMenuItem<String>>((Map<String, String> estante) {
                          return DropdownMenuItem<String>(
                            value: estante['id'],
                            child: Text(estante['nombre']!),
                          );
                        }).toList(),
                      ),
                    )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BarcodeScannerWithOverlay(
                selectedEstanteId: selectedEstanteId,
              ),
            ),
          );
        },
        child: const Icon(Icons.qr_code_scanner), // Icono de la cámara
        backgroundColor: Colors.red, // Color de fondo del botón flotante
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}