import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:escaner_qr/scanned_barcode_label.dart';
import 'package:escaner_qr/scanner_button_widgets.dart';
import 'package:escaner_qr/scanner_error_widget.dart';
import 'result_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BarcodeScannerWithOverlay extends StatefulWidget {
  @override
  _BarcodeScannerWithOverlayState createState() =>
      _BarcodeScannerWithOverlayState();
}

class _BarcodeScannerWithOverlayState extends State<BarcodeScannerWithOverlay> {
  
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _isNavigating = false;
  String _lastScannedData = '';

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
                  await validarYNavegar(context, qrData, () {
                    setState(() {
                      _isNavigating = false;
                    });
                  });
                  controller.start();
                  await Future.delayed(const Duration(seconds: 2));
                  // if (qrData != _lastScannedData) {
                  //   _lastScannedData = qrData;
                  //   _isNavigating = true;
                  //   controller.stop();
                  //   await validarYNavegar(context, qrData, () {
                  //     setState(() {
                  //       _isNavigating = false;
                  //     });
                  //   });
                  //   controller.start();
                  //   await Future.delayed(const Duration(seconds: 2));
                  // }
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

Future<void> validarYNavegar(BuildContext context, String qrData, VoidCallback onComplete) async {
  try {
    final validacionResponse = await http.get(
      Uri.parse('https://ventas-productos-pvamp.000webhostapp.com/validar-qr.php?data=$qrData'),
    );

    if (validacionResponse.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(qrData: qrData),
        ),
      ).then((_) {
        onComplete();
      });
    } else {
      _showDialog(context, 'Error', 'QR no válido', Colors.red, Icons.error_outline);
      await Player.play('audio/wrong-sound.mp3');
      onComplete();
    }
  } catch (error) {
    _showDialog(context, 'Error', 'Error al validar el QR: $error', Colors.red, Icons.error);
    await Player.play('audio/wrong-sound.mp3');
    // await Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
    onComplete();
  }
}

void _showDialog(BuildContext context, String title, String message, Color? backgroundColor, IconData icon) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
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
        backgroundColor: backgroundColor ?? Colors.white,
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
    return scanWindow != oldDelegate.scanWindow ||
        borderRadius != oldDelegate.borderRadius;
  }
}