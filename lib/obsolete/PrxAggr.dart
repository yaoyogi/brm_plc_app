//import 'dart:typed_data'; // for Uint8List
//
//import 'package:binary/binary.dart';
//
//class PrxAggr {
//  from_bytes(Uint8List r) {
////    print(r) ;
////    print('buf size: {$r.size}') ;
//    var bd = r.buffer.asByteData() ;
//
//    //
//    // Timestamp
//    //
//    timestamp = bd.getUint32(0, Endian.little) ;
////    print('timestamp: $timestamp') ;
//
//    //
//    // Valves
//    //
//    int valves = bd.getUint32(4, Endian.little) ;
////    print(valves.toBinaryPadded(32)) ;
//
//    // Relay-A
//    valve_02 = BinaryInt(valves).isSet(0) ;
//    valve_03 = BinaryInt(valves).isSet(1) ;
//    valve_04 = BinaryInt(valves).isSet(2) ;
//
//    valve_11 = BinaryInt(valves).isSet(3) ;
//    valve_12 = BinaryInt(valves).isSet(4) ;
//
//    valve_21 = BinaryInt(valves).isSet(5) ;
//    valve_22 = BinaryInt(valves).isSet(6) ;
//
//    valve_31 = BinaryInt(valves).isSet(7) ;
//    valve_32 = BinaryInt(valves).isSet(8) ;
//
//    valve_41 = BinaryInt(valves).isSet(9) ;
//    valve_42 = BinaryInt(valves).isSet(10) ;
//
//    valve_51 = BinaryInt(valves).isSet(11) ;
//    valve_52 = BinaryInt(valves).isSet(12) ;
//
//    valve_61 = BinaryInt(valves).isSet(13) ;
//
//
//    // Relay-B
//    valve_71 = BinaryInt(valves).isSet(14) ;
//    valve_72 = BinaryInt(valves).isSet(15) ;
//
//    valve_73 = BinaryInt(valves).isSet(16) ;
//    valve_74 = BinaryInt(valves).isSet(17) ;
//
//    //
//    // Temperature
//    //
//    temp_1 = bd.getFloat32( 8, Endian.little) ;
//    temp_2 = bd.getFloat32(12, Endian.little) ;
//    temp_3 = bd.getFloat32(16, Endian.little) ;
//    temp_5 = bd.getFloat32(20, Endian.little) ;
//    temp_6 = bd.getFloat32(24, Endian.little) ;
//
////    print('temp ${temp_1}, ${temp_2}, ${temp_3}, ${temp_5}, ${temp_6}') ;
//
//    //
//    // Pressure
//    //
//    pressure_1 = bd.getFloat32(28, Endian.little) ;
//    pressure_2 = bd.getFloat32(32, Endian.little) ;
//    pressure_3 = bd.getFloat32(36, Endian.little) ;
//    pressure_4 = bd.getFloat32(40, Endian.little) ;
//
////    print('pressure ${pressure_1}, ${pressure_2}, ${pressure_3}, ${pressure_4}') ;
//
//    //
//    // Input Switches
//    //
//    int input_switches = bd.getUint8(44) ; // no Endian needed as it is single byte
////    print('input switches:  ${input_switches.toBinaryPadded(8)}') ;
//    flow_sw = BinaryInt(input_switches).isSet(0) ;
////    BinaryInt(input_switches).isSet(1) ;
////    BinaryInt(input_switches).isSet(2) ;
////    BinaryInt(input_switches).isSet(3) ;
////    BinaryInt(input_switches).isSet(4) ;
////    BinaryInt(input_switches).isSet(5) ;
////    BinaryInt(input_switches).isSet(6) ;
////    BinaryInt(input_switches).isSet(7) ;
//
//    //
//    // Output Switches
//    //
//    int output_switches =  bd.getUint8(45) ; // no Endian needed as it is single byte
////    print('output switches: ${output_switches.toBinaryPadded(8)}') ;
//
//    sw_circulation_pump = BinaryInt(output_switches).isSet(0) ;
//    sw_transfer_pump = BinaryInt(output_switches).isSet(1) ;
//    sw_heater = BinaryInt(output_switches).isSet(2) ;
//    sw_heater_pump = BinaryInt(output_switches).isSet(3) ;
//    sw_chiller = BinaryInt(output_switches).isSet(4) ;
//    sw_chiller_pump = BinaryInt(output_switches).isSet(5) ;
//    sw_sonicator = BinaryInt(output_switches).isSet(6) ;
//    sw_02stone_pump = BinaryInt(output_switches).isSet(7) ;
//
//    //
//    // Motor/Pump/Device Settings
//    //
//    sonicator_setting = bd.getUint16(46, Endian.little) ;
//
//    o2stone_setting = bd.getUint16(48, Endian.little) ;
//
//    heater_setting = bd.getUint16(50, Endian.little) ;
//
//    chiller_setting = bd.getUint16(52, Endian.little) ;
//
////    print('sonicator: $sonicator_setting, o2stone: $o2stone_setting, heater: $heater_setting, chiller: $chiller_setting') ;
//
////    print(r) ;
//  }
//
//  Uint8List toBytes() {
//
//  }
//
//  //
//  // Pre-amble
//  //
//  int timestamp = 0 ;
//
//  //
//  // Valves
//  //
//  // Relay_A
//  /* Transfer/Process selection -- 3-way */
//  bool valve_02 = false ;  	// Transfer/Process selection -- 3-way
//  bool valve_03 = false ;	// IBC In/Out selection (closest to valve_02)
//  bool valve_04 = false ;	// IBC In/Out selection
//
//  bool valve_11 = false ;	// Tank-2 inlet
//  bool valve_12 = false ;	// Tank-2 outlet
//
//  bool valve_21 = false ;	// Tank-3 inlet
//  bool valve_22 = false ;	// Tank-3 outlet
//
//  bool valve_31 = false ;	// O2-stone inlet
//  bool valve_32 = false ;	// O2-stone outlet
//
//  bool valve_41 = false ;	// Transducer inlet
//  bool valve_42 = false ;	// Transducer outlet
//
//  bool valve_51 = false ;	// Filter-tank inlet
//  bool valve_52 = false ;	// Filter-tank outlet
//
//  bool valve_61 = false ; 	// Heat exchange shunt
//
//  // Relay_B
//  bool valve_71 = false ;	// Heat circulation pump inlet  -- 120VAC
//  bool valve_72 = false ;	// Heat circulation pump outlet -- 120VAC
//
//  bool valve_73 = false ;	// Chiller tank inlet  -- 120VAC
//  bool valve_74 = false ;	// Chiller pump outlet -- 120VAC
//
//  //----------------
//  //  Temperature
//  //----------------
//  //
//  // RTD MOD A
//  //
//  double temp_1 = 0.0 ; // Main-tank, 100 PT RTD
//
//  double temp_2 = 0.0 ; // Circulation-loop HX inlet, 100 PT RTD
//  double temp_3 = 0.0 ; // Circulation-loop HX outlet, 100 PT RTD
//
//// MrP: ??? Sean -- missing Temperature Transducer-4 ??
////	floattemp_4 ; // Main-tank, 100 PT RTD
//
//  //
//  // RTD MOD B
//  //
//  double temp_5 = 0.0 ; // Thermo circuit HX inlet,  100 PT RTD
//  double temp_6 = 0.0 ; // Thermo circuit HX outlet, 100 PT RTD
//
//
//  //----------------
//  //    Pressure
//  //----------------
//  double pressure_1 = 0.0 ; // Main-tank, -30..+15 PSI
//  double pressure_2 = 0.0 ; // Circulation pump outlet side, 0..+30 PSI PSI
//  double pressure_3 = 0.0 ; // Circulation loop return to Main-tank, 0..+30 PSI
//  double pressure_4 = 0.0 ; // Heat-exchanger inlet side, 0..+100 PSI
//
//  //----------------
//  // Input Switches
//  //----------------
//  bool flow_sw = false ;   // Circulation loop, right after
//
//  //-----------------
//  // Output Switches
//  //-----------------
//  bool sw_circulation_pump = false ; 	// Circulation Pump
//
//  bool sw_transfer_pump = false ; // IBC Transfer Pump
//
//  bool sw_heater = false ; 		    // Heater
//  bool sw_heater_pump = false ; 	// Heater Pump
//
//  bool sw_chiller = false ; 	  	// Chiller
//  bool sw_chiller_pump = false ; 	// Chiller Pump
//
//  bool sw_sonicator = false ; 	  // Sonicator
//
//  bool sw_02stone_pump = false ; 	// O2Stone
//
//  //
//  // Motor/Pump/Other
//  //
//  int sonicator_setting = 1 ;
//  int o2stone_setting = 2 ;
//  int heater_setting = 3 ;
//  int chiller_setting = 4 ;
//
//  //--------------------
//  // SIM Discrete Input
//  //--------------------
//  int sim = 3 ; // this is aggregate of all 8-sim switches
//}