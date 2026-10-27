// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:mobile/core/utils/error_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../data/scanner_repository.dart';
import 'package:mobile/features/user/data/user_repository.dart';
import '../widgets/analyzing_loading_view.dart';

import 'package:mobile/core/services/scan_notification_manager.dart';

class OcrScannerScreen extends ConsumerStatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  ConsumerState<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends ConsumerState<OcrScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  double _progress = 0.0;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      
      if (photo != null) {
        setState(() {
          _isProcessing = true;
          _progress = 0.1;
        });

        final repo = ref.read(scannerRepositoryProvider);
        final extractedText = await repo.extractTextFromImage(photo.path);
        
        setState(() {
          _progress = 0.4;
        });
        
        // Start a fake progress timer so the bar moves while waiting for AI
        Timer? progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (mounted && _progress < 0.95) {
            setState(() {
              _progress += 0.05;
            });
          }
        });
        
        final response = await repo.sendOcrTextToBackend(extractedText);
        
        // Invalidate scan history so Dashboard and Scan History screens update
        ref.invalidate(scanHistoryProvider);

        progressTimer.cancel();
        if (mounted) {
          setState(() {
            _progress = 1.0;
          });
          // Small delay to let the user see the bar complete
          await Future.delayed(const Duration(milliseconds: 300));
        }

        if (mounted) {
          if (response != null) {
            ScanNotificationManager.instance.evaluateAndNotify(response);
            context.push('/result', extra: response);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to analyze ingredients.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.getReadableMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Scan Ingredients'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Center(
        child: _isProcessing
            ? AnalyzingLoadingView(progress: _progress)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner, size: 80, color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(height: 24),
                  const Text(
                    'Point your camera at the ingredient label\nor upload an image from your gallery',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 48),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(220, 50),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Open Camera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      minimumSize: const Size(220, 50),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload from Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
      ),
    );
  }
}
