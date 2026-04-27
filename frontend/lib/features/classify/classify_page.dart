import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/waste_category.dart';
import '../../core/services/api_client.dart';
import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';

class ClassifyPage extends StatefulWidget {
  const ClassifyPage({super.key});

  @override
  State<ClassifyPage> createState() => _ClassifyPageState();
}

class _ClassifyPageState extends State<ClassifyPage> {
  final _apiClient = ApiClient();
  final _controller = TextEditingController(text: 'Plastic bottle');
  final _imagePicker = ImagePicker();
  ClassificationResult? _result = MockData.demoClassification;
  bool _isClassifying = false;
  String? _statusMessage;
  String? _selectedImageName;

  @override
  void dispose() {
    _apiClient.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _classify() async {
    final itemName = _controller.text.trim();
    if (itemName.isEmpty) {
      return;
    }

    setState(() {
      _isClassifying = true;
      _statusMessage = null;
    });

    try {
      final result = await _apiClient.classifyWaste(itemName);
      if (!mounted) {
        return;
      }
      setState(() => _result = result);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _result = _classifyLocally(itemName);
        _statusMessage =
            'Backend is not available. Showing a local demo result instead.';
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
    setState(() {
      _isClassifying = true;
      _statusMessage = null;
    });

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isClassifying = false;
          _statusMessage = 'No image selected.';
        });
        return;
      }

      final bytes = await picked.readAsBytes();
      final result = await _apiClient.classifyWasteImage(
        imageBytes: bytes,
        fileName: picked.name,
        submittedBy: 'u1',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImageName = picked.name;
        _result = result;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage =
            'Image recognition failed. Please check backend and Aliyun credentials.';
      });
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }

  ClassificationResult _classifyLocally(String itemName) {
    final lower = itemName.toLowerCase();
    final category = lower.contains('battery') || lower.contains('medicine')
        ? MockData.categories[2]
        : lower.contains('food') || lower.contains('banana')
            ? MockData.categories[1]
            : lower.contains('tissue') || lower.contains('ceramic')
                ? MockData.categories[3]
                : MockData.categories[0];

    return ClassificationResult(
      itemName: itemName,
      category: category,
      confidence: 0.91,
      suggestions: category.recyclingTips,
    );
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
          'Upload or describe an item to identify the correct waste category.',
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
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Item name',
            hintText: 'Example: plastic bottle, banana peel, battery',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
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
          ],
        ),
      ),
    );
  }
}
