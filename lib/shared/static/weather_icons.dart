class WeatherIcons {
  static const Map<String, String> _icons = {
    "1": "assets/weather/1.png",
    "2": "assets/weather/2.png",
    "3": "assets/weather/3.png",
    "4": "assets/weather/4.png",
    "5": "assets/weather/5.png",
    "6": "assets/weather/6.png",
    "7": "assets/weather/7.png",
    "8": "assets/weather/8.png",
    "9": "assets/weather/9.png",
  };

  static String getIcon(String code) {
    return _icons[code] ?? "assets/weather/1.png"; // fallback
  }
}
