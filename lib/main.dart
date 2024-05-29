import 'package:flutter/material.dart';
import 'package:escaner_qr/mobile_scanner_overlay.dart';

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
          secondary: Colors.redAccent,
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
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escaner Movíl')),
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