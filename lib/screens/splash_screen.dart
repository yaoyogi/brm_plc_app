//
// Flutter
//
import 'package:flutter/material.dart';

//
// Dart
//
import 'dart:async';

//
// App
//
import '../common/theme.dart' ;
import 'package:brmplcapp/common/app_util.dart';

class SplashScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  Future<Timer> loadData() async {
    return new Timer(Duration(seconds: 4), onDoneLoading);
  }

  onDoneLoading() async {
    Navigator.popAndPushNamed(context, Navi.OVERVIEW) ;
  }

  //
  // Build
  //
  Widget _buildBody() {
    var blurb = Text(
        AppEnv.barrelrm_app_note,
        style: TextStyle(fontSize: 15),
    ) ;

    Column col = Column(children: <Widget>[
      Spacer(flex: 2),
//      splashImage,
      BRMAppFlutterUtil.createIconic(),
      Spacer(flex: 1),
      Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          semanticsLabel: 'what',
        ),
      ),
      Spacer(flex: 1),
      blurb,
    ]);

    return Theme(
      child: col,
      data: appTheme,
    ) ;
  }

  //
  // Framework overrides
  //
  @override
  void initState() {
    super.initState();

    loadData();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('BarrelRM Processor Companion'),
        // The following two arguments are to get rid of the normal platform leading widget
        // and replace it with a dummy...
        leading: Icon(Icons.autorenew),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }
}