import 'package:flutter/material.dart';
import 'package:escaner_qr/maquinado/mobile_scanner_overlay.dart';
import 'package:escaner_qr/estante/estante_main.dart';
import 'package:escaner_qr/main.dart';

void main() {
  runApp(
    const MaquinadoApp(),
  );
}

class MaquinadoApp extends StatelessWidget {
  const MaquinadoApp({super.key});

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
      home: const MaquinadoHome(),
    );
  }
}

class MaquinadoHome  extends StatelessWidget {
  const MaquinadoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaner Móvil'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String mode) {
              // Navegar al archivo principal correspondiente según el modo seleccionado
              if (mode == 'estante') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => EstanteHome()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'estante',
                child: Text('Estante'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ElevatedButton eliminado
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BarcodeScannerWithOverlay(),
            ),
          );
        },
        child: Icon(Icons.qr_code_scanner), // Icono de la cámara
        backgroundColor: Colors.red, // Color de fondo del botón flotante
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,// Coloca el botón flotante en la esquina inferior derecha
    );
  }
}