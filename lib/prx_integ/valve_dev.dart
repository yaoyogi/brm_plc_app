class ValveDev {
  //
  // Construction
  //
  ValveDev(String id, bool initialState, String desc) {
    _id = id ;
    _state = initialState ;
    _desc = desc ;
  }

  //
  // State
  //
  String _id ;
  bool _state ;
  String _desc ;

  //
  // API
  //
  String get id {
    return _id ;
  }

  bool get state {
    return _state ;
  }

  set state(bool v) {
    _state = v ;
  }

  String get desc {
    return _desc ;
  }

  //
  // Override(s)
  //
  @override
  String toString() {
    return _id + ':' + (_state ? 'on' : 'off') + '(' + _desc + ')\n' ;
  }
}