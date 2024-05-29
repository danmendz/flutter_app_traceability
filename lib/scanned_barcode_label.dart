import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannedBarcodeLabel extends StatelessWidget {
  const ScannedBarcodeLabel({
    Key? key,
    required this.barcodes,
    this.onScanned, // Agregamos el parámetro con valor predeterminado
  }) : super(key: key); // Asegurémonos de llamar al constructor super

  final Stream<BarcodeCapture> barcodes;
  final Function(String)? onScanned; // Indicamos que la función puede ser nula

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: barcodes,
      builder: (context, snapshot) {
        final scannedBarcodes = snapshot.data?.barcodes ?? [];

        if (scannedBarcodes.isEmpty) {
          return const Text(
            '¡Escanea algo!',
            overflow: TextOverflow.fade,
            style: TextStyle(color: Colors.white),
          );
        }

        final String qrData = scannedBarcodes.first.displayValue ?? 'Información no obtenida.';
        
        // Llamamos a la función onScanned si está definida
        if (onScanned != null) {
          WidgetsBinding.instance?.addPostFrameCallback((_) {
            onScanned!(qrData);
          });
        }

        return Text(
          qrData,
          overflow: TextOverflow.fade,
          style: const TextStyle(color: Colors.white),
        );
      },
    );
  }
}