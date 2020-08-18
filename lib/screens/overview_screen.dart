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

import 'package:brmplcapp/prx_integ/prx_comm.dart';
import 'package:brmplcapp/prx_integ/prx_aggr.dart';
import 'package:brmplcapp/prx_integ/prx_data_pump.dart';

import 'package:brmplcapp/prx_integ/valve_dev.dart';
import 'package:brmplcapp/prx_integ/switch_dev.dart';
import 'package:brmplcapp/prx_integ/pressure_dev.dart';
import 'package:brmplcapp/prx_integ/temperature_dev.dart';

import 'package:brmplcapp/widgets/plc_single_listen_stop.dart' ;

import 'package:brmplcapp/common/brm_flutter_util.dart';

typedef SwitchDevCallback = void Function(SwitchDev dev);

class OverviewScreenAppState extends ChangeNotifier {
//  String name = 'Marko' ;       // UI TextField with controller: _nameTEC
//  bool happy = true ;         // UI: toggle button
//  double rating = -1.0 ;      // UI: slider
//  String confidence = 'High'; // UI: dropdown button

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

  PlcSingleListenPauseAppState _singleListenPauseAppState = PlcSingleListenPauseAppState() ;
}

class _SomeScreenEphemeralState extends State {
  OverviewScreenAppState _as ;  // Filled in _appStateBuild()

  //
  // Ephemeral State
  //

  //
  // General Status -- timestamp, current process/status
  //
  TextEditingController _timestampTEC = TextEditingController() ;
  TextEditingController _processAndStatusTEC = TextEditingController() ;

  //
  // Temperature
  //
  // RTD Mod-A
  /* Main tank */
  TextEditingController _temperature_1TEC = TextEditingController() ;
  TextEditingController _temperature_2TEC = TextEditingController() ;
  TextEditingController _temperature_3TEC = TextEditingController() ;

  // RTD Mod-B
  TextEditingController _temperature_5TEC = TextEditingController() ;
  TextEditingController _temperature_6TEC = TextEditingController() ;

  //
  // Pressure
  //
  TextEditingController _pressure_1TEC = TextEditingController() ;
  TextEditingController _pressure_2TEC = TextEditingController() ;
  TextEditingController _pressure_3TEC = TextEditingController() ;

  /* Heat exchanger */
  TextEditingController _pressure_4TEC = TextEditingController() ;

  //
  // Misc Behavior
  //
  _changeNotifierListener() {
    setState(() {

    }) ;
  }

  void _plcDataListener() {
    setState(() {
      // We just repaint with the PrxAggr2 aggr = PlcStatusPollerAppState.aggr ;
    }) ;
  }

  //
  // Actions
  //
  _actionUpdatePlcValve(ValveDev dev) {
    if (PrxDataPump.isStarted && ! PrxDataPump.isPaused) {
      BRMFlutterUtil.brmShowAlertDialog(
          context, 'Discrete Updates Disabled', ' Auto-updating is active.\n\nClick Pause to enable discrete updates');
      return ;
    }

    PrxComm.updateValve(dev).then((result) {
      if (result == null) {
        BRMFlutterUtil.brmShowAlertDialog(
            context, 'Valve Update Failed', ' Error: $result');
      }
      else {
        // If we aren't doing auto updates, we reflect the new value ourselves
        if (PrxDataPump.isStopped || PrxDataPump.isPaused) {
          setState(() {
            dev.state = !dev.state;
          });
          print('${dev.id} now: ${dev.state}');
        }
      }
    }) ;
  }

  _actionUpdatePlcSwitch(SwitchDev dev) {
    if (PrxDataPump.isStarted && _as._singleListenPauseAppState.listenActive) {
      BRMFlutterUtil.brmShowAlertDialog(
          context, 'Discrete Updates Disabled',
          ' Auto-updating is active.\n\nClick Pause to enable discrete updates');
      return;
    }

    PrxComm.updateSwitch(dev).then((result) {
      if (result == null) {
        BRMFlutterUtil.brmShowAlertDialog(
            context, 'Switch Update Failed', ' Error: $result');
      }
      else {
        // If we aren't doing auto updates, we reflect the new value ourselves
        if (PrxDataPump.isStopped || PrxDataPump.isPaused || !_as._singleListenPauseAppState.listenActive) {
          setState(() {
            dev.state = !dev.state;
          });
          print('${dev.id} now: ${dev.state}');
        }
      }
    }) ;
  }

  //
  // Widgets/Build
  //
  IconData _getValveIconData(bool v) {
    return v ? Icons.opacity : Icons.close  ;
  }
  IconData _getOutputSwitchIconData(bool v) {
    return v ?  Icons.radio_button_checked : Icons.close ;
  }
  Color _getOnOffColor(bool v) {
    return v ? Colors.green : Colors.blueGrey ;
  }

  Widget _buildTopControls() {
    Row r = Row(children: <Widget>[
      PlcSingleListenPauseWidget(),
      SizedBox(width: 40),
      _buildQuickNavs(),
    ]);

    return Container(
      child: r,
    ) ;
  }

  Widget _buildQuickNavs() {
    bool watcherDisabled = (AppEnv.esp32DeviceIpAddr != '192.168.1.200')  ;
    return Row(children: <Widget>[
      BRMFlutterUtil.flatButton(
          "Settings", () => Navigator.pushNamed(context, Navi.SETTINGS),
          icon: Icons.settings, iconPlacement: 9
      ),
      SizedBox(width: 40),
      BRMFlutterUtil.flatButton(
          "Events", () => Navigator.pushNamed(context, Navi.EVENTS),
          icon: Icons.event, iconPlacement: 9
      ),
      SizedBox(width: 40),
      BRMFlutterUtil.flatButton(
          "Graphs", () => Navigator.pushNamed(context, Navi.GRAPHS),
          icon: Icons.show_chart, iconPlacement: 9
      ),
      SizedBox(width: 40),
      BRMFlutterUtil.flatButton(
          "Mocks", () => Navigator.pushNamed(context, Navi.MOCKS),
          icon: Icons.border_color, iconPlacement: 9
      ),
    ]) ;
  }

  Widget _buildValve(ValveDev dev) {
    FlatButton button = BRMFlutterUtil.flatButton(dev.id, () {
      _actionUpdatePlcValve(dev) ;
    }, iconPlacement: 9, icon: _getValveIconData(dev.state), color: _getOnOffColor(dev.state),
    ) ;

    return button ;
  }

//  Widget _buildOutputSwitch_no_op(SwitchDev dev) {
//    FlatButton button = BRMFlutterUtil.flatButton(dev.desc, ()=> null, iconPlacement: 9, icon: getOutputSwitchIconData(dev.state), color: getOnOffColor(dev.state),
//    ) ;
//
//    return button ;
//  }

  Widget _buildOutputSwitch(SwitchDev dev) {
    FlatButton button = BRMFlutterUtil.flatButton(dev.desc, () {
      _actionUpdatePlcSwitch(dev) ;
    }, iconPlacement: 9, icon: _getOutputSwitchIconData(dev.state), color: _getOnOffColor(dev.state),
    ) ;

    return button ;
  }

  Widget _buildInputOnlySwitch(SwitchDev dev) {
    FlatButton button = BRMFlutterUtil.flatButton(dev.desc, () {
      BRMFlutterUtil.brmShowAlertDialog(context, 'Read-only Switch', "Switch: '${dev.id}' is read-only") ;
    }, iconPlacement: 9, icon: _getOutputSwitchIconData(dev.state), color: _getOnOffColor(dev.state),
    ) ;

    return button ;
  }

  _actionBlanco(v) {

  }

  Widget _buildCommonStatus() {
    Widget row = Row(children: <Widget>[
      BRMFlutterUtil.buildTextField('Timestamp', _timestampTEC, (v) => _actionBlanco(v), maxWidth: 120),
      BRMFlutterUtil.buildTextField('Process/Status', _processAndStatusTEC, (v) => _actionBlanco(v), maxWidth: 400),
    ], mainAxisAlignment: MainAxisAlignment.spaceBetween) ;

    return Container(
      child: row,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 800, height: 60),
    ) ;
  }

//  Widget _buildTempWidget(String title, TextEditingController tec) {
//    Text text ;
//    double v = double.parse(tec.text) ;
//    if (v > 90) {
//      text = Text(title, style: TextStyle(color: Colors.red)) ;
//    }
//    else if (v > 60) {
//      text = Text(title, style: TextStyle(color: Colors.yellow)) ;
//    }
//    else {
//      text = Text(title, style: TextStyle(color: Colors.green)) ;
//    }
//
//    Widget tf = BRMFlutterUtil.buildTextField(text, tec, ((v) {
//      // MrP: NOTE: This is NOT called unless the operator edits the field value -- which in our
//      // usecases should never happen...
////      print(v) ;
//    }), maxWidth: 100) ;
//    return tf ;
//  }

  Widget _buildTempWidget(TemperatureDev dev, TextEditingController tec) {
    String id = dev.id ;
    int idLen = id.length ;

    String desc = dev.desc ;
    int descLen = desc.length ;
    if (idLen > descLen) {
      id += '  ' ;
    }
    else {
      desc += '  ' ;
    }
    String label = id + '\n' + desc ;

    double v = dev.fahrenheit ; //double.parse(tec.text) ;

    Text text = Text(label) ;

    TextStyle fieldStyle ;
    if (v > dev.maxFahrenheit * 0.9) {
      fieldStyle = TextStyle(color: Colors.red) ;
    }
    else if (v < dev.minFahrenheit * 0.9) {
      fieldStyle = TextStyle(color: Colors.blue) ;
    }
    else if (v > dev.maxFahrenheit * 0.7) {
      fieldStyle = TextStyle(color: Colors.yellow) ;
    }
    else {
      fieldStyle = TextStyle(color: Colors.white) ;
    }

    Widget tf = BRMFlutterUtil.buildTextField(text, tec, ((v) {
      // MrP: NOTE: This is NOT called unless the operator edits the field value -- which in our
      // usecases should never happen...
//      print(v) ;
    }), maxWidth: 100, fieldStyle: fieldStyle) ;
    return tf ;
  }

  Widget _buildPressureWidget(PressureDev dev, TextEditingController tec) {
    String id = dev.id ;
    int idLen = id.length ;

    String desc = dev.desc ;
    int descLen = desc.length ;
    if (idLen > descLen) {
      id += '  ' ;
    }
    else {
      desc += '  ' ;
    }
    String label = id + '\n' + desc ;

    double v = dev.psi ; //double.parse(tec.text) ;

    Text text = Text(label) ;

    TextStyle fieldStyle ;
    if (v > dev.maxPsi * 0.9) {
      fieldStyle = TextStyle(color: Colors.red) ;
    }
    else if (v < dev.minPsi * 0.9) {
      fieldStyle = TextStyle(color: Colors.blue) ;
    }
    else if (v > dev.maxPsi * 0.7) {
      fieldStyle = TextStyle(color: Colors.yellow) ;
    }
    else {
      fieldStyle = TextStyle(color: Colors.white) ;
    }

    Widget tf = BRMFlutterUtil.buildTextField(text, tec, ((v) {
      // MrP: NOTE: This is NOT called unless the operator edits the field value -- which in our
      // usecases should never happen...
//      print(v) ;
    }), maxWidth: 100, fieldStyle: fieldStyle) ;
    return tf ;
  }

//  Widget _buildPressureWidget(String title, TextEditingController tec) {
//    return BRMFlutterUtil.buildTextField(title, tec, ((v) {
//      // MrP: NOTE: This is NOT called unless the operator edits the field value -- which in our
//      // usecases should never happen...
////      print(v) ;
//    }), maxWidth: 80) ;
//  }

  Widget _buildTemperatures() {
    Widget row = Row(children: <Widget>[
      _buildTempWidget(_as.aggr.temp_1, _temperature_1TEC),
      _buildTempWidget(_as.aggr.temp_2, _temperature_2TEC),
      _buildTempWidget(_as.aggr.temp_3, _temperature_3TEC),
      _buildTempWidget(_as.aggr.temp_5, _temperature_5TEC),
      _buildTempWidget(_as.aggr.temp_6, _temperature_6TEC),
    ], mainAxisAlignment: MainAxisAlignment.spaceBetween) ;

    return Container(
      child: row,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 1200, height: 80),
    ) ;
  }

  Widget _buildPressures() {
    Widget row = Row(children: <Widget>[
      _buildPressureWidget(_as.aggr.pressure_1, _pressure_1TEC),
      _buildPressureWidget(_as.aggr.pressure_2, _pressure_2TEC),
      _buildPressureWidget(_as.aggr.pressure_3, _pressure_3TEC),
      _buildPressureWidget(_as.aggr.pressure_4, _pressure_4TEC),
//      Spacer(flex: 1),
    ], mainAxisAlignment: MainAxisAlignment.spaceBetween) ;

    return Container(
      child: row,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 900, height: 80),
    ) ;
  }

  Widget _buildValves() {
    Row r = Row(children: <Widget>[
      Column(children: <Widget>[
        _buildValve(_as.aggr.valve_02),
        _buildValve(_as.aggr.valve_03),
        _buildValve(_as.aggr.valve_04),
      ]),

      Column(children: <Widget>[
        Text('Thermo Shunt'),
        _buildValve(_as.aggr.valve_61),
      ]),

      Column(children: <Widget>[
        _buildValve(_as.aggr.valve_12),
        Text('Tank-2 in/out'),
        _buildValve(_as.aggr.valve_11),
      ]),

      Column(children: <Widget>[
        _buildValve(_as.aggr.valve_22),
        Text('Tank-3 in/out'),
        _buildValve(_as.aggr.valve_21),
      ]),

      Column(children: <Widget>[
        _buildValve(_as.aggr.valve_32),
        Text('O2-stone in/out'),
        _buildValve(_as.aggr.valve_31),
      ]),

      Column(children: <Widget>[
        _buildValve(_as.aggr.valve_42),
        Text('Sonicator in/out'),
        _buildValve(_as.aggr.valve_41),
      ]),

      Column(children: <Widget>[
        _buildValve(_as.aggr.valve_52),
        Text('Filter-tank in/out'),
        _buildValve(_as.aggr.valve_51),
      ]),

      // Relay-B
      Column(children: <Widget>[
        _buildValve(_as.aggr.valve_72),
        Text('Heating System'),
        _buildValve(_as.aggr.valve_71),

      ]),

      Column(children: <Widget>[
        _buildValve(_as.aggr.valve_74),
        Text('Cooling System'),
        _buildValve(_as.aggr.valve_73),
      ]),
    ], mainAxisAlignment: MainAxisAlignment.spaceAround) ;

    return Container(
      child: r,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 1200, height: 170),
    ) ;
  }

  Widget _buildOuputSwitches() {
    Row r = Row(children: <Widget>[
      Column(children: <Widget>[
        _buildOutputSwitch(_as.aggr.sw_circulation_pump),
        _buildOutputSwitch(_as.aggr.sw_transfer_pump),
      ]),

      Column(children: <Widget>[
        _buildOutputSwitch(_as.aggr.sw_o2stone),
        _buildOutputSwitch(_as.aggr.sw_sonicator),
      ]),

      Column(children: <Widget>[
        _buildOutputSwitch(_as.aggr.sw_heater),
        _buildOutputSwitch(_as.aggr.sw_heater_pump),
      ]),

      Column(children: <Widget>[
        _buildOutputSwitch(_as.aggr.sw_chiller),
        _buildOutputSwitch(_as.aggr.sw_chiller_pump),
      ]),
    ],
//        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround);

    Container c = Container(
      child: r,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 600, height: 120),
    ) ;

    return c ;
  }

  Widget _buildSimSwitches() {
    Row r = Row(children: <Widget>[
      _buildInputOnlySwitch(_as.aggr.sw_sim1),
      _buildInputOnlySwitch(_as.aggr.sw_sim2),
      _buildInputOnlySwitch(_as.aggr.sw_sim3),
      _buildInputOnlySwitch(_as.aggr.sw_sim4),
      _buildInputOnlySwitch(_as.aggr.sw_sim5),
      _buildInputOnlySwitch(_as.aggr.sw_sim6),
      _buildInputOnlySwitch(_as.aggr.sw_sim7),
      _buildInputOnlySwitch(_as.aggr.sw_sim8),
    ], mainAxisAlignment: MainAxisAlignment.spaceAround) ;

    Container c = Container(
      child: r,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 900, height: 60),
    ) ;

    return c ;
  }

  Widget _buildInputSwitches() {
    Row r = Row(children: <Widget>[
      _buildInputOnlySwitch(_as.aggr.swin_flow),
      _buildInputOnlySwitch(_as.aggr.swin_2),
      _buildInputOnlySwitch(_as.aggr.swin_3),
      _buildInputOnlySwitch(_as.aggr.swin_4),
      _buildInputOnlySwitch(_as.aggr.swin_5),
      _buildInputOnlySwitch(_as.aggr.swin_6),
      _buildInputOnlySwitch(_as.aggr.swin_7),
      _buildInputOnlySwitch(_as.aggr.swin_8),
    ], mainAxisAlignment: MainAxisAlignment.spaceAround) ;

    Container c = Container(
      child: r,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints.expand(width: 900, height: 60),
    ) ;

    return c ;
  }

  Widget _buildBody() {

    Widget contents = Column(
      children: <Widget>[
        _buildTopControls(),
        SizedBox(height: 20),
        _buildCommonStatus(),
        SizedBox(height: 20),
        _buildOuputSwitches(),
        SizedBox(height: 20),
        _buildValves(),
        SizedBox(height: 20),
        _buildInputSwitches(),
        SizedBox(height: 20),
        _buildPressures(),
        SizedBox(height: 20),
        _buildTemperatures(),
        SizedBox(height: 20),
        _buildSimSwitches(),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    ) ;

    return Container(
      padding: BRMAppFlutterUtil.commonPadding,
//      child: contents, //Expanded(child: contents),
        child: SingleChildScrollView(child: contents, scrollDirection: Axis.horizontal),
    ) ;
  }

  //
  // App State
  //
  _postFrameCallback(context) {
//    print("!!> _postFrameCallback(context)") ;

    // We only need to install the listener once.  Make sure we unlisten in dispose()
    // MrP: We add the data listener when we do the start-updates() call.
//    _addDataListener() ;
    _as._singleListenPauseAppState.addListener(_plcDataListener) ;
  }

  _appStateBuild() {
    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context) ;

    _as = provider.overviewScreenAppState ;

    //
    // General
    //
    _timestampTEC.text = _as.aggr.timestamp.toString() ;
    _processAndStatusTEC.text = '' ; //IBC tx in progress, 45 gallons transferred' ;

    //
    // Temperature
    //
    _temperature_1TEC.text = _as.aggr.temp_1.fahrenheit.toStringAsFixed(2) ;
    _temperature_2TEC.text = _as.aggr.temp_2.fahrenheit.toStringAsFixed(2) ;
    _temperature_3TEC.text = _as.aggr.temp_3.fahrenheit.toStringAsFixed(2) ;

    // RTD Mod-B
    _temperature_5TEC.text = _as.aggr.temp_5.fahrenheit.toStringAsFixed(2) ;
    _temperature_6TEC.text = _as.aggr.temp_6.fahrenheit.toStringAsFixed(2) ;

    //
    // Pressure
    //
    _pressure_1TEC.text = _as.aggr.pressure_1.psi.toStringAsFixed(2) ;
    _pressure_2TEC.text = _as.aggr.pressure_2.psi.toStringAsFixed(2) ;
    _pressure_3TEC.text = _as.aggr.pressure_3.psi.toStringAsFixed(2) ;
    _pressure_4TEC.text = _as.aggr.pressure_4.psi.toStringAsFixed(2) ;  /* Heat exchanger */


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

    _as._singleListenPauseAppState.removeListener(_plcDataListener) ;

    // Remember that you are preserving the OverviewScreenAppState outside of this context; it is held
    // somewhere higher in the widget-tree and generally in the TopLevelStateProvider held at the
    // app main() level.
    super.dispose() ;
  }

  @override
  didUpdateWidget(OverviewScreenWidget oldWidget) {

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;  // must be first statement

    Scaffold scaff = Scaffold(
      appBar: AppBar(title: Text('Processor Overview')),
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
          ChangeNotifierProvider(builder: (_)
            => PlcSingleListenPauseWidgetDataProvider(_as._singleListenPauseAppState)),
        ],
        child: scaff
    ) ;
  }
}

class OverviewScreenWidget extends StatefulWidget {
  @override
  _SomeScreenEphemeralState createState() {
    return _SomeScreenEphemeralState();
  }
}



//            print('buf size: {$r.size}') ;
//            var bd = r.buffer.asByteData() ;
//
//            //
//            // Timestamp
//            //
//            int timestamp = bd.getUint32(0, Endian.little) ;
//            print('timestamp: $timestamp') ;
//
//            //
//            // Valves
//            //
//            int valves = bd.getUint32(4, Endian.little) ;
//            print(valves.toBinaryPadded(32)) ;
//
//            //
//            // Temperature
//            //
//            double temp1 = bd.getFloat32( 8, Endian.little) ;
//            double temp2 = bd.getFloat32(12, Endian.little) ;
//            double temp3 = bd.getFloat32(16, Endian.little) ;
//            double temp5 = bd.getFloat32(20, Endian.little) ;
//            double temp6 = bd.getFloat32(24, Endian.little) ;
//
//            print('temp ${temp1}, ${temp2}, ${temp3}, ${temp5}, ${temp6}') ;
//
//            //
//            // Pressure
//            //
//            double pressure1 = bd.getFloat32(28, Endian.little) ;
//            double pressure2 = bd.getFloat32(32, Endian.little) ;
//            double pressure3 = bd.getFloat32(36, Endian.little) ;
//            double pressure4 = bd.getFloat32(40, Endian.little) ;
//
//            print('pressure ${pressure1}, ${pressure2}, ${pressure3}, ${pressure4}') ;
//
//            //
//            // Input Switches
//            //
//            int input_switches = bd.getUint8(44) ; // no Endian needed as it is single byte
//            print('input switches:  ${input_switches.toBinaryPadded(8)}') ;
//
//            //
//            // Output Switches
//            //
//            int output_switches =  bd.getUint8(45) ; // no Endian needed as it is single byte
//            print('output switches: ${output_switches.toBinaryPadded(8)}') ;
//
//            //
//            // Motor/Pump/Device Settings
//            //
//            int sonicator_setting = bd.getUint16(46, Endian.little) ;
//
//            int o2stone_setting = bd.getUint16(48, Endian.little) ;
//
//            int heater_setting = bd.getUint16(50, Endian.little) ;
//
//            int chiller_setting = bd.getUint16(52, Endian.little) ;
//
//            print('sonicator: $sonicator_setting, o2stone: $o2stone_setting, heater: $heater_setting, chiller: $chiller_setting') ;
//
//            print(r) ;


//Widget _buildValveToggleButtons() {
//  ToggleButtons tbs = ToggleButtons(
//    children: [
//      Column(children: [
//        Icon(Icons.directions_bike),
//        Text('01'),
//      ]),
//      Icon(Icons.directions_boat),
//      Icon(Icons.directions_bus),
//      Icon(Icons.directions_car),
//      Icon(Icons.directions_railway),
//    ],
//    isSelected: _as.travel_selections,
//    onPressed: (int index) {
//      setState(() {
//        _as.travel_selections[index] = !_as.travel_selections[index];
//      });
//    },
//    borderWidth: 2.0,
////      renderBorder: false,
////      borderRadius: BorderRadius.all(Radius(3.0)),
//  ) ;
//
//  Widget cont = Container(
//    child: tbs,
//    padding: BRMAppFlutterUtil.commonPadding,
//    decoration: BRMAppFlutterUtil.commonBoxDeco(),
//    constraints: BoxConstraints(maxWidth: 300),
//  );
//
//  return tbs ;
//}
//
//Widget _buildValveToggleButtons2() {
//  Widget b = ToggleButtons(
//    constraints: BoxConstraints.expand(
//      height: 50, //MediaQuery.of(context).size.height,
//      width: 200, // (MediaQuery.of(context).size.width / 3) - 100,
//    ),
//    children: [
//      Column(children: [
//        Icon(Icons.directions_bike),
//        Text('01'),
//      ]),
//      Icon(Icons.directions_boat),
//      Icon(Icons.directions_bus),
//      Icon(Icons.directions_car),
//      Icon(Icons.directions_railway),
//    ],
//    isSelected: _as.travel_selections,
//    onPressed: (int index) {
//      setState(() {
//        _as.travel_selections[index] = !_as.travel_selections[index];
//      });
//    },
//  ) ;
//
//  return b ;
//
////    return Container(
////      width: 300.0, // hardcoded for testing purpose
////      child: b
////    );
//}
//
//Widget foo() {
//  ToggleButtons(
//    constraints: BoxConstraints.expand(
//      height: MediaQuery.of(context).size.height,
//      width: MediaQuery.of(context).size.width / 3 - 2,
//    ),
//    children: <Widget>[
//      Icon(Icons.ac_unit),
//      Icon(Icons.call),
//      Icon(Icons.cake),
//    ],
////      onPressed: (int index) {
////        setState(
////              () {
////            isSelected[index] = !isSelected[index];
////          },
////        );
////      },
////      isSelected: isSelected,
//  ) ;
//}

//  _actionStartUpdates() async {
//    print('About to start updates') ;
//    await PrxDataPump.start() ;
//    _addDataListener() ;
//    print('pump started...') ;
//    setState(() { }) ;
//
//  }
//
//  _actionPauseUpdates() {
//    print('About to pause updates') ;
//    setState(() {
//      PrxDataPump.pause() ;
//    }) ;
//  }
//
//  _actionResumeUpdates() {
//    print('About to resume updates') ;
//    setState(() {
//      PrxDataPump.resume() ;
//    }) ;
//  }
//
//  _actionStopUpdates() {
//    print('About to stop updates') ;
//    setState(() {
//      _removeDataListener() ;
//      PrxDataPump.stop() ;
//    }) ;
//  }
//
//  _actionGetSingleUpdate() {
////      IZFlutterUtil.toast(context, "Making call to get status") ;
//      BRMHttpUtil.httpPost(
//          "http://192.168.1.177/all",
//          headers: {'brm': 'prx'},
//          showErrDialog: false, context: null,
////      timeout: Duration(seconds: 10),
//          success: ((httpResponse) {
//            var r = httpResponse.bodyBytes ;
////            print(r) ;
//            setState(() {
//              _as.aggr.from_bytes(r) ;
//            }) ;
////            print('updated _as.aggr.from_bytes(r)') ;
//
////            print(r) ;
////            PrxAggr2 aggr = PrxAggr2() ;
////            aggr.from_bytes(r) ;
////
////            print(aggr) ;
//
//          }),
//          onReqErr: (resp) {
////            c.complete(resp.body) ;
//            BRMFlutterUtil.toast(context, "Refresh Error, Request Problem.  " + resp.body) ;
////            IZFlutterUtil.izShowAlertDialog(context, 'Refresh Error, Request Problem', resp.body) ;
//          },
//          onTimeout: () {
////            c.complete('Request timed out') ;
//            BRMFlutterUtil.toast(context, "Refresh Error, Request timed out.  ") ;
////            IZFlutterUtil.izShowAlertDialog(context, 'Refresh Error', 'Request timed out') ;
//          }
//      );
//  }


//  Widget _buildIsoControls() {
//    FlatButton statusButton = BRMFlutterUtil.flatButton(
//        'Single', PrxDataPump.isStarted ? null : _actionGetSingleUpdate, iconPlacement: 9, icon: Icons.adjust
//    ) ;
//
//    FlatButton startUpdatesButton = BRMFlutterUtil.flatButton(
//        'Start', PrxDataPump.isStarted ? null : _actionStartUpdates, iconPlacement: 9, icon: Icons.play_arrow
//    ) ;
//
//    FlatButton pauseUpdatesButton = BRMFlutterUtil.flatButton(
//        'Pause', (PrxDataPump.isPaused || !PrxDataPump.isStarted) ? null : _actionPauseUpdates, iconPlacement: 9, icon: Icons.pause
//    ) ;
//
//    FlatButton resumeUpdatesButton = BRMFlutterUtil.flatButton(
//        'Resume', PrxDataPump.isPaused ? _actionResumeUpdates : null, iconPlacement: 9, icon: Icons.refresh
//    ) ;
//
//    FlatButton stopUpdatesButton = BRMFlutterUtil.flatButton(
//        'Stop', PrxDataPump.isStarted ? _actionStopUpdates : null, iconPlacement: 9, icon: Icons.stop
//    ) ;
//
//    Row buttons = Row(
//      children: <Widget>[
//        statusButton, startUpdatesButton, pauseUpdatesButton, resumeUpdatesButton, stopUpdatesButton,
//      ],
//      mainAxisAlignment: MainAxisAlignment.spaceBetween,
//    ) ;
//
//    Container cbuttons = Container(
//        child: buttons,
//        padding: BRMAppFlutterUtil.commonPadding,
//        decoration: BRMAppFlutterUtil.commonBoxDeco(),
//        constraints: BoxConstraints.expand(width: 600, height: 70),
//    ) ;
//
//    Row r2 = Row(children: <Widget>[
//        _buildQuickNavs(),
//    ]);
//
//    Row r = Row(children: <Widget>[
//      cbuttons, SizedBox(width: 40), r2,
//    ]) ;
//
//    return Container(
//      child: r,
////      padding: BRMAppFlutterUtil.commonPadding,
////      decoration: BRMAppFlutterUtil.commonBoxDeco(),
//      constraints: BoxConstraints.expand(width: 1100, height: 70),
//    ) ;
//  }


//  _addDataListener() {
//    AggrProvider.Global.addListener(_plcDataListener) ;
//  }
//
//  _removeDataListener() {
//    AggrProvider.Global.removeListener(_plcDataListener) ;
//  }
