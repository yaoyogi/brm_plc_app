import 'package:flutter/material.dart'; // for ChangeNotifier

import 'dart:typed_data'; // for Uint8List

import 'package:binary/binary.dart';

import 'package:brmplcapp/prx_integ/valve_dev.dart';
import 'package:brmplcapp/prx_integ/pressure_dev.dart';
import 'package:brmplcapp/prx_integ/temperature_dev.dart';
import 'package:brmplcapp/prx_integ/switch_dev.dart';

///
/// This allows multiple listeners to get notified when new aggr data is available.
///
/// Note that the cadence the aggr gets updated is controlled by the Iso::runTimer(..).
///
/// If a client wants exclusive use of aggr, they should simply copy it when they are
/// first notified.
///
class AggrProvider extends ChangeNotifier {
  static AggrProvider Global = AggrProvider() ;

  PrxAggr aggr = PrxAggr();

  AggrProvider({PrxAggr data}) {
    if (data != null) {
      aggr = data;
    }
  }

  update() {
    notifyListeners();
  }
}

/// Represents the state from the PLC Aggr type.  This instance is updated via from_bytes(...) where
/// the bytes are a binary payload (little Endian) returned from the PLC
class PrxAggr {
  PrxAggr() {
    // Empty for now
  }

  from_bytes(Uint8List r) {
    lastFromBytes = r ;

//    print(r) ;
//    print('buf size: {$r.size}') ;
    var bd = r.buffer.asByteData() ;

    //
    // Timestamp
    //
    timestamp = bd.getUint32(0, Endian.little) ;
//    print('timestamp: $timestamp') ;

    //
    // Valves
    //
    int valves = bd.getUint32(4, Endian.little) ;
//    print(valves.toBinaryPadded(32)) ;

    // Relay-A
    valve_02.state = BinaryInt(valves).isSet(0) ;
    valve_03.state = BinaryInt(valves).isSet(1) ;
    valve_04.state = BinaryInt(valves).isSet(2) ;

    valve_11.state = BinaryInt(valves).isSet(3) ;
    valve_12.state = BinaryInt(valves).isSet(4) ;

    valve_21.state = BinaryInt(valves).isSet(5) ;
    valve_22.state = BinaryInt(valves).isSet(6) ;

    valve_31.state = BinaryInt(valves).isSet(7) ;
    valve_32.state = BinaryInt(valves).isSet(8) ;

    valve_41.state = BinaryInt(valves).isSet(9) ;
    valve_42.state = BinaryInt(valves).isSet(10) ;

    valve_51.state = BinaryInt(valves).isSet(11) ;
    valve_52.state = BinaryInt(valves).isSet(12) ;

    valve_61.state = BinaryInt(valves).isSet(13) ;


    // Relay-B
    valve_71.state = BinaryInt(valves).isSet(14) ;
    valve_72.state = BinaryInt(valves).isSet(15) ;

    valve_73.state = BinaryInt(valves).isSet(16) ;
    valve_74.state = BinaryInt(valves).isSet(17) ;

    //
    // Temperature
    //
    temp_1.fahrenheit = bd.getFloat32( 8, Endian.little) ;
    temp_2.fahrenheit = bd.getFloat32(12, Endian.little) ;
    temp_3.fahrenheit = bd.getFloat32(16, Endian.little) ;
    temp_5.fahrenheit = bd.getFloat32(20, Endian.little) ;
    temp_6.fahrenheit = bd.getFloat32(24, Endian.little) ;

//    print('temp ${temp_1.fahrenheit}, ${temp_2.fahrenheit}, ${temp_3.fahrenheit}, ${temp_5.fahrenheit}, ${temp_6.fahrenheit}') ;

    //
    // Pressure
    //
    double v = bd.getFloat32(28, Endian.little) ;
    pressure_1.psi = v ;
    pressure_2.psi = bd.getFloat32(32, Endian.little) ;
    pressure_3.psi = bd.getFloat32(36, Endian.little) ;
    pressure_4.psi = bd.getFloat32(40, Endian.little) ;

//   print('pressure ${pressure_1.psi}, ${pressure_2.psi}, ${pressure_3.psi}, ${pressure_4.psi}') ;

    //
    // Input Switches
    //
    int input_switches = bd.getUint8(44) ; // no Endian needed as it is single byte
//    print('input switches:  ${input_switches.toBinaryPadded(8)}') ;
    swin_flow.state = BinaryInt(input_switches).isSet(0) ;
    swin_2.state = BinaryInt(input_switches).isSet(1) ;
    swin_3.state = BinaryInt(input_switches).isSet(2) ;
    swin_4.state = BinaryInt(input_switches).isSet(3) ;
    swin_5.state = BinaryInt(input_switches).isSet(4) ;
    swin_6.state = BinaryInt(input_switches).isSet(5) ;
    swin_7.state = BinaryInt(input_switches).isSet(6) ;
    swin_8.state = BinaryInt(input_switches).isSet(7) ;

    //
    // Output Switches
    //
    int output_switches =  bd.getUint8(45) ; // no Endian needed as it is single byte
//    print('output switches: ${output_switches.toBinaryPadded(8)}') ;

    sw_circulation_pump.state = BinaryInt(output_switches).isSet(0) ;
    sw_transfer_pump.state = BinaryInt(output_switches).isSet(1) ;

    sw_heater.state = BinaryInt(output_switches).isSet(2) ;
    sw_heater_pump.state = BinaryInt(output_switches).isSet(3) ;

    sw_chiller.state = BinaryInt(output_switches).isSet(4) ;
    sw_chiller_pump.state = BinaryInt(output_switches).isSet(5) ;

    sw_sonicator.state = BinaryInt(output_switches).isSet(6) ;
    sw_o2stone.state = BinaryInt(output_switches).isSet(7) ;

    //
    // Motor/Pump/Device Settings
    //
    sonicator_setting = bd.getUint16(46, Endian.little) ;

    o2stone_setting = bd.getUint16(48, Endian.little) ;

    heater_setting = bd.getUint16(50, Endian.little) ;

    chiller_setting = bd.getUint16(52, Endian.little) ;

    //
    // Sim Switches
    //
    int sim = bd.getUint8(54) ; // this is aggregate of all 8-sim switches
//    print('sim: $sim') ;
    sw_sim1.state = sim.isSet(0) ;
    sw_sim2.state = sim.isSet(1) ;
    sw_sim3.state = sim.isSet(2) ;
    sw_sim4.state = sim.isSet(3) ;
    sw_sim5.state = sim.isSet(4) ;
    sw_sim6.state = sim.isSet(5) ;
    sw_sim7.state = sim.isSet(6) ;
    sw_sim8.state = sim.isSet(7) ;

//    print('sonicator: $sonicator_setting, o2stone: $o2stone_setting, heater: $heater_setting, chiller: $chiller_setting') ;

//    print(r) ;
  }

  /**
   * Creates a copy of this instance based on the lastFromBytes member.  That member is populated
   * from the from_bytes(..) call.
   */
  PrxAggr copyFromLastBytes() {
    if (lastFromBytes == null) {
      return null ;
    }

    PrxAggr r = PrxAggr() ;
    r.from_bytes(lastFromBytes) ;
    return r ;
  }

  Uint8List toBytes() {

  }

  //
  // Other State
  //
  Uint8List lastFromBytes ;

  //
  // Pre-amble
  //
  int timestamp = 0 ;

  //
  // Valves
  //
  // Relay_A
  /* Transfer/Process selection -- 3-way */
  ValveDev valve_02 = ValveDev('valve_02', false, 'Transfer/Process selection -- 3-way') ;  	// Transfer/Process selection -- 3-way
  ValveDev valve_03 = ValveDev('valve_03', false, 'IBC In/Out selection (closest to valve_02)') ;	// IBC In/Out selection (closest to valve_02)
  ValveDev valve_04 = ValveDev('valve_04', false, 'IBC In/Out selection') ;	// IBC In/Out selection

  ValveDev valve_11 = ValveDev('valve_11', false, 'Tank-2 inlet') ;	// Tank-2 inlet
  ValveDev valve_12 = ValveDev('valve_12', false, 'Tank-2 outlet') ;	// Tank-2 outlet

  ValveDev valve_21 = ValveDev('valve_21', false, 'Tank-3 inlet') ;	// Tank-3 inlet
  ValveDev valve_22 = ValveDev('valve_22', false, 'Tank-3 outlet') ;	// Tank-3 outlet

  ValveDev valve_31 = ValveDev('valve_31', false, 'O2-stone inlet') ;	// O2-stone inlet
  ValveDev valve_32 = ValveDev('valve_32', false, 'O2-stone outlet') ;	// O2-stone outlet

  ValveDev valve_41 = ValveDev('valve_41', false, 'Transducer inlet') ;	// Transducer inlet
  ValveDev valve_42 = ValveDev('valve_42', false, 'Transducer outlet') ;	// Transducer outlet

  ValveDev valve_51 = ValveDev('valve_51', false, 'Filter-tank inlet') ;	// Filter-tank inlet
  ValveDev valve_52 = ValveDev('valve_52', false, 'Filter-tank outlet') ;	// Filter-tank outlet

  ValveDev valve_61 = ValveDev('valve_61', false, 'Heat exchange shunt') ; 	// Heat exchange shunt

  // Relay_B
  ValveDev valve_71 = ValveDev('valve_71', false, 'Heat circulation pump inlet  -- 120VAC') ;	// Heat circulation pump inlet  -- 120VAC
  ValveDev valve_72 = ValveDev('valve_72', false, 'Heat circulation pump outlet -- 120VAC') ;	// Heat circulation pump outlet -- 120VAC

  ValveDev valve_73 = ValveDev('valve_73', false, 'Chiller tank inlet  -- 120VAC') ;	// Chiller tank inlet  -- 120VAC
  ValveDev valve_74 = ValveDev('valve_74', false, 'Chiller pump outlet -- 120VAC') ;	// Chiller pump outlet -- 120VAC

  //----------------
  //  Temperature
  //----------------
  //
  // RTD MOD A
  //
  TemperatureDev temp_1 = TemperatureDev('temp_1', 0.0, 0.0, 120.0, 'Main-tank'); // Main-tank, 100 PT RTD

  TemperatureDev temp_2 = TemperatureDev('temp_2', 0.0, 0.0, 120.0, 'Circulation HX inlet') ; // Circulation-loop HX inlet, 100 PT RTD
  TemperatureDev temp_3 = TemperatureDev('temp_3', 0.0, 0.0, 120.0, 'Circulation HX outlet') ; // Circulation-loop HX outlet, 100 PT RTD

// MrP: ??? Sean -- missing Temperature Transducer-4 ??
//	floattemp_4 ; // Main-tank, 100 PT RTD

  //
  // RTD MOD B
  //
  TemperatureDev temp_5 = TemperatureDev('temp_5', 0.0, 0.0, 120.0, 'Thermo HX inlet') ; // Thermo circuit HX inlet,  100 PT RTD
  TemperatureDev temp_6 = TemperatureDev('temp_6', 0.0, 0.0, 120.0, 'Thermo HX outlet') ; // Thermo circuit HX outlet, 100 PT RTD


  //----------------
  //    Pressure
  //----------------
  PressureDev pressure_1 = PressureDev('pressure_1', 0.0, -30.0,  15.0, 'Main-tank') ; // Main-tank, -30..+15 PSI
  PressureDev pressure_2 = PressureDev('pressure_2', 0.0,   0.0,  30.0, 'Circ-pump outlet') ; // Circulation pump outlet side, 0..+30 PSI PSI
  PressureDev pressure_3 = PressureDev('pressure_3', 0.0,   0.0,  30.0, 'Circ return to Main-tank') ; // Circulation loop return to Main-tank, 0..+30 PSI
  PressureDev pressure_4 = PressureDev('pressure_4', 0.0,   0.0, 100.0, 'HX inlet') ; // Heat-exchanger inlet side, 0..+100 PSI

  //----------------
  // Input Switches
  //----------------
  SwitchDev swin_flow = SwitchDev('swin_flow', false, 'flow switch') ;   // Circulation loop, right after circulation pump
  SwitchDev swin_2 =    SwitchDev('swin_2',    false, 'sw in 2') ; // Unassigned
  SwitchDev swin_3 =    SwitchDev('swin_2',    false, 'sw in 3') ; // Unassigned
  SwitchDev swin_4 =    SwitchDev('swin_3',    false, 'sw in 4') ;
  SwitchDev swin_5 =    SwitchDev('swin_4',    false, 'sw in 5') ;
  SwitchDev swin_6 =    SwitchDev('swin_5',    false, 'sw in 6') ;
  SwitchDev swin_7 =    SwitchDev('swin_6',    false, 'sw in 7') ;
  SwitchDev swin_8 =    SwitchDev('swin_7',    false, 'sw in 8') ;

  //-----------------
  // Output Switches
  //-----------------
  SwitchDev sw_circulation_pump = SwitchDev("sw_circulation_pump", false, 'circulation pump') ;   // Circulation Pump

  SwitchDev sw_transfer_pump  = SwitchDev("sw_transfer_pump",     false, 'ibc transfer pump') ;   // IBC Transfer Pump

  SwitchDev sw_heater         = SwitchDev("sw_heater",            false, 'heater           ') ;   // Heater
  SwitchDev sw_heater_pump    = SwitchDev("sw_heater_pump",       false, 'heater pump') ; 	      // Heater Pump

  SwitchDev sw_chiller        = SwitchDev("sw_chiller",           false, 'chiller           ') ;  // Chiller
  SwitchDev sw_chiller_pump   = SwitchDev("sw_chiller_pump",      false, 'chiller pump') ;        // Chiller Pump

  SwitchDev sw_sonicator      = SwitchDev("sw_sonicator",         false, 'sonicator') ;           // Sonicator

  SwitchDev sw_o2stone        = SwitchDev("sw_o2stone",           false, 'o2-stone ') ;           // O2Stone

  //
  // Motor/Pump/Other
  //
  int sonicator_setting = 0 ;
  int o2stone_setting   = 0 ;
  int heater_setting    = 0 ;
  int chiller_setting   = 0 ;

  //--------------------
  // SIM Discrete Input
  //--------------------
  SwitchDev sw_sim1   = SwitchDev("sw_sim1",   false, 'sim_1') ;
  SwitchDev sw_sim2   = SwitchDev("sw_sim2",   false, 'sim_2') ;
  SwitchDev sw_sim3   = SwitchDev("sw_sim3",   false, 'sim_3') ;
  SwitchDev sw_sim4   = SwitchDev("sw_sim4",   false, 'sim_4') ;
  SwitchDev sw_sim5   = SwitchDev("sw_sim5",   false, 'sim_5') ;
  SwitchDev sw_sim6   = SwitchDev("sw_sim6",   false, 'sim_6') ;
  SwitchDev sw_sim7   = SwitchDev("sw_sim7",   false, 'sim_7') ;
  SwitchDev sw_sim8   = SwitchDev("sw_sim8",   false, 'sim_8') ;
}