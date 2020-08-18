class SwitchDev {
  //
  // Construction
  //
  SwitchDev(String id, bool initialState, String desc) {
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

  turnOn() {
    _state = true ;
  }
  turnOff() {
    _state = false ;
  }

  bool toggle() {
    if (_state) {
      turnOff() ;
      return false ;
    }

    turnOn() ;
    return true ;
  }

  bool get isOn {
    return _state == true ;
  }

  bool get isOff {
    return ! isOn ;
  }

  //
  // Override(s)
  //
  @override
  String toString() {
    return _id + ':' + (_state ? 'on' : 'off') + '(' + _desc + ')\n' ;
  }
}