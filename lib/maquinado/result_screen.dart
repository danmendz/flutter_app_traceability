import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

class ResultScreen extends StatefulWidget {
  final String qrData;

  ResultScreen({required this.qrData});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

// Model classes
class Area {
  final String id;
  final String nombre;
  final List<Maquina> maquinas;
  final List<Operador> operadores;

  Area({required this.id, required this.nombre, required this.maquinas, required this.operadores});

  factory Area.fromJson(Map<String, dynamic> json) {
    var maquinasJson = json['maquinas'] as List;
    var operadoresJson = json['operadores'] as List;

    List<Maquina> maquinasList = maquinasJson.map((i) => Maquina.fromJson(i)).toList();
    List<Operador> operadoresList = operadoresJson.map((i) => Operador.fromJson(i)).toList();

    return Area(
      id: json['id'],
      nombre: json['nombre'],
      maquinas: maquinasList,
      operadores: operadoresList,
    );
  }
}

class Maquina {
  final String id;
  final String nombre;
  final String estatus;
  final String idArea;

  Maquina({required this.id, required this.nombre, required this.estatus, required this.idArea});

  factory Maquina.fromJson(Map<String, dynamic> json) {
    return Maquina(
      id: json['id'],
      nombre: json['nombre'],
      estatus: json['estatus'],
      idArea: json['id_area'],
    );
  }
}

class Operador {
  final String id;
  final String nombre;
  final String idArea;

  Operador({required this.id, required this.nombre, required this.idArea});

  factory Operador.fromJson(Map<String, dynamic> json) {
    return Operador(
      id: json['id'],
      nombre: json['nombre'],
      idArea: json['id_area'],
    );
  }
}

class Player {
  static play(String src) async {
    final player = AudioPlayer();
    await player.play(AssetSource(src));
  }
}

class _ResultScreenState extends State<ResultScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedArea;
  String? _selectedMachine;
  String? _selectedOperator;
  bool _isLoading = true; // Variable to control the loading state

  List<Area> _areas = [];
  List<Maquina> _filteredMachines = [];
  List<Operador> _filteredOperators = [];

  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  Future<void> _fetchAreas() async {
    final response = await http.get(Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/obtener-areas.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['areas'];
      setState(() {
        _areas = data.map((dynamic item) => Area.fromJson(item)).toList();
        _isLoading = false; // Set loading to false when data is fetched
      });
    } else {
      throw Exception('Failed to load areas');
    }
  }

  void _onAreaChanged(String? newValue) {
    setState(() {
      _selectedArea = newValue;
      _selectedMachine = null;
      _selectedOperator = null;
      _filteredMachines = _areas
          .firstWhere((area) => area.id == newValue)
          .maquinas;
      _filteredOperators = _areas
          .firstWhere((area) => area.id == newValue)
          .operadores;
    });
  }

  void _onMachineChanged(String? newValue) {
    setState(() {
      _selectedMachine = newValue;
    });
  }

  void _onOperatorChanged(String? newValue) {
    setState(() {
      _selectedOperator = newValue;
    });
  }

  Future<void> _registerData() async {
    final url = Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/insertar-reporte2.php');
    final response = await http.get(Uri(
      scheme: url.scheme,
      host: url.host,
      port: url.port,
      path: url.path,
      queryParameters: {
        'datos': widget.qrData,
        'area': _selectedArea ?? '',
        'maquina': _selectedMachine ?? '',
        'operador': _selectedOperator ?? '',
      },
    ));

    if (response.statusCode == 200) {
      _showDialog(context, 'Éxito', 'Datos registrados exitosamente', Colors.green, Icons.check_circle);
      // Éxito en la solicitud
      await Player.play('audio/correct-sound.mp3');
    } else {
      // Error en la solicitud
      _showDialog(context, 'Error', 'Error al registrar datos: ${response.reasonPhrase}', Colors.red, Icons.error);
      await Player.play('audio/wrong-sound.mp3');
    }
  }

  void _showDialog(BuildContext context, String title, String message, Color? backgroundColor, IconData icon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor ?? Colors.white,
          title: Row(
            children: [
              Icon(icon, color: backgroundColor != null ? Colors.white : Colors.black),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: backgroundColor != null ? Colors.white : Colors.black),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "OK",
                style: TextStyle(color: backgroundColor != null ? Colors.white : Colors.black),
              ),
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
      body: _isLoading // Show the progress indicator if data is still loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Área'),
                      value: _selectedArea,
                      items: _areas.map((Area area) {
                        return DropdownMenuItem<String>(
                          value: area.id,
                          child: Text(area.nombre),
                        );
                      }).toList(),
                      onChanged: _onAreaChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, seleccione un área';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Máquina'),
                      value: _selectedMachine,
                      items: _filteredMachines.map((Maquina maquina) {
                        return DropdownMenuItem<String>(
                          value: maquina.id,
                          child: Text(maquina.nombre),
                        );
                      }).toList(),
                      onChanged: _onMachineChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, seleccione una máquina';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Operador'),
                      value: _selectedOperator,
                      items: _filteredOperators.map((Operador operador) {
                        return DropdownMenuItem<String>(
                          value: operador.id,
                          child: Text(operador.nombre),
                        );
                      }).toList(),
                      onChanged: _onOperatorChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, seleccione un operador';
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
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.green), // Color del fondo
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