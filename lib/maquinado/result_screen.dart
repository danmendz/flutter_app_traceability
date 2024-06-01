import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class ResultScreen extends StatefulWidget {
  final String qrData;

  ResultScreen({required this.qrData});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class Player {
  static play(String src) async {
    final player = AudioPlayer();
    await player.play(AssetSource(src));
  }
}

class _ResultScreenState extends State<ResultScreen> {

  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _area = '';
  String _machine = '';

  Future<void> _registerData() async {
    final url = Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/insertar-reporte.php');
    final response = await http.get(Uri(
      scheme: url.scheme,
      host: url.host,
      port: url.port,
      path: url.path,
      queryParameters: {
        'datos': widget.qrData,
        'area': _area,
        'maquina': _machine,
        'operador': _fullName,
      },
    ));
    
    if (response.statusCode == 200) {
      // Éxito en la solicitud
      _showDialog('Éxito', 'Datos registrados exitosamente');
      await Player.play('audio/correct-sound.mp3');
    } else {
      // Error en la solicitud
      _showDialog('Error', 'Error al registrar datos: ${response.reasonPhrase}');
      await Player.play('audio/wrong-sound.mp3');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultado del Escaneo'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Datos del QR: ${widget.qrData}',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre Completo'),
                onChanged: (value) {
                  setState(() {
                    _fullName = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su nombre completo';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Área'),
                onChanged: (value) {
                  setState(() {
                    _area = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su área';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Máquina'),
                onChanged: (value) {
                  setState(() {
                    _machine = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese la máquina';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _registerData();
                  }
                },
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white), // Color del texto
                ),
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}