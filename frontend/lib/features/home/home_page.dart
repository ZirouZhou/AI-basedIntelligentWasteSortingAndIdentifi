import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/models/weather_info.dart';
import '../../core/services/api_client.dart';
import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';

/// Home page dashboard.
///
/// Adds a UK weather section powered by AMap weather API.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiClient _apiClient;
  Future<WeatherInfo>? _weatherFuture;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _weatherFuture = _apiClient.fetchUkLiveWeather();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = _apiClient.fetchUkLiveWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('EcoSort AI', style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Identify waste instantly, build greener habits, and connect with a low-carbon community.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3D2E), Color(0xFF2EAD72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco, size: 42, color: Colors.white),
              const SizedBox(height: 18),
              Text(
                'Today is a good day to sort smarter.',
                style: textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Scan an item, learn the correct bin, and earn points for every verified eco action.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<WeatherInfo>(
          future: _weatherFuture,
          builder: (context, snapshot) {
            return _WeatherCard(
              snapshot: snapshot,
              onRefresh: _refreshWeather,
            );
          },
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Green Score',
                value: '836',
                icon: Icons.trending_up,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Recycled',
                value: '48.5 kg',
                icon: Icons.recycling,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Sorting Guide', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        ...MockData.categories.map(
          (category) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor: AppTheme.sky,
                child: Text(category.binColor.substring(0, 1)),
              ),
              title: Text(category.title),
              subtitle: Text(category.description),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.snapshot,
    required this.onRefresh,
  });

  final AsyncSnapshot<WeatherInfo> snapshot;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Loading live weather for ${AppConfig.ukWeatherCountryLabel}...',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      final message = snapshot.error is WeatherNoDataException
          ? (snapshot.error as WeatherNoDataException).message
          : 'Unable to load weather right now.';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_off, color: Color(0xFF8A5A2B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppConfig.ukWeatherCountryLabel} Live Weather',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh weather',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(message, style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                'Source: AMap Weather API',
                style: textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    final weather = snapshot.data;
    if (weather == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E5C7B), Color(0xFF3E9FC6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppConfig.ukWeatherCountryLabel} Live Weather',
                    style: textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh weather',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              weather.locationName,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              '${weather.temperatureCelsius}°C  •  ${weather.weather}',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _WeatherChip(label: 'Humidity', value: '${weather.humidityPercent}%'),
                _WeatherChip(
                  label: 'Wind',
                  value: '${weather.windDirection} ${weather.windPower}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reported at ${weather.reportTime} (AMap)',
              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '$label: $value',
        style: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.seed),
            const SizedBox(height: 14),
            Text(value, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
