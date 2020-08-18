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

    OverviewScreenAppState OverviewScreenAppState = OverviewScreenAppState();
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
use a ChangeNotifier with the app state.  Note OverviewScreenAppState extends ChangeNotifier and calls
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
import 'package:brmplcapp/common/app_state.dart';

import 'package:brmplcapp/widgets/plc_status_poller_widget.dart';

import 'package:brmplcapp/common/brm_flutter_util.dart';

import 'package:brmplcapp/prx_integ/prx_aggr.dart';

class SettingsScreenAppState extends ChangeNotifier {
  String name = 'Marko' ;       // UI TextField with controller: _nameTEC

  // Contained widgets app-state often makes sense to held here as well.  In those cases this widget
  // will also be a Provider itself.

//  // If the state changes internally and/or externally and we want the widget to have the opportunity
//  // to react, such as doing a setState((){ }), we notify any listeners with notifyListeners() call.
//  // In our scenario assume an external entity, timer, isolate, etc... could change the happy state.
//  // We could notify the widget if it was listening
//  setHappy(bool v) {
//    happy = v ;
//    notifyListeners() ;
//  }

// MrP: HACK: TOTAL STATE hack -- revisit the widget setup and related static aspects
  PrxAggr aggr = AggrProvider.Global.aggr ;
}

class _SettingsScreenEphemeralState extends State {
  SettingsScreenAppState _as ;  // Filled in _appStateBuild()

  //
  // Ephemeral State
  //
//  TextEditingController _nameTEC = TextEditingController() ;

  //
  // General Status -- timestamp, current process/status
  //
  TextEditingController _timestampTEC = TextEditingController() ;
//  TextEditingController _processAndStatusTEC = TextEditingController() ;

  //
  // Misc Behavior
  //
  _changeNotifierListener() {
    setState(() {

    }) ;
  }

  VoidCallback _dataListener ;

  _addDataListener() {
    AggrProvider.Global.addListener(_dataListener) ;
  }

  _removeDataListener() {
    AggrProvider.Global.removeListener(_dataListener) ;
  }

  //
  // Actions
  //
  _actionNameChanged(String v) {
    _as.name = v ;
  }

  //
  // Widgets/Build
  //
  Widget _buildQuickNavs() {
    return Row(children: <Widget>[
      BRMFlutterUtil.flatButton(
          "Overview", () => Navigator.pushNamed(context, Navi.OVERVIEW),
          icon: Icons.filter_hdr, iconPlacement: 9
      ),
      SizedBox(width: 40),
      BRMFlutterUtil.flatButton(
          "Events", () => Navigator.pushNamed(context, Navi.EVENTS),
          icon: Icons.event, iconPlacement: 9
      ),
      SizedBox(width: 40),
      BRMFlutterUtil.flatButton(
          "Mocks", () => Navigator.pushNamed(context, Navi.MOCKS),
          icon: Icons.border_color, iconPlacement: 9, longPress: BRMFlutterUtil.longPressShow(context, 'Go to Mocks screen'),
      ),
      SizedBox(width: 40),
      BRMFlutterUtil.flatButton(
          "Graphs", () => Navigator.pushNamed(context, Navi.GRAPHS),
          icon: Icons.show_chart, iconPlacement: 9
      ),
    ]) ;
  }

  Widget _buildTopControls() {
    Row r = Row(children: <Widget>[
      PlcStatusPollerWidget(),
//      SizedBox(width: 40),
    ]);

    return Container(
      child: r,
    ) ;
  }

  Widget _buildCommonStatus() {
    Widget row = Row(children: <Widget>[
      BRMFlutterUtil.buildTextField('Timestamp', _timestampTEC, (v) => null/*_actionBlanco(v)*/, maxWidth: 150),
//      BRMFlutterUtil.buildTextField('Process/Status', _processAndStatusTEC, (v) => _actionBlanco(v), maxWidth: 600),
    ], mainAxisAlignment: MainAxisAlignment.spaceBetween) ;

    return Container(
      child: row,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 500, height: 60),
    ) ;
  }

  Widget _buildBody() {

    Widget contents = Column(
      children: <Widget>[
        _buildTopControls(),
        SizedBox(height: 40),
        _buildCommonStatus(),
        SizedBox(height: 40),
        _buildQuickNavs(),
      ], crossAxisAlignment: CrossAxisAlignment.start,
    ) ;

    return Container(
      padding: BRMAppFlutterUtil.commonPadding,
      child: contents,
    ) ;
  }

  //
  // App State
  //
  _postFrameCallback(context) {
    _dataListener = () {
      setState(() {
        // We just repaint with the PrxAggr2 aggr = PlcStatusPollerAppState.aggr ;
      }) ;
    } ;

    // We only need to install the listener once.  Make sure we unlisten in dispose()
    // MrP: We add the data listener when we do the start-updates() call.
    _addDataListener() ;
  }

  _appStateBuild() {
    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context) ;
    _as = provider.configScreenAppState ;

    _timestampTEC.text = _as.aggr.timestamp.toString() ;

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

    _removeDataListener() ;

    // Remember that you are preserving the ConfigScreenAppState outside of this context; it is held
    // somewhere higher in the widget-tree and generally in the TopLevelStateProvider held at the
    // app main() level.
    super.dispose() ;
  }

  @override
  didUpdateWidget(SettingsScreenWidget oldWidget) {

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;  // must be first statement

    Scaffold scaff = Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SingleChildScrollView(child: _buildBody()),
    );

    // Since we have a nested widget that requires its own app state, we hold onto that state in "this"
    // instances App State and have a separate "provider" for it.  This makes sense in that the websocket
    // imu widget is a child of "this" instance and thus should NOT be at the root of the entire application.
    // While that could work, it's improperly scoped and we already have multiple screens that could have
    // their own websocket imu connection widget.  Of course, the case for sharing the "connection" widget
    // might be needed at some point its NOT what we want now...
    return MultiProvider(
        providers: [
// The commented providers are used in a number of other screens, see the imu_watcher_screen.dart for actual use
//          ChangeNotifierProvider(builder: (_) => IZImuDataProvider(data: _appState.imuData)),
//          ChangeNotifierProvider(builder: (_) => WebsocketImuDataProvider(_appState.wsImuDataWidgetAppState)),
        ],
        child: scaff
    ) ;
  }
}

class SettingsScreenWidget extends StatefulWidget {
  @override
  _SettingsScreenEphemeralState createState() {
    return _SettingsScreenEphemeralState();
  }
}
