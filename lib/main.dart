import 'package:flutter/material.dart';
import 'package:escaner_qr/maquinado/maquinado_main.dart';
import 'package:escaner_qr/estante/estante_main.dart';

void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escaner QR',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red).copyWith(
          secondary: const Color.fromARGB(255, 255, 168, 168),
        ),
        scaffoldBackgroundColor: Colors.white, // Fondo blanco
        appBarTheme: const AppBarTheme(
          color: Colors.red, // Color de la barra de navegación
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.red), // Color de fondo del botón
          ),
        ),
        // textTheme: const TextTheme(
        //   bodyLarge: TextStyle(color: Colors.white), // Color de texto predeterminado // Color de texto secundario
        //   // Aquí puedes agregar más estilos de texto según sea necesario
        // ),
      ),
      home: const MyHome(),
    );
  }
}

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

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
                  MaterialPageRoute(builder: (context) => MaquinadoApp()),
                );
              } else if (mode == 'estante') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => EstanteHome()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'maquinado',
                child: Text('Maquinado'),
              ),
              const PopupMenuItem<String>(
                value: 'estante',
                child: Text('Estante'),
              ),
            ],
          ),
        ],
      ),
      body: const Center(
        child: Text('Contenido de la pantalla principal'),
      ),
    );
  }
}