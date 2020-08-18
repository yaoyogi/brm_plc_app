class DevWithSettings {

  bool _state ;
  int _setting ;

  int get setting {
    return _setting ;
  }

  set setting(int v) {
    _setting = v ;
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
}