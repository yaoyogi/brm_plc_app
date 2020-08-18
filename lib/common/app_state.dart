
import 'package:provider/provider.dart';// Provider
import 'package:flutter/material.dart';

import 'package:brmplcapp/screens/overview_screen.dart';
import 'package:brmplcapp/screens/settings_screen.dart';
import 'package:brmplcapp/screens/mocks_screen.dart';
import 'package:brmplcapp/screens/events_screen.dart';
import 'package:brmplcapp/screens/processes_screen.dart';

import 'package:brmplcapp/screens/logging_console_viewer_screen.dart';
import 'package:brmplcapp/screens/logging_udp_mgr_screen.dart';
import 'package:brmplcapp/screens/logging_send_msg_screen.dart' ;

import 'package:brmplcapp/screens/graphs_screen.dart';
import 'package:brmplcapp/screens/validator_screen.dart';
import 'package:brmplcapp/screens/help_screen.dart';

//
// App
//

// !! EXAMPLE ONLY !!
import '../examples/ex_state_mgmt.dart' ;       // app state

class TopLevelStateProvider extends ChangeNotifier {
  static TopLevelStateProvider getProvider(BuildContext ctx) {
    return Provider.of<TopLevelStateProvider>(ctx) ;
  }

  TopLevelStateProvider() {
    resetAllAppState() ;
  }

  // Resets ALL app state
  resetAllAppState() {
//    TastingAppGlobals.resetAll() ;

    someScreenAppState = SomeScreenAppState() ;
    overviewScreenAppState = OverviewScreenAppState() ;
    configScreenAppState = SettingsScreenAppState() ;
//    thermoScreenAppState = ThermoScreenAppState() ;
//    circulationScreenAppState = CirculationScreenAppState() ;
//    ibcTransferScreenAppState = IBCTransferScreenAppState() ;
    mocksScreenAppState = MocksScreenAppState() ;
    eventsScreenAppState = EventsScreenAppState() ;
    processesScreenAppState = ProcessesScreenAppState() ;

    consoleLogEntryDataTableAppState = ConsoleLogEntryDataTableAppState() ;
    udpLoggerMgrAppState = UDPLoggerMgrAppState() ;
    loggingSendMessageAppState = LoggingSendMessageAppState();

    graphsScreenAppState = GraphsScreenAppState() ;
    helpScreenAppState = HelpScreenAppState() ;
    validatorScreenAppState = ValidatorScreenAppState() ;
  }

  //
  // Examples, Testing, Misc -- NOT FOR PRODUCTION
  //
  SomeScreenAppState someScreenAppState = SomeScreenAppState() ;
  OverviewScreenAppState overviewScreenAppState = OverviewScreenAppState() ;
  SettingsScreenAppState configScreenAppState = SettingsScreenAppState() ;
//  ThermoScreenAppState thermoScreenAppState = ThermoScreenAppState() ;
//  CirculationScreenAppState circulationScreenAppState = CirculationScreenAppState() ;
//  IBCTransferScreenAppState ibcTransferScreenAppState = IBCTransferScreenAppState() ;
  MocksScreenAppState mocksScreenAppState = MocksScreenAppState() ;
  EventsScreenAppState eventsScreenAppState = EventsScreenAppState() ;
  ProcessesScreenAppState processesScreenAppState = ProcessesScreenAppState() ;

  ConsoleLogEntryDataTableAppState consoleLogEntryDataTableAppState = ConsoleLogEntryDataTableAppState() ;
  UDPLoggerMgrAppState udpLoggerMgrAppState = UDPLoggerMgrAppState() ;
  LoggingSendMessageAppState loggingSendMessageAppState = LoggingSendMessageAppState();

  GraphsScreenAppState graphsScreenAppState = GraphsScreenAppState() ;
  HelpScreenAppState helpScreenAppState = HelpScreenAppState() ;
  ValidatorScreenAppState validatorScreenAppState = ValidatorScreenAppState() ;

  update() {
    notifyListeners() ;
  }
}