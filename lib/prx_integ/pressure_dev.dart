class PressureDev {
  String _id ;
  String _desc ;

  double _psi ;
  double _min_psi ;
  double _max_psi ;

  //
  // Construction
  //
  PressureDev(String id, double initialPsi, double minPsi, double maxPsi, String desc) {
    _id = id ;
    _psi = initialPsi ;
    _min_psi = minPsi ;
    _max_psi = maxPsi ;
    _desc = desc ;
  }

  //
  // API
  //
  String get id {
    return _id ;
  }

  double get psi {
    return _psi ;
  }

  set psi(double v) {
    _psi = v ;
  }

  double get minPsi {
    return _min_psi ;
  }

  double get maxPsi {
    return _max_psi ;
  }

  String get desc {
    return _desc ;
  }

  //
  // Overrides
  //
  @override
  String toString() {
    return '_id: $_id $_psi [$_min_psi .. $_max_psi] ($_desc)\n' ;
  }
}