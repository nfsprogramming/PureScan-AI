// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/scanner_repository.dart';
import 'package:mobile/features/user/data/user_repository.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first.rawValue;
      if (barcode != null) {
        setState(() {
          _isProcessing = true;
        });
        
        // Stop scanning while processing
        _controller.stop();
        
        final repo = ref.read(scannerRepositoryProvider);
        final response = await repo.sendBarcodeToBackend(barcode);
        
        // Invalidate scan history so Dashboard and Scan History screens update
        ref.invalidate(scanHistoryProvider);
        
        if (!mounted) return;

        if (response != null && response['status'] == 'not_found') {
          // Product not found, prompt for contribution
          _showContributeDialog(barcode);
        } else if (response != null && response['status'] == 'found') {
          // Found!
          final product = response['product'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found: ${product['name']}')),
          );
          Navigator.pop(context);
        } else {
          // Error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error scanning barcode')),
          );
          setState(() {
            _isProcessing = false;
          });
          _controller.start();
        }
      }
    }
  }

  void _showContributeDialog(String barcode) {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Product Not Found'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Would you like to share this product with our team?'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () {
                    Navigator.pop(context);
                    setState(() {
                      _isProcessing = false;
                    });
                    _controller.start();
                  },
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (nameController.text.trim().isEmpty) return;
                    
                    setDialogState(() => isSubmitting = true);
                    
                    final repo = ref.read(scannerRepositoryProvider);
                    final success = await repo.submitContribution(barcode, nameController.text.trim());
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Thank you for contributing!' : 'Failed to submit.')),
                      );
                      Navigator.pop(context); // Go back to dashboard
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.onSurface, foregroundColor: Colors.white),
                  child: isSubmitting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2)) : Text('Submit'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Product Barcode'),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface),
            ),
        ],
      ),
    );
  }
}
