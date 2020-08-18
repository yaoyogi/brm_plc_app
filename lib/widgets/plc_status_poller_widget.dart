/*
Strictly follow this model which is clear separation of Ephemeral and App state.

The Ephemeral state will hold onto the App state.

 The App state:
    should use common names and not be bound to particular names like xxxDropDown or xxxTextFieldValue etc...
    Should have NO dependencies on UI artifacts
    It's a "data" construct, avoid biz behavior etc...
    It may need to be serialized and/or stored persistently so limit complex types
    When complex types can't be avoided use non-UI members to reconstruct it
    May hold other app-states.  If the screen uses widgets that themselves have app-state, your app-state
      is often the most logical place to hold onto them.  See imu_data_access_widget.dart and its uses
      for exactly this scenario.

 The App state will be created/held external to the ephemeral state somewhere "up" the widget hierarchy.
 Often that will be the root app widget.  The app state is "provided" using the Flutter Provider package.

Flutter Provider
-----------------
We are using the following in pubspec.yaml
  provider: ^3.0.0


 app_state.dart has the App-level provider:
 ------------------------------------------
 class TopLevelStateProvider extends ChangeNotifier {
    static TopLevelStateProvider getProvider(BuildContext ctx) {
      return Provider.of<TopLevelStateProvider>(ctx) ;
    }

    MocksScreenAppState someScreenAppState = MocksScreenAppState();
    ...

    update() {
      notifyListeners() ;
    }
  }

  This provider is exposed in the widget tree so that descendant widgets can "look them up" as needed.

  For this example the main.dart's build(context) {

    TopLevelStateProvider prov = TopLevelStateProvider() ;

    var cnp = ChangeNotifierProvider<TopLevelStateProvider> (
      builder: (context) => prov,
      child: materialApp,
    );

    return MultiProvider(
      providers: [ ],
      child: cnp,
    ) ;
  }

 Post-frame usage
 ----------------
 There are cases where you need the entire widget tree intact to apply some state/behavior.
 We have standardized on:

   _postFrameCallback(context) {
    // Empty for now
  }

 The callback is setup as the LAST statement in the normal initState() lifecycle

 Common handling scenarios
 --------------------------

 TextFields
    Use onChanged: (v) => _appState.xxx = v,

        // Do conversion to int, double here if needed
        onChanged: (v) => _appState.xxx = int.parse(v)
        onChanged: (v) => _appState.xxx = double.parse(v)

    The text/form fields should have their initial values assigned in the _appStateBuild()
        _someTEC.text = _appState.someValue.toString()

 Dropdowns
    init with app state and update app state when changed

 Toggle buttons
    init with app state and update app state when changed

 Sliders
    init with app state and update app state when changed

 Buttons
  In general there isn't much state for the buttons.  You will often see that a button is enabled or not
  based on ephemeral/app state, but that doesn't require us doing anything special.

Model/State async changes communication to widget
-------------------------------------------------
In many/most cases the Widget is rebuilt to react to changes in the model/state.  Often those changes
are a result of the Widget itself, such as a button press or text-field change and then that code can
do a setState(() { }).  There are cases where the state/model changed for example due to an internal
and/or external activity such as an Isolate communication, or a Timer etc... The model/state does NOT
have access to the Widget and thus itself could not call setState((){ }).  For these scenarios we can
use a ChangeNotifier with the app state.  Note MocksScreenAppState extends ChangeNotifier and calls
notifyListeners() in the setHappy(bool) method.  The listener for this notification is setup in the
_appStateBuild() call.

Other
--------------
This is also not a bad example of creating a new screen/widget...

For adding tweak space, use: SizedBox(height: 10.0) and not Text('   ')
 */

//
// Flutter
//
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//
// App
//
import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/prx_integ/prx_data_pump.dart';
import 'package:brmplcapp/prx_integ/prx_aggr.dart';
import 'package:brmplcapp/prx_integ/prx_comm.dart';

//
// Ismintis
//
import 'package:brmplcapp/common/brm_flutter_util.dart';

class PlcStatusPollerAppState extends ChangeNotifier {

}

class _PlcStatusPollerEphemeralState extends State<PlcStatusPollerWidget> {

  //
  // Build
  //
  _appStateBuild() {
//    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context);
//    _as = provider.mocksScreenAppState;
//
//    if (!_as.hasListeners) {
//      // We only need to add this once for lifetime of widget, we remove in dispose().  Note that we
//      // DON'T use anonymous closure since we need to remove the same listener in dispose so having
//      // a function ref works.
//      _as.addListener(_changeNotifierListener);
//    }
  }

  Widget _buildIsoControls() {
    FlatButton statusButton = BRMFlutterUtil.flatButton(
        'Single', PrxDataPump.isStarted ? null : _actionGetSingleUpdate, iconPlacement: 9, icon: Icons.adjust
    ) ;

    FlatButton startUpdatesButton = BRMFlutterUtil.flatButton(
        'Start', PrxDataPump.isStarted ? null : _actionStartUpdates, iconPlacement: 9, icon: Icons.play_arrow
    ) ;

    FlatButton pauseUpdatesButton = BRMFlutterUtil.flatButton(
        'Pause', (PrxDataPump.isPaused || !PrxDataPump.isStarted) ? null : _actionPauseUpdates, iconPlacement: 9, icon: Icons.pause
    ) ;

    FlatButton resumeUpdatesButton = BRMFlutterUtil.flatButton(
        'Resume', PrxDataPump.isPaused ? _actionResumeUpdates : null, iconPlacement: 9, icon: Icons.refresh
    ) ;

    FlatButton stopUpdatesButton = BRMFlutterUtil.flatButton(
        'Stop', PrxDataPump.isStarted ? _actionStopUpdates : null, iconPlacement: 9, icon: Icons.stop
    ) ;

    Row buttons = Row(
      children: <Widget>[
        statusButton, startUpdatesButton, pauseUpdatesButton, resumeUpdatesButton, stopUpdatesButton,
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    ) ;

    Container cbuttons = Container(
      child: buttons,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 800, height: 70),
    ) ;

    return cbuttons ;

//    return Container(
//      child: cbuttons,
//      constraints: BoxConstraints.expand(width: 1000, height: 70),
//    ) ;
  }

  //
  // Misc Behavior
  //

  //
  // Actions
  //

  _actionStartUpdates() async {
    print('About to start updates') ;
    await PrxDataPump.start() ;
//    _addDataListener() ;
    print('pump started...') ;
    setState(() { }) ;

  }

  _actionPauseUpdates() {
    print('About to pause updates') ;
    setState(() {
      PrxDataPump.pause() ;
    }) ;
  }

  _actionResumeUpdates() {
    print('About to resume updates') ;
    setState(() {
      PrxDataPump.resume() ;
    }) ;
  }

  _actionStopUpdates() {
    print('About to stop updates') ;
    setState(() {
//      _removeDataListener() ;
      PrxDataPump.stop() ;
    }) ;
  }

  _actionGetSingleUpdate() {
    PrxComm.getPlcData().then((r) {
      if (r != null) {
        AggrProvider.Global.aggr.from_bytes(r);
        AggrProvider.Global.update();
      }
    }) ;
  }

  //
  // Framework Overrides
  //
  @override
  initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild(); // must be first statement

    return Container(
      constraints: BoxConstraints(maxHeight: 500, minWidth: 500, maxWidth: 500),
      child: SingleChildScrollView(child: _buildIsoControls()),
    );
  }
}


class PlcStatusPollerWidget extends StatefulWidget {
  PlcStatusPollerWidget()  {
    // Empty on purpose
  }

  @override
  _PlcStatusPollerEphemeralState createState() => _PlcStatusPollerEphemeralState() ;
}

//  _actionGetSingleUpdate_old() {
////      IZFlutterUtil.toast(context, "Making call to get status") ;
//    print('hello...') ;
//    BRMHttpUtil.httpPost(
//        "http://192.168.1.177/all",
//        headers: {'brm': 'prx'},
//        showErrDialog: false, context: null,
//        timeout: Duration(seconds: 1),
//        success: ((httpResponse) {
//          var r = httpResponse.bodyBytes ;
////            print(r) ;
//          setState(() {
//            // We take the PLC status binary and update the
//            AggrProvider.Global.aggr.from_bytes(r) ;
//            AggrProvider.Global.update() ;
////            PlcStatusPollerAppState.aggr.from_bytes(r) ;
////            PrxDataPump.provider.update() ;
//
//          }) ;
////          PrxAggr2 px2 = PlcStatusPollerAppState.aggr ;
////          print('updated from bytes, $px2') ;
////            print('updated _as.aggr.from_bytes(r)') ;
//
////            print(r) ;
////            PrxAggr2 aggr = PrxAggr2() ;
////            aggr.from_bytes(r) ;
////
////            print(aggr) ;
//
//        }),
//        onReqErr: (resp) {
////            c.complete(resp.body) ;
//          BRMFlutterUtil.toast(context, "Refresh Error, Request Problem.  " + resp.body) ;
////            IZFlutterUtil.izShowAlertDialog(context, 'Refresh Error, Request Problem', resp.body) ;
//        },
//        onTimeout: () {
////            c.complete('Request timed out') ;
//          BRMFlutterUtil.toast(context, "Refresh Error, Request timed out.  ") ;
////            IZFlutterUtil.izShowAlertDialog(context, 'Refresh Error', 'Request timed out') ;
//        }
//    );
//  }
