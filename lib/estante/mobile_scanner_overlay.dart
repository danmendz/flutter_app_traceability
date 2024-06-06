import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:escaner_qr/scanned_barcode_label.dart';
import 'package:escaner_qr/scanner_button_widgets.dart';
import 'package:escaner_qr/scanner_error_widget.dart';
import 'package:escaner_qr/estante/estante_main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BarcodeScannerWithOverlay extends StatefulWidget {
  final String? selectedEstanteId; // Definir el parámetro aquí
  const BarcodeScannerWithOverlay({Key? key, this.selectedEstanteId}) : super(key: key);

  @override
  _BarcodeScannerWithOverlayState createState() => _BarcodeScannerWithOverlayState();
}

class _BarcodeScannerWithOverlayState extends State<BarcodeScannerWithOverlay> {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero),
      width: 200,
      height: 200,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escaner'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: MobileScanner(
              fit: BoxFit.contain,
              controller: controller,
              scanWindow: scanWindow,
              errorBuilder: (context, error, child) {
                return ScannerErrorWidget(error: error);
              },
              overlayBuilder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ScannedBarcodeLabel(
                      barcodes: controller.barcodes,
                      onScanned: (String qrData) {
                        if (!_isNavigating) {
                          _isNavigating = true;
                          validarYEnviarDatos(context, widget.selectedEstanteId ?? "", qrData);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              if (!value.isInitialized ||
                  !value.isRunning ||
                  value.error != null) {
                return const SizedBox();
              }

              return CustomPaint(
                painter: ScannerOverlay(scanWindow: scanWindow),
              );
            },
          ),
          Positioned(
            top: 16.0, // Margen desde la parte superior
            left: 0, // Centrado horizontal
            right: 0, // Centrado horizontal
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ToggleFlashlightButton(controller: controller),
                  SwitchCameraButton(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}

class Player {
  static play(String src) async {
    final player = AudioPlayer();
    await player.play(AssetSource(src));
  }
}

Future<void> validarYEnviarDatos(BuildContext context, String selectedId, String qrData) async {
  try {
    // Validar el QR primero
    final validacionResponse = await http.get(
      Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/validar-qr.php?data=$qrData'),
    );

    // Imprimir la respuesta de validación
    print('Validación response: ${validacionResponse.statusCode}');
    print('Validación body: ${validacionResponse.body}');

     if (validacionResponse.statusCode == 200) {
      // QR válido, proceder a enviar los datos
      final response = await http.post(
        Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/insertar-reporte-estante.php?datos=$qrData&estante=$selectedId'),
        body: json.encode({'selectedId': selectedId, 'data': qrData}),
        headers: {'Content-Type': 'application/json'},
      );

      // Imprimir la respuesta de envío
      print('Envío response: ${response.statusCode}');
      print('Envío body: ${response.body}');

      if (response.statusCode == 200) {
        _showDialog(context, 'Éxito', 'Datos registrados exitosamente');
        await Player.play('audio/correct-sound.mp3');
      } else {
        _showDialog(context, 'Error', 'Error al enviar los datos escaneados: ${response.reasonPhrase}');
        await Player.play('audio/wrong-sound.mp3');
      }
    } else {
      // QR no válido
      _showDialog(context, 'Error', 'QR no válido');
      await Player.play('audio/wrong-sound.mp3');
    }
  } catch (error) {
    _showDialog(context, 'Error', 'Error al validar/enviar los datos: $error');
    await Player.play('audio/wrong-sound.mp3');
  }
}

void _showDialog(BuildContext context, String title, String message) {
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


class ScannerOverlay extends CustomPainter {
  const ScannerOverlay({
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: use `Offset.zero & size` instead of Rect.largest
    // we need to pass the size to the custom paint widget
    final backgroundPath = Path()..addRect(Rect.largest);

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    // First, draw the background,
    // with a cutout area that is a bit larger than the scan window.
    // Finally, draw the scan window itself.
    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
        borderRadius != oldDelegate.borderRadius;
  }
}
