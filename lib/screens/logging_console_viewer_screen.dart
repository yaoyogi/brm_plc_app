//
// Flutter
//
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//
// Dart
//
import 'dart:async';

import 'package:sprintf/sprintf.dart';

import 'package:brmplcapp/logging/brm_logging_util.dart';

//
// App
//
import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/app_state.dart';

import 'package:brmplcapp/brm_json/brm_json_util.dart';

import 'package:brmplcapp/logging/brm_logging.dart';

import 'package:brmplcapp/common/brm_flutter_util.dart';

class ConsoleLogEntryDataTableAppState {
  bool showErrorCbValue = true;

  bool showDebugCbValue = true;

  bool showWarningCbValue = true;

  bool showInfoCbValue = true;

  bool showVerboseCbValue = true;

  //
  // RegEx
  //
  bool applyTagRegexCbValue = false;
  bool applyMsgRegexCbValue = false;

  String tagRegex ;
  String msgRegex ;

  bool autoScrollCbValue = true;
  bool skipDisplayCbValue = false;

  int maxCachedEntries = 250 ;
  int numLogEvents = 0 ;

  List<ConsoleLoggerEntry> entries = List<ConsoleLoggerEntry>() ;

  //
  // These are kindof gross here, BUT, they are state we must maintain across transitions
  // so this is their best home.  Just doc this and keep them separate.
  //
  bool sourceUDP = false ;

  //  ReceivePort _rxPort ;
  StreamSubscription<ConsoleLoggerEntry> streamSubscription ;
}

class _ConsoleLogEntryDataTableEphemeralState extends State {
  ConsoleLogEntryDataTableAppState _as ;

  int _maxRowsInPlay = 250 ;
  int _removeCount = 50 ;
  int _totalNumEntryEvents = 0 ;

  //
  // Show Levels
  //
  _showErrorCbChanged(bool value) {
    setState(() {
      _as.showErrorCbValue = value;
    });
  }
  
  _showDebugCbChanged(bool value) {
    setState(() {
      _as.showDebugCbValue = value;
    });
  }
  
  _showWarningCbChanged(bool value) {
    setState(() {
      _as.showWarningCbValue = value;
    });
  }
  
  _showInfoCbChanged(bool value) {
    setState(() {
      _as.showInfoCbValue = value;
    });
  }
  
  _showVerboseCbChanged(bool value) {
    setState(() {
      _as.showVerboseCbValue = value;
    });
  }

  //
  // RegEx
  //
  _applyTagRegexCbChanged(bool value) {
    setState(() {
      _as.applyTagRegexCbValue = value;
      if (value) {
        var s = _tagRegexTEC.text;
        try {
          _tagRegex = RegExp(s);
          BRMFlutterUtil.toast(context, 'Tag regexp is active') ;
        }
        catch(e) {
          _tagRegex = null ;
          var errMsg = 'Tag regexp is invalid: ' + e.toString() ;
          print(errMsg) ;
          _as.applyTagRegexCbValue = false ;
          BRMFlutterUtil.toast(context, errMsg);
          return;
        }
      }
    });
  }
  
  _applyMsgRegexCbChanged(bool value) {
    setState(() {
      _as.applyMsgRegexCbValue = value;
    });
  }

  TextEditingController _tagRegexTEC = TextEditingController();
  TextEditingController _msgRegexTEC = TextEditingController();

  TextEditingController _numLogEventsTEC = TextEditingController();
  TextEditingController _maxCachedEntriesTEC = TextEditingController();

  RegExp _tagRegex ;
  RegExp _msgRegex ;

  //
  // Bottom Row
  //
  _autoScrollCbChanged(bool value) {
    setState(() {
      _as.autoScrollCbValue = value;
    });
  }
  
  _skipDisplayCbChanged(bool value) {
    setState(() {
      _as.skipDisplayCbValue = value;
    });
  }

  //
  // List View
  //
  String _listHeader ; // set in initState() ;

  // So we can position new log entries to the end of the scrollable space.
  ScrollController _scrollController = ScrollController() ;

  addEntry(ConsoleLoggerEntry entry) {
    if (_as.skipDisplayCbValue) {
      setState(() {
        _totalNumEntryEvents++ ;
        _numLogEventsTEC.text = _totalNumEntryEvents.toString() ;
      });
      return ;
    }

    _totalNumEntryEvents++ ;

    // Filter based on level.  Note each level-check is mutually exclusive and thus allows us to
    // filter for any combination of levels.
    if (!_as.showErrorCbValue && (entry.level == 'E')) {
      return ;
    }
    if (!_as.showDebugCbValue && (entry.level == 'D')) {
      return ;
    }
    if (!_as.showWarningCbValue && (entry.level == 'W')) {
      return ;
    }
    if (!_as.showInfoCbValue && (entry.level == 'I')) {
      return ;
    }
    if (!_as.showVerboseCbValue && (entry.level == 'V')) {
      return ;
    }

    // Filter based on RegExp's
    if (_as.applyTagRegexCbValue) {
      if (! _tagRegex.hasMatch(entry.tag)) {
        print('Log entry skipped due to NOT matching TAG regexp') ;
        return ;
      }
    }

    if (_as.applyMsgRegexCbValue) {
      if (! _msgRegex.hasMatch(entry.msg)) {
        print('Log entry skipped due to NOT matching MSG regexp') ;
        return ;
      }
    }

    if (_as.entries.length > _maxRowsInPlay) {
      _as.entries.removeRange(0, _removeCount) ;
    }

    _as.entries.add(entry) ;

    if (_as.autoScrollCbValue) {
      setState(() {
        _numLogEventsTEC.text = _totalNumEntryEvents.toString() ;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  _actionSetMaxCachedEntries() {
    var s = _maxCachedEntriesTEC.text ;
    try {
      var m = int.parse(s);
      if (m < 50 || m > 500) {
        BRMFlutterUtil.toast(context, 'Max cached entries must be >= 50 <= 500', 3) ;
        return ;
      }
      _maxRowsInPlay = m ;
      _removeCount = (0.3 * _maxRowsInPlay) as int ;
//      _count = 0 ;
    }
    on FormatException {
      BRMFlutterUtil.toast(context, 'Max cache value must be a number', 3) ;
    }
  }
  
  _actionClearLogList() {
    _as.entries.clear() ;
    setState(() {

    });
  }
  
  _actionAttachToUDP() {
    print('attach to UDP') ;
    if (! UDPLogSource.isStarted) {
      _as.sourceUDP = false ;
      BRMFlutterUtil.toast(context, 'UDP Logger not started/active', 3) ;
      return ;
    }

    _as.streamSubscription = UDPLogSource.stream.listen((consoleLogEntry) {
      addEntry(consoleLogEntry);
    });

    // Handle case where underlying stream has been cancelled.  This can happen from the UDP log Mgr
    // where the user has done a UDP Server stop() which means the stream will be closed.
    _as.streamSubscription.onDone(() {
      print('UDP Stream is done') ;
      setState(() {}); // We just let the UI update to reflect we are no longer attached (subscribed)
    });

    setState(() {
      _as.sourceUDP = true ;
    });

    print('!! has listener: ${UDPLogSource.hasListener.toString()}') ;

    BRMFlutterUtil.toast(context, 'Viewer will display UDP-logged messages') ;
  }

  _actionDetachFromUDP() {
    _as.streamSubscription.cancel() ;
    _as.streamSubscription = null ;
    setState(() {
      _as.sourceUDP = false ;
    });
    BRMFlutterUtil.toast(context, 'Viewer no longer displaying UDP-logged messages') ;
  }

  //
  // Building Blocks...
  //
  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _as.entries.length,
      itemBuilder: (ctx, idx) {
        Text t = Text(
          _as.entries[idx].toFormattedString,
            style: TextStyle(fontFamily: 'IBM_Plex_Mono', fontSize: 16.0),
        );
        return t ; //SingleChildScrollView(child: t) ;
      },
    ) ;
  }

  Widget _buildShowLevelsRow() {
    return Container(
      padding:BRMAppFlutterUtil.commonPadding,
      child: Row(children: <Widget>[
        Text('Show levels: '),
        Checkbox(value: _as.showErrorCbValue, onChanged: _showErrorCbChanged),
        Text(' Error '),

        Spacer(flex: 1),
        Checkbox(value: _as.showDebugCbValue, onChanged: _showDebugCbChanged),
        Text(' Debug '),

        Spacer(flex: 1),
        Checkbox(value: _as.showWarningCbValue, onChanged: _showWarningCbChanged),
        Text(' Warning '),

        Spacer(flex: 1),
        Checkbox(value: _as.showInfoCbValue, onChanged: _showInfoCbChanged),
        Text(' Info '),

        Spacer(flex: 1),
        Checkbox(value: _as.showVerboseCbValue, onChanged: _showVerboseCbChanged),
        Text(' Verbose '),
      ],),
    );
  }

  Widget _buildShowApplyTagRegexRow() {
    return Container(
      padding:BRMAppFlutterUtil.commonPadding,
      child: Row(children: <Widget>[
        Checkbox(value: _as.applyTagRegexCbValue, onChanged: _applyTagRegexCbChanged),
        Text(' Apply tag reg-ex: '),
        Flexible(
          // Need Flexible parent as TextField want same control as Row does on length...
          child: TextField(
            controller: _tagRegexTEC,
            onChanged: (v)=> _as.tagRegex = v,
            decoration: InputDecoration(hintText: '(tag regex)'),
          ),
        ),
      ],),
    );
  }

  Widget _buildShowApplyMsgRegexRow() {
    return Container(
      padding:BRMAppFlutterUtil.commonPadding,
      child: Row(children: <Widget>[
        Checkbox(value: _as.applyMsgRegexCbValue, onChanged: _applyMsgRegexCbChanged),
        Text(' Apply msg reg-ex: '),
        Flexible(
          // Need Flexible parent as TextField want same control as Row does on length...
          child: TextField(
            controller: _msgRegexTEC,
            onChanged: (v)=> _as.msgRegex = v,
            decoration: InputDecoration(hintText: '(msg regex)'),
          ),
        ),
      ],),
    );
  }

  Widget _buildBottomDetailsRow() {
    return Container(
      padding:BRMAppFlutterUtil.commonPadding,
      child: Row(children: <Widget>[
        BRMFlutterUtil.flatButton( 'Clear log', _actionClearLogList, iconPlacement: 9, icon: Icons.clear),
        Checkbox(value: _as.autoScrollCbValue, onChanged: _autoScrollCbChanged),
        Text(' Auto-scroll'),
        Checkbox(value: _as.skipDisplayCbValue, onChanged: _skipDisplayCbChanged),
        Text(' Skip Display'),
        Spacer(flex: 1),
        BRMFlutterUtil.flatButton( 'Set max cached entries', _actionClearLogList),
        Text(' '),
        Flexible(
          // Need Flexible parent as TextField want same control as Row does on length...
          child: TextField(
              controller: _maxCachedEntriesTEC,
              onChanged: (v)=> _as.maxCachedEntries = int.parse(v),
              decoration: InputDecoration(hintText: '(max cached entries)'),
              keyboardType: TextInputType.numberWithOptions(decimal: false, signed: false)
          ),
        ),
        Spacer(flex: 1),
        Text('Num log events: '),
        Flexible(
          // Need Flexible parent as TextField want same control as Row does on length...
          child: TextField(
            controller: _numLogEventsTEC,
            onChanged: (v)=> _as.numLogEvents = int.parse(v),
            enabled: false,
          ),
        ),
      ]),
    );
  }


  Widget _buildSourceChoice() {
    String buttonText = _as.sourceUDP
        ? 'Detach from UDP'
        : 'Attach to UDP' ;
    Row r = Row(children: <Widget>[
      BRMFlutterUtil.flatButton( buttonText, (_as.sourceUDP ? _actionDetachFromUDP : _actionAttachToUDP), iconPlacement: 9, icon: Icons.attach_file),
      Text('  '),
      BRMFlutterUtil.flatButton('UDP Log Manager',
        ()=>Navigator.popAndPushNamed(context, Navi.LOGGER_UDP_MGR), iconPlacement: 9, icon: Icons.arrow_forward_ios),
    ]) ;
    return Container(
      child: r,
      padding:BRMAppFlutterUtil.commonPadding,
    ) ;
  }

  Widget _buildBody() {
    return Column(
      // We need this to "push" our Heading and ListView alignment to the left
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildShowLevelsRow(),
        _buildShowApplyTagRegexRow(),
        _buildShowApplyMsgRegexRow(),
        // Hmmm, difficulty in aligning the hack-header with the formatted ListView entries even
        // though we use the same FMT for the sprintf(..)
        Container(
          padding: BRMAppFlutterUtil.commonPadding,
          child: Text(
              _listHeader,
              style: TextStyle(fontFamily: 'IBMPlexMono-Regular', fontStyle: FontStyle.italic)
          ),
        ),
        Expanded(
          flex: 8,
//            child: Expanded(child: SingleChildScrollView(
//              child: _buildListView(),
//            )),
          child: Container(child: _buildListView(), padding: BRMAppFlutterUtil.commonPadding),
        ),
        _buildSourceChoice(),
        _buildBottomDetailsRow(),
      ],
    );
  }

  //
  // App State
  //
  _appStateBuild() {
    // Provider is a great way to get easy access to data stashed in the widget parentage...
    // In this case, we really didn't need a full class, ProviderData, but is ok as we may get
    // more complex later on.
    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context) ;
    _as = provider.consoleLogEntryDataTableAppState ;


    _tagRegexTEC.text = _as.tagRegex ;
    _msgRegexTEC.text = _as.msgRegex ;

    _numLogEventsTEC.text = _as.numLogEvents.toString() ;
    _maxCachedEntriesTEC.text = _as.maxCachedEntries.toString() ;
  }

  _postFrameCallback(context) {
    // Empty for now
  }


  //
  // Overrides for Framework
  //
  @override
  void initState() {
//    _entries.add(ConsoleLoggerEntry(1, 'D', 100, 'wifi', 'some msg A')) ;
//    _entries.add(ConsoleLoggerEntry(2, 'I', 200, 'ble', 'some msg with a lot more to say dare we say more...')) ;
//    _entries.add(ConsoleLoggerEntry(3, 'E', 300, 'i2c', 'one upon a time in Texas')) ;
//    _entries.add(ConsoleLoggerEntry(4, 'W', 400, 'batt', 'constant draw')) ;
//    _entries.add(ConsoleLoggerEntry(5, 'E', 500, 'i2c', 'things in bunches can be hunches')) ;
//    _entries.add(ConsoleLoggerEntry(6, 'V', 600, 'i2c', 'completed with no errors')) ;

    _maxCachedEntriesTEC.text = '250' ;
    _numLogEventsTEC.text = '0' ;

    _listHeader = sprintf(ConsoleLoggerEntry.FMT, ['Count', 'Level', 'Time', 'Tag', 'Message']) ;

    super.initState() ;

    // Do this LAST and for sure after super.initState()
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallback(context)) ;
  }

  @override
  dispose() {
    // cancel() should be safe even if previously cancelled or subscription is stale... right???
    // MrP: Big problem here!!! If we leave the screen we cancel the subscription and then we don't
    // get/see any messages.  That's why when we come back after leaving we see NO messages...
//    _appState.streamSubscription?.cancel() ;
    super.dispose() ;
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;  // MUST be first as we rely on state within it

    return Scaffold(
      appBar: AppBar(
        title: Text('Console Logger Viewer'),
      ),
      body: _buildBody(),
    ) ;
  }
}

class ConsoleLogEntryDataTableWidget extends StatefulWidget {
  @override
  _ConsoleLogEntryDataTableEphemeralState createState() {
    return _ConsoleLogEntryDataTableEphemeralState();
  }
}


//String _dropdownValue = 'None' ;
//String _dropdownValuePrev = 'None' ;
//
//_actionDropdownNone() {
//  print('None') ;
//}
//
//_actionDropdownUDP() {
//  if (! UDPLogSource.isStarted) {
//    IZFlutterUtil.toast(context, 'UDP Logger not started/active', 3) ;
//    return ;
//  }
//
//  if (_dropdownValuePrev == 'UDP') {
//    IZFlutterUtil.toast(context, 'UDP logger source already attached') ;
//    return ;
//  }
//
//  // Connect us to the UDP Logger Source
//  print('Attaching to UDP logger source') ;
//    UDPLogSource.start(_rxPort.sendPort) ;
//    _rxPort.listen((data) {
//      print(data) ;
//      ConsoleLoggerEntry cle = ConsoleLoggerEntry.fromMap(data) ;
//      addEntry(cle) ;
//    }) ;
//}
//
//Widget _createSourceChoice() {
//  var dropdown = DropdownButton<String>(
//    value: _dropdownValue,
//    icon: Icon(Icons.arrow_downward),
//    iconSize: 24,
//    elevation: 16,
//    style: TextStyle(
//        color: Colors.deepPurple
//    ),
//    underline: Container(
//      height: 2,
//      color: Colors.deepPurpleAccent,
//    ),
//    onChanged: (String newValue) {
//      setState(() {
//        _dropdownValue = newValue;
//        if (newValue == 'None') {
//          _actionDropdownNone() ;
//        }
//        else if (newValue == 'UDP') {
//          _actionDropdownUDP() ;
//        }
//        else {
//          print('Unhandled source choice: ${newValue}') ;
//        }
//      });
//    },
//    items: <String>['None', 'UDP'].map<DropdownMenuItem<String>>((String value) {
//      return DropdownMenuItem<String>(
//        value: value,
//        child: Text(value),
//      );
//    }).toList(),
//  ) ;
//
//  Row row = Row(children: <Widget>[
//    Text('Logging Source: '),
//    dropdown,
//  ]) ;
//
//  return Container(
//    child: row,
//    padding:AppUtil.commonPadding,
//  ) ;
//}
