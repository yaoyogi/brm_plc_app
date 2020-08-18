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

    PlcSingleListenPauseAppState PlcSingleListenPauseAppState = PlcSingleListenPauseAppState();
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
use a ChangeNotifier with the app state.  Note PlcSingleListenPauseAppState extends ChangeNotifier and calls
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
import 'package:provider/provider.dart';

//
// App
//
import 'package:brmplcapp/common/app_util.dart';

import 'package:brmplcapp/prx_integ/prx_aggr.dart';
import 'package:brmplcapp/prx_integ/prx_comm.dart';
import 'package:brmplcapp/prx_integ/prx_data_pump.dart';

//
// BarrelRM
//
import 'package:brmplcapp/common/brm_flutter_util.dart';

class PlcSingleListenPauseAppState extends ChangeNotifier {
  bool listenActive = false ;

  // Contained widgets app-state often makes sense to held here as well.  In those cases this widget
  // will also be a Provider itself.

  // If the state changes internally and/or externally and we want the widget to have the opportunity
  // to react, such as doing a setState((){ }), we notify any listeners with notifyListeners() call.
  // In our scenario assume an external entity, timer, isolate, etc... could change the happy state.
  // We could notify the widget if it was listening
  setNewPlcData() {
//    print('PlcSingleListenPauseAppState about to notify its listeners...') ;
    notifyListeners() ;
  }

}

class _PlcSingleListenPauseEphemeralState extends State {
  PlcSingleListenPauseAppState _as ;  // Filled in _appStateBuild()

  //
  // Ephemeral State
  //
  VoidCallback _plcDataListener ;

  _addPlcDataListener() {
    AggrProvider.Global.addListener(_plcDataListener) ;
  }

  _removePlcDataListener() {
    AggrProvider.Global.removeListener(_plcDataListener) ;
  }

  //
  // Misc Behavior
  //
  _changeNotifierListener() {
    setState(() {

    }) ;
  }

  _notifyWidgetParentsAndSetStateLocally() {
    _as.setNewPlcData();

    setState(() {
      // We just repaint with the PrxAggr2 aggr = PlcStatusPollerAppState.aggr ;
    });
  }

  //
  // Actions
  //
  _actionButtonSingle() {
    BRMFlutterUtil.toast(context, 'single') ;
    PrxComm.getPlcData().then((r) {
      if (r != null) {
        AggrProvider.Global.aggr.from_bytes(r);
        AggrProvider.Global.update();

        // We explicitly do the setState() to get refresh the UI to the updates. This is because the
        // PLC data listener is NOT active if we are doing a single op.
        _notifyWidgetParentsAndSetStateLocally() ;
      }
    }) ;
  }

  _actionButtonListen() {
    BRMFlutterUtil.toast(context, 'listen') ;
    if (PrxDataPump.isStopped) {
      BRMFlutterUtil.brmShowAlertDialog(context, 'Unable to Listen', '"Start" master polling in the settings screen') ;
      return ;
    }
    else if (PrxDataPump.isPaused) {
      BRMFlutterUtil.brmShowAlertDialog(context, 'Unable to Listen', '"Resume master" polling in the settings screen') ;
      return ;
    }

    setState(() {
      _as.listenActive = true ;
    }) ;
  }

  _actionButtonPause() {
    BRMFlutterUtil.toast(context, 'pause') ;
    setState(() {
      _as.listenActive = false ;
    }) ;
  }

  //
  // Widgets/Build
  //
  Widget _buildIsoControls() {
    var singleButtonEnabled = !_as.listenActive ;  // !PrxDataPump.isStarted &&
    FlatButton statusButton = BRMFlutterUtil.flatButton(
        'Single', singleButtonEnabled ? _actionButtonSingle : null, iconPlacement: 9, icon: Icons.adjust
    ) ;

    FlatButton startUpdatesButton = BRMFlutterUtil.flatButton(
        'Listen', _as.listenActive ? null : _actionButtonListen, iconPlacement: 9, icon: Icons.play_arrow
    ) ;

    FlatButton pauseUpdatesButton = BRMFlutterUtil.flatButton(
        'Pause', _as.listenActive ? _actionButtonPause : null, iconPlacement: 9, icon: Icons.pause
    ) ;

    Row buttons = Row(
      children: <Widget>[
        statusButton, startUpdatesButton, pauseUpdatesButton,
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    ) ;

    Container cbuttons = Container(
      child: buttons,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 400, height: 70),
    ) ;

    return cbuttons ;

//    return Container(
//      child: cbuttons,
//      constraints: BoxConstraints.expand(width: 1000, height: 70),
//    ) ;
  }

  Widget _buildBody() {
    return _buildIsoControls() ;
  }

  //
  // App State
  //
  _postFrameCallback(context) {
    _plcDataListener = () {
      // We are getting called because the global Aggr has some new data.  We want to have OUR
      // listeners who are registered with our app state!
      if (_as.listenActive) {
        _notifyWidgetParentsAndSetStateLocally() ;
      }
    } ;

    // We only need to install the listener once.  Make sure we unlisten in dispose()
    // MrP: We add the data listener when we do the start-updates() call.
    _addPlcDataListener();
  }

  _appStateBuild() {
    // MrP: !! Note this widget COMPLETELY relies on the client of this widget providing the app-statte instance!
    // This is done in the clients build(BuildContext) method by returning a MultiProvider wrapper.  The
    // _as.NEEDED_APP_STATE_MEMBER is where the clients app state is holding onto the THIS instances app-state!
    //
    //    Widget build(BuildContext context) {
    //      _appStateBuild(); // must be first
    //      ...
    //      Scaffold scaff = Scaffold(...)
    //      return MultiProvider(
    //          providers: [
    //            ChangeNotifierProvider(builder: (_) => PlcSingleListenPauseWidgetDataProvider(data: _as.NEEDED_APP_STATE_MEMBER)),
    //            ...
    //          ],
    //          child: scaff
    //      );
    //    }
    PlcSingleListenPauseWidgetDataProvider p = Provider.of<PlcSingleListenPauseWidgetDataProvider>(context) ;
    _as = p.data ;

    if (! _as.hasListeners) {
      // We only need to add this once for lifetime of widget, we remove in dispose().  Note that we
      // DON'T use anonymous closure since we need to remove the same listener in dispose so having
      // a function ref works.
      _as.addListener(_changeNotifierListener) ;
    }
  }

  //
  // Framework overrides
  //
  @override
  initState() {
    // Empty at this point.  This is app state heavy so nearly everything is in appstate

    super.initState();

    // Do this LAST and for sure after super.initState()
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallback(context)) ;
  }

  @override
  dispose() {
    // We don't want notifications going to a stale widget that no longer exists!
    _as.removeListener(_changeNotifierListener) ;

    _removePlcDataListener() ;

    // Remember that you are preserving the PlcSingleListenPauseAppState outside of this context; it is held
    // somewhere higher in the widget-tree and generally in the TopLevelStateProvider held at the
    // app main() level.
    super.dispose() ;
  }

  @override
  didUpdateWidget(PlcSingleListenPauseWidget oldWidget) {

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;  // must be first statement

    var widget = SingleChildScrollView(child: Container(
//      padding: BRMAppFlutterUtil.commonPadding,
      child: _buildBody(),
    )
    ) ;

    return widget ;
  }
}

class PlcSingleListenPauseWidget extends StatefulWidget {
  @override
  _PlcSingleListenPauseEphemeralState createState() {
    return _PlcSingleListenPauseEphemeralState();
  }
}

/// The widget parentage of the ImuDataVcrWidget needs to expose this via a Provider.
class PlcSingleListenPauseWidgetDataProvider extends ChangeNotifier {
  PlcSingleListenPauseAppState data ;

  PlcSingleListenPauseWidgetDataProvider(this.data) ;

  update() {
    notifyListeners() ;
  }
}
