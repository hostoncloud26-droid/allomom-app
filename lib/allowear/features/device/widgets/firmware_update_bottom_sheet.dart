import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class FirmwareUpdateBottomSheet extends StatefulWidget {
  const FirmwareUpdateBottomSheet({super.key});

  @override
  State<FirmwareUpdateBottomSheet> createState() =>
      _FirmwareUpdateBottomSheetState();
}

class _FirmwareUpdateBottomSheetState extends State<FirmwareUpdateBottomSheet> {
  String? _selectedFilePath;
  String? _selectedFileName;
  double _progress = 0;
  String _status = 'Idle';
  bool _isUpdating = false;
  StreamSubscription? _progressSubscription;

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin', 'zip'],
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
          _status = 'File Selected';
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick file: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _startUpdate() {
    if (_selectedFilePath == null) return;

    setState(() {
      _isUpdating = true;
      _status = 'Syncing...';
      _progress = 0;
    });

    _progressSubscription = allowear.firmwareUpdateProgress.listen((event) {
      final status = event['status'] as String;
      
      if (status == 'progress') {
        final progress = (event['progress'] as num).toDouble();
        setState(() {
          _progress = progress;
        });
      } else if (status == 'completed') {
        setState(() {
          _isUpdating = false;
          _status = 'Finished';
          _progress = 1.0;
        });
        Get.snackbar('Success', 'Firmware updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } else if (status == 'failed') {
        final error = event['error'] ?? 'Unknown error';
        setState(() {
          _isUpdating = false;
          _status = 'Failed (Error: $error)';
        });
        Get.snackbar('Update Failed', 'Firmware update failed: $error',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    }, onError: (error) {
      setState(() {
        _isUpdating = false;
        _status = 'Error: $error';
      });
    });

    allowear.startFirmwareUpgrade(_selectedFilePath!).catchError((e) {
      setState(() {
        _isUpdating = false;
        _status = 'Error starting upgrade';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);

    return PopScope(
      canPop: !_isUpdating,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Firmware Update (OTA)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Black800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The OTA update file must be obtained from the manufacturer and tested thoroughly before proceeding.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // File Selection Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  if (_selectedFileName != null) ...[
                    Icon(Icons.description_rounded,
                        color: primaryColor, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFileName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFilePath!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const Icon(Icons.file_upload_outlined,
                        color: Colors.grey, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'No file selected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUpdating ? null : _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      elevation: 0,
                      side: BorderSide(color: primaryColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_selectedFileName == null
                        ? 'Select OTA File'
                        : 'Change File'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Progress Area
            if (_isUpdating || _progress > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: $_status',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Action Button
            ElevatedButton(
              onPressed: (_isUpdating || _selectedFilePath == null)
                  ? null
                  : _startUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Start Upgrade',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isUpdating ? null : () => Get.back(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.withOpacity(0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
