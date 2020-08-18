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

    SomeScreenAppState someScreenAppState = SomeScreenAppState();
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
use a ChangeNotifier with the app state.  Note SomeScreenAppState extends ChangeNotifier and calls
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
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//
// App
//
import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/app_state.dart';

//
// Ismintis
//
import 'package:brmplcapp/common/brm_flutter_util.dart';

class SomeScreenAppState extends ChangeNotifier {
  String name = 'Marko' ;       // UI TextField with controller: _nameTEC
  bool happy = true ;         // UI: toggle button
  double rating = -1.0 ;      // UI: slider
  String confidence = 'High'; // UI: dropdown button

  // Contained widgets app-state often makes sense to held here as well.  In those cases this widget
  // will also be a Provider itself.

  // If the state changes internally and/or externally and we want the widget to have the opportunity
  // to react, such as doing a setState((){ }), we notify any listeners with notifyListeners() call.
  // In our scenario assume an external entity, timer, isolate, etc... could change the happy state.
  // We could notify the widget if it was listening
  setHappy(bool v) {
    happy = v ;
    notifyListeners() ;
  }

  List<bool> travel_selections = [true, false, true, true, false] ;
}

class _SomeScreenEphemeralState extends State {
  SomeScreenAppState _as ;  // Filled in _appStateBuild()

  //
  // Ephemeral State
  //
  TextEditingController _nameTEC = TextEditingController() ;

  List<String> _confidenceChoices = ['Low', 'Medium', 'High'] ;

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
  _actionNameChanged(String v) {
    _as.name = v ;
  }

  _actionButtonClicked() {
    BRMFlutterUtil.toast(context, "Your name is: '${_nameTEC.text}'") ;
  }

  _actionHappChoiceChanged(bool v) {
    setState(() => _as.happy = v) ;
  }

  //
  // Widgets/Build
  //
  Widget _buildNameStuff() {
    Row row = Row(children: <Widget>[
      BRMFlutterUtil.buildTextField(
          'Name', _nameTEC,
          (v) => _actionNameChanged(v),
          maxWidth: 300),
      SizedBox(height: 10.0),  // don't use Text('   ')
      Text('Just showing best way to add some space between widgets...'),
    ]) ;
    return row ;
  }

  Widget _buildButton() {
    FlatButton button = BRMFlutterUtil.flatButton(
        'Say my name if happy',
        // Note use of app-state in controlling button enablement
        _as.happy ? _actionButtonClicked : null,
        iconPlacement: 9, icon: Icons.message
    ) ;

    return Container(
        constraints: BoxConstraints(maxWidth: 300),
        child: button,
    ) ;
  }

  Widget _buildHappyChoice() {
    return Row(children: <Widget>[
      Text('Are you happy: '), // disable: 0, enable: 1
      Switch(
        value: _as.happy,
        onChanged: (v) => _actionHappChoiceChanged(v),
      ),
    ]);
  }

  Widget _buildRatingSlider() {
    return Row(children: <Widget>[
      Text('Rating [-2..2]:'),
      Slider(
          label: 'Rating:',
          min: -2, max: 2, divisions: 4,
          value: _as.rating,
          onChanged: (v) {
            setState(() => _as.rating = v);
          },
          semanticFormatterCallback: (double newValue) {
            return '${newValue.round()}';
          }),
      Text(' ${_as.rating.round()}'),
    ]);
  }

  Widget _buildConfidenceDropdown() {
    DropdownButton dropdown = BRMFlutterUtil.createDropdownButton(
        _as.confidence,
        _confidenceChoices,
        ((String newValue) => setState(() => _as.confidence = newValue))
    );

    return Row(children: <Widget>[
      Text('Confidence:  '),
      dropdown,
    ]) ;
  }

  Widget _buildValveToggleButtons() {
    ToggleButtons tbs = ToggleButtons(
      children: [
        Column(children: [
          Icon(Icons.directions_bike),
          Text('01'),
        ]),
        Icon(Icons.directions_boat),
        Icon(Icons.directions_bus),
        Icon(Icons.directions_car),
        Icon(Icons.directions_railway),
      ],
      isSelected: _as.travel_selections,
      onPressed: (int index) {
        setState(() {
          _as.travel_selections[index] = !_as.travel_selections[index];
        });
      },
      borderWidth: 2.0,
//      renderBorder: false,
//      borderRadius: BorderRadius.all(Radius(3.0)),
    ) ;

    Widget cont = Container(
      child: tbs,
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints(maxWidth: 300),
    );

    return tbs ;
  }

  Widget _buildValveToggleButtons2() {
    return Container(
      width: 150.0, // hardcoded for testing purpose
      child: ToggleButtons(
        constraints:
        BoxConstraints.expand(width: MediaQuery.of(context).size.width), // this doesn't work once inside container unless hard coding it
        borderRadius: BorderRadius.circular(5),
        children: [
          Column(children: [
            Icon(Icons.directions_bike),
            Text('01'),
          ]),
          Icon(Icons.directions_boat),
          Icon(Icons.directions_bus),
          Icon(Icons.directions_car),
          Icon(Icons.directions_railway),
        ],
        isSelected: _as.travel_selections,
        onPressed: (int index) {
          setState(() {
            _as.travel_selections[index] = !_as.travel_selections[index];
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    // Good example of a common grouping mechanism is the Container with a Row or Column as children
    // and some general padding, decoration and constraints.
    Widget qualificationDetails = Container(
      child: Column(children: <Widget>[
        _buildRatingSlider(),
        _buildConfidenceDropdown(),
      ], crossAxisAlignment: CrossAxisAlignment.start,),
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BRMAppFlutterUtil.commonBoxDeco(),
      constraints: BoxConstraints(maxWidth: 380),
    );

    Widget contents = Column(
      children: <Widget>[
        _buildNameStuff(),
        _buildHappyChoice(),
        _buildButton(),
        qualificationDetails,
        Flex(
          children: [ Expanded(child: _buildValveToggleButtons2())],
          direction: Axis.horizontal,
        ),
//        _buildValveToggleButtons2(),
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
    // Empty for now
  }

  _appStateBuild() {
    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context) ;
    _as = provider.someScreenAppState ;

    _nameTEC.text = _as.name ;

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

    // Remember that you are preserving the SomeScreenAppState outside of this context; it is held
    // somewhere higher in the widget-tree and generally in the TopLevelStateProvider held at the
    // app main() level.
    super.dispose() ;
  }

  @override
  didUpdateWidget(SomeScreenWidget oldWidget) {

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;  // must be first statement

    Scaffold scaff = Scaffold(
      appBar: AppBar(title: Text('State Management Example')),
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

class SomeScreenWidget extends StatefulWidget {
  @override
  _SomeScreenEphemeralState createState() {
    return _SomeScreenEphemeralState();
  }
}
