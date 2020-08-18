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

    GraphsScreenAppState GraphsScreenAppState = GraphsScreenAppState();
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
use a ChangeNotifier with the app state.  Note GraphsScreenAppState extends ChangeNotifier and calls
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
import 'package:charts_flutter/flutter.dart' as charts;

//
// App
//
import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/app_state.dart';

//
// BarrelRM
//
import 'package:brmplcapp/common/brm_flutter_util.dart';

import 'package:brmplcapp/widgets/plc_single_listen_stop.dart' ;
import 'package:brmplcapp/widgets/plc_single_listen_stop.dart' ;

import 'package:brmplcapp/prx_integ/prx_comm.dart';
import 'package:brmplcapp/prx_integ/prx_aggr.dart';
import 'package:brmplcapp/prx_integ/prx_data_pump.dart';
import 'package:brmplcapp/widgets/general_line_chart.dart';


LineChartDef createTemperatureLineChartDef() {

  SeriesDef mainTankSeries   = SeriesDef('main tank',  [ ], charts.MaterialPalette.yellow.shadeDefault) ;
  SeriesDef circHXPostSeries = SeriesDef('circ hx post', [ ], charts.MaterialPalette.blue.shadeDefault) ;
  SeriesDef thermoHXPostSeries  = SeriesDef('thermo hx post',  [ ], charts.MaterialPalette.red.shadeDefault) ;

//  for(int i = 0; i < 1500; i++) {
//    mainTankSeries.addEntry(40.0) ;
//    circHXPostSeries.addEntry(40.0) ;
//    thermoHXPostSeries.addEntry(40.0) ;
//  }
//  mainTankSeries.maxDisplayCountBeforeShifting = 1500 ;
//  circHXPostSeries.maxDisplayCountBeforeShifting = 1500 ;
//  thermoHXPostSeries.maxDisplayCountBeforeShifting = 1500 ;

  var seriesDefs = [mainTankSeries, circHXPostSeries, thermoHXPostSeries] ;

  // MrP: It doesn't seem possible to get the axes to go from large to small order.  Even when
  // I explicitly start with large->small and see the correct large->small ordering in the debugger
  // the rendered graph just ignores and puts in ascending order anyways...
  ChartAxisDef domainAxis = ChartAxisDef(
      40.0, 100, 5.0,  // in Fahrenheit
      color: charts.MaterialPalette.white, fontSize: 12
  ) ;

  ChartAxisDef primaryAxis = ChartAxisDef(
    0.0, 60.0, 1.0, // minutes
    color: charts.MaterialPalette.white, fontSize: 12
  ) ;

  return LineChartDef(seriesDefs, domainAxis, primaryAxis) ;
}

class GraphsScreenAppState extends ChangeNotifier {
  LineChartDef temperatureLineChartDef = createTemperatureLineChartDef();
  // Contained widgets app-state often makes sense to held here as well.  In those cases this widget
  // will also be a Provider itself.

  int timeMs = 0 ;

  // If the state changes internally and/or externally and we want the widget to have the opportunity
  // to react, such as doing a setState((){ }), we notify any listeners with notifyListeners() call.
  // In our scenario assume an external entity, timer, isolate, etc... could change the happy state.
  // We could notify the widget if it was listening
  setHappy(bool v) {
//    happy = v ;
    notifyListeners() ;
  }

  // MrP: HACK: TOTAL STATE hack -- revisit the widget setup and related static aspects
  PrxAggr aggr = AggrProvider.Global.aggr ;

  PlcSingleListenPauseAppState _singleListenPauseAppState = PlcSingleListenPauseAppState() ;
}

class _GraphsScreenEphemeralState extends State {
  GraphsScreenAppState _as ;  // Filled in _appStateBuild()

  //
  // Ephemeral State
  //
  TextEditingController _nameTEC = TextEditingController() ;

  //
  // Misc Behavior
  //
  _changeNotifierListener() {
    setState(() {

    }) ;
  }

  //
  // Actions
  //
  void _plcDataListener() {
    setState(() {
      // We just repaint with the PrxAggr2 aggr = PlcStatusPollerAppState.aggr ;
      _updateTemperatureLineChart() ;
    }) ;
  }

  _updateTemperatureLineChart() {
    int now = DateTime.now().millisecondsSinceEpoch ;
    if (_as.timeMs == 0) {
      _as.timeMs = now ;
    }

    int elapsedSinceStartedTiming = now - _as.timeMs ;
    double inSeconds = elapsedSinceStartedTiming / 1000.0 ;   // deal with millis
    double inMinutes = inSeconds / 60.0 ;                     // deal with minutes

    double tempr1 = _as.aggr.temp_1.fahrenheit ;  // Main tank
    double tempr3 = _as.aggr.temp_3.fahrenheit ;  // Circulation post HX
    double tempr5 = _as.aggr.temp_5.fahrenheit ;  // Thermo post HX

    if (tempr1 < 40.0) tempr1 = 40.0 ;
    if (tempr3 < 40.0) tempr3 = 40.0 ;
    if (tempr5 < 40.0) tempr5 = 40.0 ;

    print('$tempr1, $inSeconds') ;
    _as.temperatureLineChartDef.seriesDefs[0].addEntry(tempr1, inMinutes) ;
//    _as.temperatureLineChartDef.seriesDefs[1].addEntry(tempr3) ;
//    _as.temperatureLineChartDef.seriesDefs[2].addEntry(tempr5) ;
  }

  //
  // Widgets/Build
  //
  Widget _buildQuickNavs() {
    return Row(children: <Widget>[
      SizedBox(width: 40),
      BRMFlutterUtil.flatButton(
          "Settings", () => Navigator.pushNamed(context, Navi.SETTINGS),
          icon: Icons.settings, iconPlacement: 9
      ),
      SizedBox(width: 40),
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
    ]) ;
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
  Widget _buildTemperatureLineChart() {
//    SimpleLineChart2Widget chart = SimpleLineChart2Widget(_as.yawData, _as.pitchData, _as.rollData);
    GeneralLineChartWidget chart = GeneralLineChartWidget(_as.temperatureLineChartDef) ;

    return chart ;
//    Container chartContainer = Container(
//      child: chart, //Expanded(child: chart),
//      constraints: BoxConstraints(maxHeight: 400, minHeight: 200, maxWidth: 820, minWidth: 200),
//    );
//
//    return chartContainer ;
  }


  Widget _buildBody() {

    Widget contents = Column(
      children: <Widget>[
        _buildTopControls(),
        Container(
//          child: Expanded(child: _buildTemperatureLineChart()),
        child: _buildTemperatureLineChart(),
          constraints: BoxConstraints(maxWidth: 1200, maxHeight: 300),
        )

    ]) ;

    return Container(
      padding: BRMAppFlutterUtil.commonPadding,
      child: contents,
    ) ;
  }

  //
  // App State
  //
  _postFrameCallback(context) {
    // Empty for now
    // MrP: We don't want to do this here as it means our _plcDataListener() is getting called without
    // us every saying "Listen".  I think we got away with this before because we just didn't do a setState()
    // and thus seemingly did not get any updates!
    _as._singleListenPauseAppState.addListener(_plcDataListener) ;
  }

  _appStateBuild() {
    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context) ;
    _as = provider.graphsScreenAppState ;

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

    // Remember that you are preserving the GraphsScreenAppState outside of this context; it is held
    // somewhere higher in the widget-tree and generally in the TopLevelStateProvider held at the
    // app main() level.
    super.dispose() ;
  }

  @override
  didUpdateWidget(GraphsScreenWidget oldWidget) {

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;  // must be first statement

    Scaffold scaff = Scaffold(
      appBar: AppBar(title: Text('Graphs')),
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

class GraphsScreenWidget extends StatefulWidget {
  @override
  _GraphsScreenEphemeralState createState() {
    return _GraphsScreenEphemeralState();
  }
}
//
//class SimpleLineChart extends StatelessWidget {
//  final List<charts.Series> seriesList;
//  final bool animate;
//
//  SimpleLineChart(this.seriesList, {this.animate});
//
//  /// Creates a [LineChart] with sample data and no transition.
//  factory SimpleLineChart.withSampleData() {
//    return new SimpleLineChart(
//      _createSampleData(),
//      // Disable animations for image tests.
//      animate: false,
//    );
//  }
//
//
//  @override
//  Widget build(BuildContext context) {
//    return new charts.LineChart(seriesList, animate: animate);
//  }
//
//  /// Create one series with sample hard coded data.
//  static List<charts.Series<LinearSales, int>> _createSampleData() {
//    final data = [
//      new LinearSales(0, 5),
//      new LinearSales(1, 25),
//      new LinearSales(2, 100),
//      new LinearSales(3, 75),
//      new LinearSales(4, 38),
//    ];
//
//    return [
//      new charts.Series<LinearSales, int>(
//        id: 'Sales',
//        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
//        domainFn: (LinearSales sales, _) => sales.year,
//        measureFn: (LinearSales sales, _) => sales.sales,
//        data: data,
//      )
//    ];
//  }
//}
//
///// Sample linear data type.
//class LinearSales {
//  final int year;
//  final int sales;
//
//  LinearSales(this.year, this.sales);
//}
