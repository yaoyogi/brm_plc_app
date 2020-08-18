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
import 'package:provider/provider.dart';

import 'dart:typed_data';  // Uint8List

//
// App
//
import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/app_state.dart';
import 'package:brmplcapp/common/mocks.dart';
import 'package:brmplcapp/common/brm_flutter_util.dart';

import 'package:brmplcapp/prx_integ/prx_comm.dart';
import 'package:brmplcapp/prx_integ/prx_aggr.dart';

import 'package:brmplcapp/widgets/plc_status_poller_widget.dart';

class MocksScreenAppState extends ChangeNotifier {
//  PressureMock pressure_1_mock = PressureMock("pressure_1", 10.0, false, 0, 30) ;
//  PressureMock pressure_2_mock = PressureMock("pressure_2", 20.0, false, 0, 30) ;
//  PressureMock pressure_3_mock = PressureMock("pressure_3", 30.0, false, 0, 30) ;
//  PressureMock pressure_4_mock = PressureMock("pressure_4", 40.0, false, 0, 100) ;
//
//  TemperatureMock temperature_1_mock = TemperatureMock("temperature_1", 11.0, false, 0, 300) ;
//  TemperatureMock temperature_2_mock = TemperatureMock("temperature_2", 17.0, false, 0, 300) ;
//  TemperatureMock temperature_3_mock = TemperatureMock("temperature_3", 31.0, false, 0, 300) ;
//  TemperatureMock temperature_5_mock = TemperatureMock("temperature_5", 81.0, false, 0, 300) ;
//  TemperatureMock temperature_6_mock = TemperatureMock("temperature_6", 131.0, false, 0, 300) ;
//
//  BinarySwitchMock sw_flow_mock = BinarySwitchMock("sw_flow", false, false) ;
//  BinarySwitchMock sw_power_loss_mock = BinarySwitchMock("sw_power_loss", false, false) ;
//  BinarySwitchMock sw_emergency_mock = BinarySwitchMock("sw_emergency_off", false, false) ;

  MockBunch _mockBunch = MockBunch(AggrProvider.Global.aggr) ;

  // Contained widgets app-state often makes sense to held here as well.  In those cases this widget
  // will also be a Provider itself.

//  // If the state changes internally and/or externally and we want the widget to have the opportunity
//  // to react, such as doing a setState((){ }), we notify any listeners with notifyListeners() call.
//  // In our scenario assume an external entity, timer, isolate, etc... could change the happy state.
//  // We could notify the widget if it was listening
//  setHappy(bool v) {
//    happy = v;
//    notifyListeners();
//  }
}

class _MocksScreenEphemeralState extends State {
  MocksScreenAppState _as; // Filled in _appStateBuild()

  //
  // Ephemeral State
  //

  //
  // Misc Behavior
  //
  _changeNotifierListener() {
    setState(() {});
  }

  //
  // Actions
  //
  _actionAllMocks(bool state) {
    setState(() {
      _as._mockBunch.pressure_1_mock.active = state ;
      _as._mockBunch.pressure_2_mock.active = state ;
      _as._mockBunch.pressure_3_mock.active = state ;
      _as._mockBunch.pressure_4_mock.active = state ;

      _as._mockBunch.temperature_1_mock.active = state ;
      _as._mockBunch.temperature_2_mock.active = state ;
      _as._mockBunch.temperature_3_mock.active = state ;
      _as._mockBunch.temperature_5_mock.active = state ;
      _as._mockBunch.temperature_6_mock.active = state ;

      _as._mockBunch.sw_flow_mock.active = state ;
      _as._mockBunch.sw_emergency_shutdown_mock.active = state ;
      _as._mockBunch.sw_power_loss_mock.active = state ;
      _as._mockBunch.sw_4_mock.active = state ;
      _as._mockBunch.sw_5_mock.active = state ;
      _as._mockBunch.sw_6_mock.active = state ;
      _as._mockBunch.sw_7_mock.active = state ;
      _as._mockBunch.sw_8_mock.active = state ;
    }) ;
  }

  _actionSendMocks() {
      String json = _as._mockBunch.toJson() ;
//      print(json) ;
      
      PrxComm.updateMocks(json).then((resp) {
        if (resp == null) {
          BRMFlutterUtil.toast(context, 'Send mocks failed', 3) ;
        }
        else {
          BRMFlutterUtil.toast(context, 'Mocks updated', 2) ;
        }
      });
  }

  _actionGetMocks() {
    PrxComm.getMocks().then((json) {
      if (json == null) {
        // Error retrieving the mocks -- not much we can do but we should at least notify
        // the operator.
        BRMFlutterUtil.toast(context, 'Mocks retrieval failed', 3) ;
      }
      else {
        _as._mockBunch.fromJson(json) ;
        setState(() {
          // The mock bunch has all the state the UI needs to refresh
        }) ;
        BRMFlutterUtil.toast(context, 'Mocks retrieved', 2) ;
      }
    }) ;
  }

  _actionMocksOn() {
    print('all ON...');
    _actionAllMocks(true) ;
  }

  _actionMocksOff() {
    _actionAllMocks(false) ;
  }

  Widget _buildBooleanChoice(PressureMock mock) {
    return Row(children: <Widget>[
      Text('active: '), // disable: 0, enable: 1
      Switch(
        value: mock.active,
        onChanged: (v){
          setState(() {
            mock.active = v ;
          }) ;
        },
      ),
    ]);
  }

  Widget _buildBooleanChoiceX(TemperatureMock mock) {
    return Row(children: <Widget>[
      Text('active: '), // disable: 0, enable: 1
      Switch(
        value: mock.active,
        onChanged: (v){
          setState(() {
            mock.active = v ;
          }) ;
        },
      ),
    ]);
  }

  Widget _buildBinarySwitchChoice(BinarySwitchMock mock) {
    return Row(children: <Widget>[
      Text('active: '), // disable: 0, enable: 1
      Switch(
        value: mock.active,
        onChanged: (v){
          setState(() {
            mock.active = v ;
          }) ;
        },
      ),
    ]);
  }

  Widget _buildBinarySwitchValue(BinarySwitchMock mock) {
    return Row(children: <Widget>[
      Text('${mock.id}: '), // disable: 0, enable: 1
      Switch(
        value: mock.v,
        onChanged: (newState){
          setState(() {
            mock.v = newState ;
          }) ;
        },
      ),
    ]);
  }

  //
  // Widgets/Build
  //
  Widget _buildPressureComplex(PressureMock mock) {
    Slider slider = Slider(
        label: 'pressure', // this is the bubble-label on the slider box itself
        min: mock.min,
        max: mock.max,
//        divisions: 20,
        value: mock.v,
        onChanged: (value) {
          setState(() => mock.v = value) ; //_as.qualityValue = value);
          print('{$mock.id}: ${mock.v.toStringAsFixed(2)}') ;
        },
        semanticFormatterCallback: (double newValue) {
          return '${newValue.toStringAsFixed(2)}';
        });
    Row r = Row(children: <Widget>[
      Text('${mock.id} [${mock.min}..${mock.max}]:'),
      Expanded(child: slider),  // important as we want slider to expand to parent
//      slider,
      Text(' ${mock.v.toStringAsFixed(2)}'),
      SizedBox(width: 30),
      _buildBooleanChoice(mock),
    ]);

    return r;
  }

  Widget _buildTemperatureComplex(TemperatureMock mock) {
    Slider slider = Slider(
        label: 'temperature', // this is the bubble-label on the slider box itself
        min: mock.min,
        max: mock.max,
//        divisions: 20,
        value: mock.v,
        onChanged: (value) {
          setState(() => mock.v = value) ; //_as.qualityValue = value);
          print('{$mock.id}: ${mock.v.toStringAsFixed(2)}') ;
        },
        semanticFormatterCallback: (double newValue) {
          return '${newValue.toStringAsFixed(2)}';
        });
    Row r = Row(children: <Widget>[
      Text('${mock.id} [${mock.min}..${mock.max}]:'),
      Expanded(child: slider),  // important as we want slider to expand to parent
//      slider,
      Text(' ${mock.v.toStringAsFixed(2)}'),
      SizedBox(width: 30),
      _buildBooleanChoiceX(mock),
    ]);

    return r;
  }

  Widget _buildBinarySwitchComplex(BinarySwitchMock mock) {
    Row r = Row(children: <Widget>[
        Text('['),
        _buildBinarySwitchValue(mock),    // ** VALUE **
        Text(':  '),
        _buildBinarySwitchChoice(mock),   // active or not
        Text(']'),
    ]) ;

    return r ;
  }

  _buildMockControlButtons() {
    FlatButton all = BRMFlutterUtil.flatButton(
        'Refresh', _actionGetMocks, iconPlacement: 9, icon: Icons.refresh
    ) ;

    FlatButton send = BRMFlutterUtil.flatButton(
        'Mocks to PLC', _actionSendMocks, iconPlacement: 9, icon: Icons.cloud_upload
    ) ;

    FlatButton allOn = BRMFlutterUtil.flatButton(
        'All mocks ON', _actionMocksOn, iconPlacement: 9, icon: Icons.check
    ) ;

    FlatButton allOff = BRMFlutterUtil.flatButton(
        'All mocks OFF', _actionMocksOff, iconPlacement: 9, icon: Icons.remove_circle
    ) ;

    Row r = Row(children: <Widget>[
      all,
      SizedBox(width: 40),
      send,
      SizedBox(width: 80),
      allOn,
      SizedBox(width: 40),
      allOff,
    ]);

    return r ;
  }

  Widget _buildMockSwitches() {
    Row r1 = Row(children: <Widget>[
      _buildBinarySwitchComplex(_as._mockBunch.sw_flow_mock),
      SizedBox(width: 40),
      _buildBinarySwitchComplex(_as._mockBunch.sw_emergency_shutdown_mock),
      SizedBox(width: 40),
      _buildBinarySwitchComplex(_as._mockBunch.sw_power_loss_mock),
    ]) ;

    Row r2 = Row(children: <Widget>[
      _buildBinarySwitchComplex(_as._mockBunch.sw_4_mock),
      SizedBox(width: 40),
      _buildBinarySwitchComplex(_as._mockBunch.sw_5_mock),
      SizedBox(width: 40),
      _buildBinarySwitchComplex(_as._mockBunch.sw_6_mock),
    ]) ;

    Row r3 = Row(children: <Widget>[
      _buildBinarySwitchComplex(_as._mockBunch.sw_7_mock),
      SizedBox(width: 40),
      _buildBinarySwitchComplex(_as._mockBunch.sw_8_mock),
    ]) ;

    Column col = Column(children: <Widget>[
      r1, r2, r3,
    ],crossAxisAlignment: CrossAxisAlignment.start,);

    return col ;
  }

  Widget _buildBody() {
    Widget contents = Column(
      children: <Widget>[
//        PlcStatusPollerWidget(),
        SizedBox(height:10),
        Container(child: _buildPressureComplex(_as._mockBunch.pressure_1_mock), width: 800),
        Container(child: _buildPressureComplex(_as._mockBunch.pressure_2_mock), width: 800),
        Container(child: _buildPressureComplex(_as._mockBunch.pressure_3_mock), width: 800),
        Container(child: _buildPressureComplex(_as._mockBunch.pressure_4_mock), width: 800),
        SizedBox(height:30),
        Container(child: _buildTemperatureComplex(_as._mockBunch.temperature_1_mock), width: 800),
        Container(child: _buildTemperatureComplex(_as._mockBunch.temperature_2_mock), width: 800),
        Container(child: _buildTemperatureComplex(_as._mockBunch.temperature_3_mock), width: 800),
        Container(child: _buildTemperatureComplex(_as._mockBunch.temperature_5_mock), width: 800),
        Container(child: _buildTemperatureComplex(_as._mockBunch.temperature_6_mock), width: 800),

        SizedBox(height: 30),
        _buildMockSwitches(),

        SizedBox(height: 20),
        _buildMockControlButtons(),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );

    return Container(
      padding: BRMAppFlutterUtil.commonPadding,
//      child: contents, //Expanded(child: contents),
      child: SingleChildScrollView(child: contents, scrollDirection: Axis.horizontal),
    ) ;

//    return Container(
//      padding: BRMAppFlutterUtil.commonPadding,
//      child: contents,
//    );
  }

  //
  // App State
  //
  _postFrameCallback(context) {
    // Empty for now
  }

  _appStateBuild() {
    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context);
    _as = provider.mocksScreenAppState;

    if (!_as.hasListeners) {
      // We only need to add this once for lifetime of widget, we remove in dispose().  Note that we
      // DON'T use anonymous closure since we need to remove the same listener in dispose so having
      // a function ref works.
      _as.addListener(_changeNotifierListener);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallback(context));
  }

  @override
  dispose() {
    // We don't want notifications going to a stale widget that no longer exists!
    _as.removeListener(_changeNotifierListener);

    // Remember that you are preserving the MocksScreenAppState outside of this context; it is held
    // somewhere higher in the widget-tree and generally in the TopLevelStateProvider held at the
    // app main() level.
    super.dispose();
  }

  @override
  didUpdateWidget(MocksScreenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild(); // must be first statement

    Scaffold scaff = Scaffold(
      appBar: AppBar(title: Text('Mocks')),
      body: SingleChildScrollView(child: _buildBody()),
    );

    // Since we have a nested widget that requires its own app state, we hold onto that state in "this"
    // instances App State and have a separate "provider" for it.  This makes sense in that the websocket
    // imu widget is a child of "this" instance and thus should NOT be at the root of the entire application.
    // While that could work, it's improperly scoped and we already have multiple screens that could have
    // their own websocket imu connection widget.  Of course, the case for sharing the "connection" widget
    // might be needed at some point its NOT what we want now...
    return MultiProvider(providers: [
// The commented providers are used in a number of other screens, see the imu_watcher_screen.dart for actual use
//          ChangeNotifierProvider(builder: (_) => IZImuDataProvider(data: _appState.imuData)),
//          ChangeNotifierProvider(builder: (_) => WebsocketImuDataProvider(_appState.wsImuDataWidgetAppState)),
    ], child: scaff);
  }
}

class MocksScreenWidget extends StatefulWidget {
  @override
  _MocksScreenEphemeralState createState() {
    return _MocksScreenEphemeralState();
  }
}
