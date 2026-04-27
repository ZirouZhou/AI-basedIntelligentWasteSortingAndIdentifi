/// Weather data shown on the home page.
class WeatherInfo {
  const WeatherInfo({
    required this.locationName,
    required this.weather,
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.windDirection,
    required this.windPower,
    required this.reportTime,
  });

  final String locationName;
  final String weather;
  final String temperatureCelsius;
  final String humidityPercent;
  final String windDirection;
  final String windPower;
  final String reportTime;
}
