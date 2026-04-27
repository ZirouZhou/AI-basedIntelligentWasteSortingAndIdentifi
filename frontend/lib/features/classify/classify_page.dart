import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/waste_category.dart';
import '../../core/services/api_client.dart';
import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';

class ClassifyPage extends StatefulWidget {
  const ClassifyPage({
    super.key,
    required this.userId,
    this.onClassificationSuccess,
  });

  final String userId;
  final VoidCallback? onClassificationSuccess;

  @override
  State<ClassifyPage> createState() => _ClassifyPageState();
}

class _ClassifyPageState extends State<ClassifyPage> {
  final _apiClient = ApiClient();
  final _imagePicker = ImagePicker();
  ClassificationResult? _result = MockData.demoClassification;
  bool _isClassifying = false;
  String? _statusMessage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _classify() async {
    final selectedImageBytes = _selectedImageBytes;
    final selectedImageName = _selectedImageName;
    if (selectedImageBytes == null || selectedImageName == null) {
      setState(() {
        _statusMessage = 'Please select an image first.';
      });
      return;
    }

    setState(() {
      _isClassifying = true;
      _statusMessage = null;
    });

    try {
      final result = await _apiClient.classifyWasteImage(
        imageBytes: selectedImageBytes,
        fileName: selectedImageName,
        submittedBy: widget.userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _statusMessage = 'Image classified successfully.';
      });
      widget.onClassificationSuccess?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Image recognition failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }

  Future<void> _classifyFromCamera() async {
    await _classifyFromSource(ImageSource.camera);
  }

  Future<void> _classifyFromGallery() async {
    await _classifyFromSource(ImageSource.gallery);
  }

  Future<void> _classifyFromSource(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
        _statusMessage =
            'Image selected: ${picked.name}. Tap "Start AI Classification".';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Failed to select image. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('AI Waste Classification', style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Upload a photo to identify the correct waste category.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white,
            border: Border.all(color: AppTheme.sky, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppTheme.sky,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  size: 42,
                  color: AppTheme.seed,
                ),
              ),
              const SizedBox(height: 16),
              Text('Image Classification', style: textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Take a photo or pick one from gallery.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isClassifying ? null : _classifyFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isClassifying ? null : _classifyFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isClassifying ? null : _classify,
          icon: _isClassifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(
            _isClassifying ? 'Classifying...' : 'Start AI Classification',
          ),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _statusMessage!,
            style: textTheme.bodyMedium?.copyWith(color: Colors.orange[800]),
          ),
        ],
        if (_selectedImageName != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last image: $_selectedImageName',
            style: textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        if (_result != null) _ClassificationCard(result: _result!),
      ],
    );
  }
}

class _ClassificationCard extends StatelessWidget {
  const _ClassificationCard({required this.result});

  final ClassificationResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.sky,
                  child: Icon(Icons.check, color: AppTheme.seed),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.category.title, style: textTheme.titleLarge),
                      Text(
                        'Confidence ${(result.confidence * 100).toStringAsFixed(0)}%',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Identified Item', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(result.identifiedItem),
            const SizedBox(height: 18),
            Text('British Standard', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(result.englandCategoryName),
            const SizedBox(height: 6),
            Text('Recommended Bin: ${result.ukDisposalBin}'),
            const SizedBox(height: 18),
            Text('Recommended Bin', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('${result.category.binColor} bin'),
            const SizedBox(height: 18),
            Text('Sorting Suggestions', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            ...result.suggestions.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.eco, size: 18, color: AppTheme.seed),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            ),
            if (result.ukDisposalTips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('UK Disposal Tips', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              ...result.ukDisposalTips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.public, size: 18, color: AppTheme.seed),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
