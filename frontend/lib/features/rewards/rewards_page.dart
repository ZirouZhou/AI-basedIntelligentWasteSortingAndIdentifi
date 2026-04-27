import 'package:flutter/material.dart';

import '../../core/models/eco_reward_models.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_theme.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  late final ApiClient _apiClient;
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _successMessage;

  EcoDashboard? _dashboard;
  List<EcoActionCatalogItem> _catalog = const [];
  List<EcoActionRecord> _history = const [];
  List<BadgeItem> _badges = const [];

  String? _selectedCatalogId;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _quantityController = TextEditingController(text: '1');
    _noteController = TextEditingController();
    _loadAll();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _apiClient.fetchEcoDashboard(userId: widget.userId),
        _apiClient.fetchEcoActionCatalog(),
        _apiClient.fetchEcoActionHistory(userId: widget.userId, limit: 20),
        _apiClient.fetchBadges(userId: widget.userId),
      ]);

      final dashboard = results[0] as EcoDashboard;
      final catalog = results[1] as List<EcoActionCatalogItem>;
      final history = results[2] as List<EcoActionRecord>;
      final badges = results[3] as List<BadgeItem>;

      setState(() {
        _dashboard = dashboard;
        _catalog = catalog;
        _history = history;
        _badges = badges;
        _selectedCatalogId = _selectedCatalogId ?? (catalog.isNotEmpty ? catalog.first.id : null);
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _evaluateAction() async {
    final selected = _selectedCatalogId;
    final quantity = double.tryParse(_quantityController.text.trim());
    if (selected == null) {
      setState(() => _error = 'Please select an eco action type.');
      return;
    }
    if (quantity == null || quantity <= 0) {
      setState(() => _error = 'Quantity must be a positive number.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final result = await _apiClient.evaluateEcoAction(
        userId: widget.userId,
        catalogActionId: selected,
        quantity: quantity,
        note: _noteController.text.trim(),
      );
      _quantityController.text = '1';
      _noteController.clear();
      setState(() {
        _successMessage =
            'Evaluated successfully: -${result.record.co2ReductionKg.toStringAsFixed(2)} kg CO2, +${result.record.pointsAwarded} points.';
      });
      await _loadAll();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _redeemBadge(BadgeItem badge) async {
    setState(() {
      _submitting = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final result = await _apiClient.redeemBadge(
        userId: widget.userId,
        badgeId: badge.id,
      );
      setState(() {
        _successMessage =
            'Badge redeemed: ${result.badge.title}. Remaining points: ${result.newPointsBalance}.';
      });
      await _loadAll();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Eco Assessment & Rewards', style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Estimate CO2 reduction from your eco behavior, earn points, and redeem badges.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _MessageBanner(
            color: const Color(0xFFFBEAEA),
            icon: Icons.error_outline,
            message: _error!,
          ),
        ],
        if (_successMessage != null) ...[
          const SizedBox(height: 10),
          _MessageBanner(
            color: const Color(0xFFE7F7ED),
            icon: Icons.check_circle_outline,
            message: _successMessage!,
          ),
        ],
        const SizedBox(height: 16),
        _buildDashboard(textTheme),
        const SizedBox(height: 22),
        _buildEvaluationCard(textTheme),
        const SizedBox(height: 22),
        _buildBadges(textTheme),
        const SizedBox(height: 22),
        _buildHistory(textTheme),
      ],
    );
  }

  Widget _buildDashboard(TextTheme textTheme) {
    final dashboard = _dashboard;
    return Card(
      color: AppTheme.moss,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Green Dashboard',
              style: textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 14),
            if (dashboard == null)
              Text(
                'Loading dashboard...',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatChip(label: 'Points', value: '${dashboard.currentPoints}'),
                  _StatChip(
                    label: 'CO2 Reduced',
                    value: '${dashboard.totalCo2ReductionKg.toStringAsFixed(2)} kg',
                  ),
                  _StatChip(label: 'Evaluations', value: '${dashboard.totalEvaluations}'),
                  _StatChip(label: 'Badges', value: '${dashboard.badgesRedeemed}'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationCard(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evaluate Eco Action', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCatalogId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Action type',
                border: OutlineInputBorder(),
              ),
              items: _catalog
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.title} (${item.unitLabel})'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _selectedCatalogId = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              enabled: !_submitting,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _submitting ? null : _evaluateAction,
              icon: const Icon(Icons.calculate),
              label: Text(_submitting ? 'Submitting...' : 'Evaluate & Award Points'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badge Exchange', style: textTheme.titleLarge),
        const SizedBox(height: 10),
        if (_badges.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No badge items available.'),
            ),
          )
        else
          ..._badges.map(
            (badge) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.sky,
                      child: Text(badge.icon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(badge.title, style: textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(badge.description, style: textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            badge.redeemed
                                ? 'Redeemed${badge.redeemedAt != null ? ' at ${badge.redeemedAt}' : ''}'
                                : 'Requires ${badge.requiredPoints} points',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (badge.redeemed)
                      const Chip(label: Text('Owned'))
                    else
                      FilledButton(
                        onPressed: (!badge.redeemable || _submitting)
                            ? null
                            : () => _redeemBadge(badge),
                        child: const Text('Redeem'),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistory(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evaluation History', style: textTheme.titleLarge),
        const SizedBox(height: 10),
        if (_history.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No evaluated eco actions yet.'),
            ),
          )
        else
          ..._history.map(
            (record) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.sky,
                  child: Icon(Icons.eco, color: AppTheme.seed),
                ),
                title: Text(record.actionTitle),
                subtitle: Text(
                  '${record.quantity.toStringAsFixed(2)} ${record.unitLabel} · '
                  '-${record.co2ReductionKg.toStringAsFixed(2)} kg CO2 · ${record.createdAt}',
                ),
                trailing: Text(
                  '+${record.pointsAwarded}',
                  style: textTheme.titleMedium?.copyWith(color: AppTheme.seed),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
