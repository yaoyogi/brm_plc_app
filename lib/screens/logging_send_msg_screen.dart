//
// Flutter
//
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

//
// Dart
//
import 'dart:convert' as convert;

//
// App
//
import 'package:brmplcapp/common/app_state.dart';

import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/brm_flutter_util.dart';

import 'package:brmplcapp/brm_json/brm_json_util.dart';

import 'package:brmplcapp/logging/brm_logging.dart';

class LoggingSendMessageAppState {
  String level = 'debug';
  String tag = '';
  String message = '';
}

class LoggingSendMessageEphemeralState extends State {
  static List<LogLevel> _logLevels = LogLevel.getLevels() ;

  LoggingSendMessageAppState _as ;

  LogLevel _selectedLogLevel ;
  List<DropdownMenuItem<LogLevel>> _dropdownnMenuItems ;

  TextEditingController _messageTEC = TextEditingController() ;
  TextEditingController _tagTEC = TextEditingController() ;

  //
  // Actions
  //

  void _actionSendMsg() {
    BRMFlutterUtil.toast(context, 'Send message', 1);
    String tag = _tagTEC.text ;
    String msg = _messageTEC.text ;
    if (tag.isEmpty || msg.isEmpty) {
      BRMFlutterUtil.toast(context, 'Tag and message must not be empty') ;
      return ;
    }

    var body = BRMJsonUtil.jsonEncode({'level': _selectedLogLevel.name, 'tag': tag, 'msg': msg}) ;

    BRMHttpUtil.httpPost(
      AppUtil.urlMgr.esp32AdminLogWrite, body: body,
      showErrDialog: true, context: context,
      success: ((httpResponse) {
        var jsonResponse = convert.jsonDecode(httpResponse.body);
        var result = jsonResponse['result'] ;
        if (result != null) {
          var r = jsonResponse['result'].toString() ;
          BRMFlutterUtil.toast(context, r) ;
        }
        else {
          BRMFlutterUtil.toast(context, jsonResponse['error'].toString(), 3) ;
        }
      }),
    );
  }

  _actionLogLevelChanged(LogLevel level) {
    print('log level changed') ;
    _as.level = level.name ;
    setState(() {
      _selectedLogLevel = level ;
    }) ;
  }

  //
  // Build
  //
  List<DropdownMenuItem<LogLevel>> _buildDropdownMenuItems(List levels) {
    List<DropdownMenuItem<LogLevel>> items = List();
    for (LogLevel level in levels) {
      items.add(
        DropdownMenuItem(
          value: level,
          child: Text(level.name),
        ),
      );
    }
    return items;
  }

  Widget _buildMessageRow() {
    TextField tf = TextField(
      controller: _messageTEC,
      maxLines: 20,
      onChanged:(v) => _as.message = v,
//      expands: true,  // Should allow TF to be same size as parent???
    ) ;

    Column col = Column(
      children: <Widget>[
        Text('Message'),
        SizedBox(height: 10),
        Container(
          decoration: BRMAppFlutterUtil.commonBoxDeco(),
          child: tf,
        ),
      ], crossAxisAlignment: CrossAxisAlignment.start,
    ) ;

    return Container(
      padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
      child: col,
    ) ;
  }

  Widget _buildControlRow() {
    String level = _as.level ;

    Row r = Row(children: <Widget>[
      BRMFlutterUtil.flatButton( 'Send message', _actionSendMsg, iconPlacement: 9, icon: Icons.send),
      Text('   for tag: '),
      Container(
        constraints: BoxConstraints(maxWidth: 200),
        child: TextField(
            controller: _tagTEC,
            onChanged:(v) { _as.tag = v ; }
            ),
      ),
      Text('   at level:  '),
      DropdownButton(
        value: _selectedLogLevel,
        items: _dropdownnMenuItems,
        onChanged: _actionLogLevelChanged
      ),
    ]);
    return Container(
        padding: BRMAppFlutterUtil.commonPadding,
        child: r,
    ) ;
  }

  Widget _buildBody() {
    return SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildMessageRow(),
            _buildControlRow(),
          ],
        )
    ) ;
  }

  //
  // App State
  //
  _appStateBuild() {
    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context) ;
    _as = provider.loggingSendMessageAppState ;

    _tagTEC.text = _as.tag ;
    _messageTEC.text = _as.message ;
    _selectedLogLevel = LogLevel.findByName(_as.level) ;
  }

  _postFrameCallback(context) {
    // Empty for now
  }

  //
  // Framework Overrides
  //
  @override
  initState() {
    // MrP: Note, by using Provider(s) we rely on the widget-tree being intact.  This is only
    // true AFTER initState() has completely() finished AND returned.  You can't just do work
    // after the super.initState().  So, app state access/use minimally starts in build(BuildContext).

    // MrP: Here is first case where we would like to have the _appState already extracted/available...
    _selectedLogLevel = _logLevels[3] ; // DEBUG

    _dropdownnMenuItems = _buildDropdownMenuItems(_logLevels) ;

    super.initState() ;

    // Do this LAST and for sure after super.initState()
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallback(context)) ;
  }

  @override
  didUpdateWidget(LoggingSendMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  dispose() {
    super.dispose() ;
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;

    return Scaffold(
      appBar: AppBar(title: Text('Log Message')),
      body: _buildBody(),
    );
  }
}

class LoggingSendMessageWidget extends StatefulWidget {
  @override
  LoggingSendMessageEphemeralState createState() {
    return LoggingSendMessageEphemeralState() ;
  }
}
