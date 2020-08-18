//
// Flutter
//
import 'package:brmplcapp/screens/graphs_screen.dart';
import 'package:flutter/material.dart';

import 'common/theme.dart' ;

//
// App
//
import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/app_state.dart';

import 'package:brmplcapp/screens/home_screen.dart';
import 'package:brmplcapp/screens/splash_screen.dart';
import 'package:brmplcapp/screens/settings_screen.dart';
import 'package:brmplcapp/screens/overview_screen.dart';
import 'package:brmplcapp/screens/circulation_screen.dart';
import 'package:brmplcapp/screens/ibc_tx_screen.dart';
import 'package:brmplcapp/screens/thermo_screen.dart';
import 'package:brmplcapp/screens/mocks_screen.dart';
import 'package:brmplcapp/screens/events_screen.dart';
import 'package:brmplcapp/screens/processes_screen.dart';
import 'package:brmplcapp/screens/graphs_screen.dart';
import 'package:brmplcapp/screens/validator_screen.dart';
import 'package:brmplcapp/screens/help_screen.dart';

import 'package:brmplcapp/screens/logging_console_viewer_screen.dart';
import 'package:brmplcapp/screens/logging_udp_mgr_screen.dart';
import 'package:brmplcapp/screens/logging_send_msg_screen.dart' ;
import 'package:brmplcapp/screens/logging_levels_screen.dart' ;

import 'examples/ex_state_mgmt.dart' ;

//
// 3rd Party
//
import 'package:provider/provider.dart';

void main() async {
  // Added on upgrade to: 1.12.13+hotfix.5
  // Error was:
  // [ERROR:flutter/lib/ui/ui_dart_state.cc(157)] Unhandled Exception: ServicesBinding.defaultBinaryMessenger was accessed before the binding was initialized.
  // E/flutter (21613): If you're running an application and need to access the binary messenger before `runApp()` has been called (for example, during plugin initialization), then you need to explicitly call the `WidgetsFlutterBinding.ensureInitialized()` first.

  // MrP: The above didn't fix my problem!  I think that somehow the mDNS is doing some work early in the
  // runApp(..) lifecycle and with the above update is actually a problem now...
  // The app ultimately comes up and can deploy/debug on Pixel-C
  //
  // UPDATE: This seems to be a known recently introduced bug and is fixed on the flutter beta channel...
  WidgetsFlutterBinding.ensureInitialized();

  // We need to get any initial environment and shared prefs values BEFORE we launch the main app widget...
  await AppEnv.initPlatformState() ;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
//    TastingAppGlobals.globalInit().then((_) {
//      String json = TastingAppGlobals.tastingEvent.toJson() ;
//      print(json) ;
//    });
  }

  @override
  Widget build(BuildContext context) {
    String title = 'BarrelRM Processor Companion' ;
    MaterialApp materialApp = MaterialApp(
      title: title,
      theme: appTheme,
      initialRoute: Navi.GRAPHS,
      routes: {
        Navi.SPLASH: (context) => SplashScreen(),

        Navi.HOME: (context) => MyHomePage(title: title),

        Navi.EX_STATE_MGMT: (context) => SomeScreenWidget(),

        Navi.SETTINGS: (context) => SettingsScreenWidget(),

        Navi.OVERVIEW: (context) => OverviewScreenWidget(),

//        Navi.CIRCULATION: (context) => CirculationScreenWidget(),
//
//        Navi.IBC_TRANSFER: (context) => IBCTransferScreenWidget(),

//        Navi.THERMO: (context) => ThermoScreenWidget(),

        Navi.MOCKS: (context) => MocksScreenWidget(),

        Navi.EVENTS: (context) => EventsScreenWidget(),

        Navi.PROCESSES: (context) => ProcessesScreenWidget(),

        Navi.LOGGER_CONSOLE_VIEWER: (context) => ConsoleLogEntryDataTableWidget(),
        Navi.LOGGER_UDP_MGR: (context) => UDPLoggerMgrScreen(),
        Navi.LOGGER_SEND_MSG: (context) => LoggingSendMessageWidget(),
//        Navi.LOGGER_ESP32_SIDE_FILE_LOGGER: (context) => ESP32SideFileLoggerMgrScreen(),
        Navi.LOGGER_LEVELS: (context) => LoggingLevelsDataTableWidget(),

        Navi.GRAPHS: (context) => GraphsScreenWidget(),
        Navi.VALIDATOR: (context) => ValidatorScreenWidget(),
        Navi.HELP: (context) => HelpScreenWidget(),

//        Navi.SAMPLES: (context) => SamplerScreenWidget(),
      },
//        home: JunkHomePage(),
    ) ;

    TopLevelStateProvider prov = TopLevelStateProvider() ;

    return ChangeNotifierProvider<TopLevelStateProvider> (
      create: (context) => prov,
      child: materialApp,
    );
  }
}