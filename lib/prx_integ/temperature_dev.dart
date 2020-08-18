class TemperatureDev {
  String _id ;
  String _desc ;

  double _fahrenheit ;
  double _min_fahrenheit ;
  double _max_fahrenheit ;

  //
  // Construction
  //
  TemperatureDev(String id, double initialFahrenheit, double minFahrenheit, double maxFahrenheit, String desc) {
    _id = id ;
    _fahrenheit = initialFahrenheit ;
    _min_fahrenheit = minFahrenheit ;
    _max_fahrenheit = maxFahrenheit ;
    _desc = desc ;
  }

  //
  // API
  //
  String get id {
    return _id ;
  }

  double get fahrenheit {
    return _fahrenheit ;
  }

  set fahrenheit(double v) {
    _fahrenheit = v ;
  }

  double get minFahrenheit {
    return _min_fahrenheit ;
  }

  double get maxFahrenheit {
    return _max_fahrenheit ;
  }

  String get desc {
    return _desc ;
  }

  //
  // Overrides
  //
  @override
  String toString() {
    return '_id: $_id $fahrenheit [$_min_fahrenheit .. $_max_fahrenheit] ($_desc)\n' ;
  }
}