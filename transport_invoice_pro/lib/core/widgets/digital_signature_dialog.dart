import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';

class DigitalSignatureDialog extends StatefulWidget {
  const DigitalSignatureDialog({super.key});

  @override
  State<DigitalSignatureDialog> createState() => _DigitalSignatureDialogState();
}

class _DigitalSignatureDialogState extends State<DigitalSignatureDialog> {
  final List<Offset?> _points = [];
  bool _isSaving = false;

  Future<void> _saveSignature() async {
    final validPoints = _points.whereType<Offset>().toList();
    if (_points.isEmpty || validPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(const Offset(0, 0), const Offset(400, 200)),
      );

      // Draw white background
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 400, 200),
        Paint()..color = Colors.white,
      );

      final paint = Paint()
        ..color = Colors.black
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 200);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        
        // Encode as Base64 Data URL for cross-platform reliability
        final base64String = 'data:image/png;base64,${base64Encode(buffer)}';

        // Also attempt saving to local disk if supported
        try {
          final tempDir = await getApplicationDocumentsDirectory();
          final filePath = '${tempDir.path}/sig_${const Uuid().v4()}.png';
          final file = File(filePath);
          await file.writeAsBytes(buffer);
        } catch (_) {}

        if (mounted) {
          Navigator.pop(context, base64String);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving signature: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Draw Signature'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sign inside the box below with finger or mouse:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              width: 400,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue, width: 2.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GestureDetector(
                  onPanDown: (details) {
                    final pos = details.localPosition;
                    if (pos.dx >= 0 && pos.dx <= 400 && pos.dy >= 0 && pos.dy <= 200) {
                      setState(() {
                        _points.add(pos);
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    final pos = details.localPosition;
                    if (pos.dx >= 0 && pos.dx <= 400 && pos.dy >= 0 && pos.dy <= 200) {
                      setState(() {
                        _points.add(pos);
                      });
                    } else {
                      if (_points.isNotEmpty && _points.last != null) {
                        setState(() {
                          _points.add(null);
                        });
                      }
                    }
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _points.add(null);
                    });
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(points: _points),
                    size: const Size(400, 200),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.clear_rounded),
          label: const Text('Clear'),
          onPressed: () => setState(() => _points.clear()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_rounded),
          label: const Text('Save Signature'),
          onPressed: _isSaving ? null : _saveSignature,
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
