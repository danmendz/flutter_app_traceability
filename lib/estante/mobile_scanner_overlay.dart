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
  final String? selectedEstanteId;
  const BarcodeScannerWithOverlay({Key? key, this.selectedEstanteId}) : super(key: key);

  @override
  _BarcodeScannerWithOverlayState createState() => 
      _BarcodeScannerWithOverlayState();
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
              onDetect: (capture) async {
                if (!_isNavigating) {
                  final String qrData = capture.barcodes.first.displayValue ?? 'Información no obtenida.';
                  _isNavigating = true;
                  controller.stop();
                  await validarYEnviarDatos(context, widget.selectedEstanteId ?? "", qrData, () {
                    setState(() {
                      _isNavigating = false;
                    });
                  });
                  controller.start();
                  await Future.delayed(const Duration(seconds: 2));
                }
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              if (!value.isInitialized || !value.isRunning || value.error != null) {
                return const SizedBox();
              }

              return CustomPaint(
                painter: ScannerOverlay(scanWindow: scanWindow),
              );
            },
          ),
          Positioned(
            top: 16.0,
            left: 0,
            right: 0,
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

Future<void> validarYEnviarDatos(BuildContext context, String selectedId, String qrData, VoidCallback onComplete) async {
  try {
    final validacionResponse = await http.get(
      Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/validar-qr.php?data=$qrData'),
    );

    if (validacionResponse.statusCode == 200) {
      final response = await http.post(
        Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/insertar-reporte-estante.php?datos=$qrData&id_estante=$selectedId'),
        body: json.encode({'selectedId': selectedId, 'data': qrData}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _showDialog(context, 'Éxito', 'Datos registrados exitosamente', Colors.green, Icons.check_circle);
        await Player.play('audio/correct-sound.mp3');
      } else if (response.statusCode == 402) {
        _showDialog(context, '¡Advertencia!', 'Mismos datos registrados en menos de 2 minutos', Colors.yellow, Icons.warning);
        await Player.play('audio/wrong-sound.mp3');
      } else {
        _showDialog(context, 'Error', 'Error al enviar los datos escaneados: ${response.reasonPhrase}', Colors.red, Icons.error_outline);
        await Player.play('audio/wrong-sound.mp3');
      }
    } else {
      _showDialog(context, 'Error', 'QR no válido', Colors.red, Icons.error_outline);
      await Player.play('audio/wrong-sound.mp3');
    }
  } catch (error) {
    _showDialog(context, 'Error', 'Error al validar/enviar los datos: $error', Colors.red, Icons.error);
    await Player.play('audio/wrong-sound.mp3');
    // await Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
  } finally {
    onComplete();
  }
}

void _showDialog(BuildContext context, String title, String message, Color? backgroundColor, IconData icon) {
  showDialog(
    context: context,
    barrierDismissible: true,
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

class ScannerOverlay extends CustomPainter {
  const ScannerOverlay({
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
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

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) {
    return scanWindow != oldDelegate.scanWindow || borderRadius != oldDelegate.borderRadius;
  }
}