import 'package:flutter/material.dart';
import 'package:flutter_pos/widgets/scanner_overlay_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerDialog extends ConsumerStatefulWidget {
  const BarcodeScannerDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<BarcodeScannerDialog> createState() =>
      _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends ConsumerState<BarcodeScannerDialog> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сканировать штрих-код'),
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.all(10),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double parentWidth = constraints.maxWidth;
            final double parentHeight = constraints.maxHeight;
            // Делаем окно сканирования квадратным, ~60-70% от меньшей стороны
            final double scanWindowSize =
                (parentWidth < parentHeight ? parentWidth : parentHeight) * 0.7;

            final Offset center = Offset(parentWidth / 2, parentHeight / 2);

            final scanWindow = Rect.fromCenter(
              center: center,
              width: scanWindowSize,
              height: scanWindowSize, // Квадратное окно
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: MobileScanner(
                    controller: controller,
                    scanWindow: scanWindow,
                    onDetect: (capture) {
                      if (_isProcessing) return;

                      final List<Barcode> barcodes = capture.barcodes;
                      String? scannedValue;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null &&
                            barcode.rawValue!.isNotEmpty) {
                          scannedValue = barcode.rawValue;
                          break;
                        }
                      }

                      if (scannedValue != null) {
                        setState(() {
                          _isProcessing = true;
                        });
                        Navigator.of(context).pop(scannedValue);
                      }
                    },
                    errorBuilder: (context, error, child) {
                      print('Scanner Error: $error');

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Ошибка сканера:\n${error.toString()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                CustomPaint(
                  size: Size(
                    parentWidth,
                    parentHeight,
                  ), // Явно указываем размер
                  painter: ScannerOverlayPainter(
                    scanWindow: scanWindow,
                  ), // Передаем рассчитанное окно
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: IconButton(
                    color: Colors.white,
                    iconSize: 32.0,
                    icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
                    tooltip: 'Фонарик',
                    onPressed: () async {
                      try {
                        await controller.toggleTorch();

                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      } catch (e) {
                        print("Failed to toggle torch: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Не удалось переключить фонарик: $e',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: IconButton(
                    color: Colors.white,
                    iconSize: 32.0,
                    icon: const Icon(Icons.cameraswitch),
                    tooltip: 'Сменить камеру',
                    onPressed: () async {
                      try {
                        await controller.switchCamera();
                      } catch (e) {
                        print("Failed to switch camera: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Не удалось сменить камеру: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),

      actions: [
        TextButton(
          child: const Text('Отмена'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
