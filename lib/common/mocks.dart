
import 'dart:typed_data';  // Uint8List
import 'package:binary/binary.dart';
import 'package:brmplcapp/brm_json/brm_json_util.dart';  // BinaryInt type

import 'package:brmplcapp/prx_integ/prx_aggr.dart';

class PressureMock {
  PressureMock(String id, double v, bool active, double min, double max) {
    this.id = id ;
    this.v = v ;
    this.active = active ;
    this.min = min ;
    this.max = max ;
  }

  String id ;
  double v ;
  bool active ;

  double min ;
  double max ;

  @override
  String toString() {
    return '$id: $v [$min .. $max], active: $active' ;
  }
}

class TemperatureMock {
  TemperatureMock(String id, double v, bool active, double min, double max) {
    this.id = id ;
    this.v = v ;
    this.active = active ;
    this.min = min ;
    this.max = max ;
  }

  String id ;
  double v ;
  bool active ;

  double min ;
  double max ;

  @override
  String toString() {
    return '$id: $v [$min .. $max], active: $active' ;
  }
}

class BinarySwitchMock {
  BinarySwitchMock(String id, bool initialValue, bool active) {
    this.id = id ;
    this.v = initialValue ;
    this.active = active ;
  }

  String id ;
  bool v ;
  bool active ;

  @override
  String toString() {
    return '$id: $v, active: $active' ;
  }
}

class MockBunch {
  TemperatureMock temperature_1_mock  ;
  TemperatureMock temperature_2_mock  ;
  TemperatureMock temperature_3_mock  ;
  TemperatureMock temperature_5_mock  ;
  TemperatureMock temperature_6_mock  ;

  PressureMock pressure_1_mock ;
  PressureMock pressure_2_mock ;
  PressureMock pressure_3_mock ;
  PressureMock pressure_4_mock ;

  BinarySwitchMock sw_flow_mock = BinarySwitchMock("sw_flow", false, false) ;
  BinarySwitchMock sw_power_loss_mock = BinarySwitchMock("sw_power_loss", false, false) ;
  BinarySwitchMock sw_emergency_shutdown_mock = BinarySwitchMock("sw_emergency_shutdown", false, false) ;
  BinarySwitchMock sw_4_mock = BinarySwitchMock("sw_4", false, false) ;
  BinarySwitchMock sw_5_mock = BinarySwitchMock("sw_5", false, false) ;
  BinarySwitchMock sw_6_mock = BinarySwitchMock("sw_6", false, false) ;
  BinarySwitchMock sw_7_mock = BinarySwitchMock("sw_7", false, false) ;
  BinarySwitchMock sw_8_mock = BinarySwitchMock("sw_8", false, false) ;

  MockBunch(PrxAggr aggr) {
    temperature_1_mock = TemperatureMock("temperature_1", 0.0, false, aggr.temp_1.minFahrenheit, aggr.temp_1.maxFahrenheit) ;
    temperature_2_mock = TemperatureMock("temperature_2", 0.0, false, aggr.temp_2.minFahrenheit, aggr.temp_2.maxFahrenheit) ;
    temperature_3_mock = TemperatureMock("temperature_3", 0.0, false, aggr.temp_3.minFahrenheit, aggr.temp_3.maxFahrenheit) ;
    temperature_5_mock = TemperatureMock("temperature_5", 0.0, false, aggr.temp_5.minFahrenheit, aggr.temp_5.maxFahrenheit) ;
    temperature_6_mock = TemperatureMock("temperature_6", 0.0, false, aggr.temp_6.minFahrenheit, aggr.temp_6.maxFahrenheit) ;

    pressure_1_mock = PressureMock("pressure_1", 0.0, false, aggr.pressure_1.minPsi, aggr.pressure_1.maxPsi) ;
    pressure_2_mock = PressureMock("pressure_2", 0.0, false, aggr.pressure_2.minPsi, aggr.pressure_2.maxPsi) ;
    pressure_3_mock = PressureMock("pressure_3", 0.0, false, aggr.pressure_3.minPsi, aggr.pressure_3.maxPsi) ;
    pressure_4_mock = PressureMock("pressure_4", 0.0, false, aggr.pressure_4.minPsi, aggr.pressure_4.maxPsi) ;

    BinarySwitchMock sw_flow_mock = BinarySwitchMock("sw_flow", false, false) ;
    BinarySwitchMock sw_power_loss_mock = BinarySwitchMock("sw_power_loss", false, false) ;
    BinarySwitchMock sw_emergency_shutdown_mock = BinarySwitchMock("sw_emergency_shutdown", false, false) ;
    BinarySwitchMock sw_4_mock = BinarySwitchMock("sw_4", false, false) ;
    BinarySwitchMock sw_5_mock = BinarySwitchMock("sw_5", false, false) ;
    BinarySwitchMock sw_6_mock = BinarySwitchMock("sw_6", false, false) ;
    BinarySwitchMock sw_7_mock = BinarySwitchMock("sw_7", false, false) ;
    BinarySwitchMock sw_8_mock = BinarySwitchMock("sw_8", false, false) ;
  }

//  TemperatureMock temperature_1_mock = TemperatureMock("temperature_1", 0.0, false, aggr.temp_1.minFahrenheit, 300) ;
//
//  TemperatureMock temperature_1_mock = TemperatureMock("temperature_1", 0.0, false, 0, 300) ;
//  TemperatureMock temperature_2_mock = TemperatureMock("temperature_2", 0.0, false, 0, 300) ;
//  TemperatureMock temperature_3_mock = TemperatureMock("temperature_3", 0.0, false, 0, 300) ;
//  TemperatureMock temperature_5_mock = TemperatureMock("temperature_5", 0.0, false, 0, 300) ;
//  TemperatureMock temperature_6_mock = TemperatureMock("temperature_6", 0.0, false, 0, 300) ;
//
//  PressureMock pressure_1_mock = PressureMock("pressure_1", 0.0, false, 0, 30) ;
//  PressureMock pressure_2_mock = PressureMock("pressure_2", 0.0, false, 0, 30) ;
//  PressureMock pressure_3_mock = PressureMock("pressure_3", 0.0, false, 0, 30) ;
//  PressureMock pressure_4_mock = PressureMock("pressure_4", 0.0, false, 0, 100) ;
//
//  BinarySwitchMock sw_flow_mock = BinarySwitchMock("sw_flow", false, false) ;
//  BinarySwitchMock sw_power_loss_mock = BinarySwitchMock("sw_power_loss", false, false) ;
//  BinarySwitchMock sw_emergency_shutdown_mock = BinarySwitchMock("sw_emergency_shutdown", false, false) ;
//  BinarySwitchMock sw_4_mock = BinarySwitchMock("sw_4", false, false) ;
//  BinarySwitchMock sw_5_mock = BinarySwitchMock("sw_5", false, false) ;
//  BinarySwitchMock sw_6_mock = BinarySwitchMock("sw_6", false, false) ;
//  BinarySwitchMock sw_7_mock = BinarySwitchMock("sw_7", false, false) ;
//  BinarySwitchMock sw_8_mock = BinarySwitchMock("sw_8", false, false) ;

  String toJson() {
    Map<String, dynamic>  m = {
      'temp_1': [temperature_1_mock.v, temperature_1_mock.active],
      'temp_2': [temperature_2_mock.v, temperature_2_mock.active],
      'temp_3': [temperature_3_mock.v, temperature_3_mock.active],
      'temp_5': [temperature_5_mock.v, temperature_5_mock.active],
      'temp_6': [temperature_6_mock.v, temperature_6_mock.active],

      'pressure_1': [pressure_1_mock.v, pressure_1_mock.active],
      'pressure_2': [pressure_2_mock.v, pressure_2_mock.active],
      'pressure_3': [pressure_3_mock.v, pressure_3_mock.active],
      'pressure_4': [pressure_4_mock.v, pressure_4_mock.active],

      'sw_flow':               [sw_flow_mock.v, sw_flow_mock.active],
      'sw_emergency_shutdown': [sw_emergency_shutdown_mock.v, sw_emergency_shutdown_mock.active],
      'sw_power_loss':         [sw_power_loss_mock.v, sw_power_loss_mock.active],
      'sw_4': [sw_4_mock.v, sw_4_mock.active],
      'sw_5': [sw_5_mock.v, sw_5_mock.active],
      'sw_6': [sw_6_mock.v, sw_6_mock.active],
      'sw_7': [sw_7_mock.v, sw_7_mock.active],
      'sw_8': [sw_8_mock.v, sw_8_mock.active],
    } ;

    String json = BRMJsonUtil.jsonEncode(m) ;
    String json_pretty = BRMJsonUtil.prettyPrintJson(json) ;
    print('pretty: $json_pretty') ;

    return json ;
  }

  fromJson(String json) {
//    print('MockBunch fromJson: $json') ;
    Map<String, dynamic> m = BRMJsonUtil.jsonDecode(json) ;

    //
    // Temperature
    //
    temperature_1_mock.v      = m['temp_1'][0] ;
    temperature_1_mock.active = m['temp_1'][1] ;

    temperature_2_mock.v      = m['temp_2'][0] ;
    temperature_2_mock.active = m['temp_2'][1] ;

    temperature_3_mock.v      = m['temp_3'][0] ;
    temperature_3_mock.active = m['temp_3'][1] ;

    temperature_5_mock.v      = m['temp_5'][0] ;
    temperature_5_mock.active = m['temp_5'][1] ;

    temperature_6_mock.v      = m['temp_6'][0] ;
    temperature_6_mock.active = m['temp_6'][1] ;

    //
    // Pressure
    //
    pressure_1_mock.v      = m['pressure_1'][0] ;
    pressure_1_mock.active = m['pressure_1'][1] ;

    pressure_2_mock.v      = m['pressure_2'][0] ;
    pressure_2_mock.active = m['pressure_2'][1] ;

    pressure_3_mock.v      = m['pressure_3'][0] ;
    pressure_3_mock.active = m['pressure_3'][1] ;

    pressure_4_mock.v      = m['pressure_4'][0] ;
    pressure_4_mock.active = m['pressure_4'][1] ;

    //
    // Switches
    //
    sw_flow_mock.v      = m['sw_flow'][0] ;
    sw_flow_mock.active = m['sw_flow'][1] ;

    sw_emergency_shutdown_mock.v      = m['sw_emergency_shutdown'][0] ;
    sw_emergency_shutdown_mock.active = m['sw_emergency_shutdown'][1] ;

    sw_power_loss_mock.v      = m['sw_power_loss'][0] ;
    sw_power_loss_mock.active = m['sw_power_loss'][1] ;

    sw_4_mock.v      = m['sw_4'][0] ;
    sw_4_mock.active = m['sw_4'][1] ;

    sw_5_mock.v      = m['sw_5'][0] ;
    sw_5_mock.active = m['sw_5'][1] ;

    sw_6_mock.v      = m['sw_6'][0] ;
    sw_6_mock.active = m['sw_6'][1] ;

    sw_7_mock.v      = m['sw_7'][0] ;
    sw_7_mock.active = m['sw_7'][1] ;

    sw_8_mock.v      = m['sw_8'][0] ;
    sw_8_mock.active = m['sw_8'][1] ;

    print(m) ;

  }
}

//  Uint8List toBytes() {
//    Uint8List bytes = Uint8List(40) ;
//    ByteData bd = bytes.buffer.asByteData() ;
//
//    bd.setFloat32(0,  temperature_1_mock.v, Endian.little) ;
//    bd.setFloat32(4,  temperature_2_mock.v, Endian.little) ;
//    bd.setFloat32(8,  temperature_3_mock.v, Endian.little) ;
//    bd.setFloat32(12, temperature_5_mock.v, Endian.little) ;
//    bd.setFloat32(16, temperature_6_mock.v, Endian.little) ;
//
//    bd.setFloat32(20, pressure_1_mock.v, Endian.little) ;
//    bd.setFloat32(24, pressure_2_mock.v, Endian.little) ;
//    bd.setFloat32(28, pressure_3_mock.v, Endian.little) ;
//    bd.setFloat32(32, pressure_4_mock.v, Endian.little) ;
//
//    //
//    // Temperature mock active
//    //
//    int oneByte = 0 ;
//    if (temperature_1_mock.active) {
//      oneByte = oneByte.setBit(0);
//    }
//    if (temperature_2_mock.active) {
//      oneByte = oneByte.setBit(1);
//    }
//    if (temperature_3_mock.active) {
//      oneByte = oneByte.setBit(2);
//    }
//    if (temperature_5_mock.active) {
//      oneByte = oneByte.setBit(3);
//    }
//    if (temperature_6_mock.active) {
//      oneByte = oneByte.setBit(4) ;
//    }
//    bd.setUint8(36, oneByte) ;
//
//    //
//    // pressure mock active
//    //
//    oneByte = 0 ;
//    if (pressure_1_mock.active) {
//      oneByte = oneByte.setBit(0);
//    }
//    if (pressure_2_mock.active) {
//      oneByte = oneByte.setBit(1);
//    }
//    if (pressure_3_mock.active) {
//      oneByte = oneByte.setBit(2);
//    }
//    if (pressure_4_mock.active) {
//      oneByte = oneByte.setBit(3);
//    }
//    bd.setUint8(37, oneByte) ;
//
//    //
//    // switch mock ** VALUE **
//    //
//    oneByte = 0 ;
//    if (sw_flow_mock.v) {
//      oneByte = oneByte.setBit(0);
//    }
//    if (sw_emergency_shutdown_mock.v) {
//      oneByte = oneByte.setBit(1);
//    }
//    if (sw_power_loss_mock.v) {
//      oneByte = oneByte.setBit(2);
//    }
//    if (sw_4_mock.v) {
//      oneByte = oneByte.setBit(3);
//    }
//    if (sw_5_mock.v) {
//      oneByte = oneByte.setBit(4);
//    }
//    if (sw_6_mock.v) {
//      oneByte = oneByte.setBit(5);
//    }
//    if (sw_7_mock.v) {
//      oneByte = oneByte.setBit(6);
//    }
//    if (sw_8_mock.v) {
//      oneByte = oneByte.setBit(7);
//    }
//    bd.setUint8(38, oneByte) ;
//
//    //
//    // switch mock active
//    //
//    oneByte = 0 ;
//    if (sw_flow_mock.active) {
//      oneByte = oneByte.setBit(0);
//    }
//
//    if (sw_emergency_shutdown_mock.active) {
//      oneByte = oneByte.setBit(1);
//    }
//
//    if (sw_power_loss_mock.active) {
//      oneByte = oneByte.setBit(2);
//    }
//
//    if (sw_4_mock.active) {
//      oneByte = oneByte.setBit(3);
//    }
//
//    if (sw_5_mock.active) {
//      oneByte = oneByte.setBit(4);
//    }
//
//    if (sw_6_mock.active) {
//      oneByte = oneByte.setBit(5);
//    }
//
//    if (sw_7_mock.active) {
//      oneByte = oneByte.setBit(6);
//    }
//
//    if (sw_8_mock.active) {
//      oneByte = oneByte.setBit(7);
//    }
//    bd.setUint8(39, oneByte) ;
//
//    Uint8List b = bd.buffer.asUint8List() ;
//
//    if (b == bytes) {
//      print("yep");
//    }
//    else {
//      print("nope") ;
//    }
//    return b ;
//  }
//}

//  fromBytes(Uint8List bytes) {
//    ByteData bd = bytes.buffer.asByteData() ;
//
//    temperature_1_mock.v = bd.getFloat32(0, Endian.little) ;
//    temperature_2_mock.v = bd.getFloat32(4, Endian.little) ;
//    temperature_3_mock.v = bd.getFloat32(8, Endian.little) ;
//    temperature_5_mock.v = bd.getFloat32(12, Endian.little) ;
//    temperature_6_mock.v = bd.getFloat32(16, Endian.little) ;
//
//
//    pressure_1_mock.v = bd.getFloat32(20, Endian.little) ;
//    pressure_2_mock.v = bd.getFloat32(24, Endian.little) ;
//    pressure_3_mock.v = bd.getFloat32(28, Endian.little) ;
//    pressure_4_mock.v = bd.getFloat32(32, Endian.little) ;
//
//    int oneByte ;
//    oneByte = bd.getInt8(36) ; // temperature mock active
//    temperature_1_mock.active = oneByte.isSet(0);
//    temperature_2_mock.active = oneByte.isSet(1) ;
//    temperature_3_mock.active = oneByte.isSet(2) ;
//    temperature_5_mock.active = oneByte.isSet(3) ;
//    temperature_6_mock.active = oneByte.isSet(4) ;
//    print('temp bits: ${oneByte.toBinaryPadded(8)}') ;
//
//    oneByte = bd.getInt8(37) ; // pressure mock active
//    pressure_1_mock.active = oneByte.isSet(0) ;
//    pressure_2_mock.active = oneByte.isSet(1) ;
//    pressure_3_mock.active = oneByte.isSet(2) ;
//    pressure_4_mock.active = oneByte.isSet(3) ;
//    print('pressure bits: ${oneByte.toBinaryPadded(8)}') ;
//
//    oneByte = bd.getInt8(38) ; // switch mock VALUE
//    sw_flow_mock.v = oneByte.isSet(0) ;
//    sw_emergency_shutdown_mock.v = oneByte.isSet(1) ;
//    sw_power_loss_mock.v = oneByte.isSet(2) ;
//    sw_4_mock.v = oneByte.isSet(3) ;
//    sw_5_mock.v = oneByte.isSet(4) ;
//    sw_6_mock.v = oneByte.isSet(5) ;
//    sw_7_mock.v = oneByte.isSet(6) ;
//    sw_8_mock.v = oneByte.isSet(7) ;
//    print('switch value bits: ${oneByte.toBinaryPadded(8)}') ;
//
//    oneByte = bd.getInt8(39) ;  // switch mock active
//    sw_flow_mock.active = oneByte.isSet(0) ;
//    sw_emergency_shutdown_mock.active = oneByte.isSet(1) ;
//    sw_power_loss_mock.active = oneByte.isSet(2) ;
//    sw_4_mock.active = oneByte.isSet(3) ;
//    sw_5_mock.active = oneByte.isSet(4) ;
//    sw_6_mock.active = oneByte.isSet(5) ;
//    sw_7_mock.active = oneByte.isSet(6) ;
//    sw_8_mock.active = oneByte.isSet(7) ;
//    print('switch active bits: ${oneByte.toBinaryPadded(8)}') ;
//  }
/*
  {
  "temp_1": [10, false],
  "temp_2": [20, false],
  "temp_3": [0, false],
  "temp_4": [15, true],
  "temp_5": [20, true],

  "pressure_1": [0, true],
  "pressure_2": [0, false],
  "pressure_3": [10, true],
  "pressure_4": [0, false],

  "sw_flow": [true, true],
  "sw_emergency_shutdown": [false, false],
  "sw_power_loss": [false, true],
  "sw_4": [false, true],
  "sw_5": [false, true],
  "sw_6": [false, true],
  "sw_7": [false, true],
  "sw_8": [false, true]
  }
  */