//
// Flutter
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//
// Dart
//
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

//
// App
//
import 'package:brmplcapp/common/app_util.dart';

//
// BarrelRM
//
import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/brm_flutter_util.dart';

/*
TextField with bounds
TextField numeric
Checkbox
DropDown
 */
class ExampleAppState {

}

// General Steps
//
class _ExampleEphemeralState extends State {
  ExampleAppState _as ;

  //
  // Construction
  //

  //
  // Actions
  //
  void _actionRefresh() {
    BRMFlutterUtil.toast(context, 'Retrieving info...');

  }

  //
  // Build
  //


  Widget _buildTextField() {

  }

  Widget _buildNumericTextField() {

  }

  Widget _buildCheckbox() {

  }

  Widget _buildDropdown() {

  }

  Widget _buildSomething() {
    Widget w = Row(children: <Widget>[

    ]) ;

    return Container(
      child: w,
      constraints: BoxConstraints(maxWidth: 380, maxHeight: 170),
      padding: BRMAppFlutterUtil.commonPadding,
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
//      decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
    ) ;
  }

  Widget _buildBody() {
    return SingleChildScrollView(
        child: Column(children: <Widget>[

        ]),
    );
  }

  //
  // App State
  //
  _appStateBuild() {

  }

  //
  // Framework Lifecycle
  @override
  initState() {
    super.initState() ;
  }

  @override
  dispose() {
    super.dispose() ;
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;

    return Scaffold(
      appBar: AppBar(title: Text('My New Screen')),
      body: _buildBody(),
    );
  }
}

class ExampleScreenWidget extends StatefulWidget {
  @override
  _ExampleEphemeralState createState() {
    return _ExampleEphemeralState() ;
  }
}
