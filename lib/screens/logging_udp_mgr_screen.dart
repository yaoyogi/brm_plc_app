/*

look at the Eclipse C++ iz_examples/ex_logging/ folder for the scripts.
/Users/marko/git/iz_firmware/wobblezz/iz_examples/ex_logging/readme.txt

> python logging_server_python2.py    // defaults to 17000
ip: 0.0.0.0 , port: 17000
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
|  Ismintis UDP Logging Server  |
|  > ctrl-C    (to end server)  |
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+

Use ctrl-C to stop the logging server

The Python3 server will get an Accept Dialog on MAC OS X:
	"Do you want the application 'Python.app' to accept incoming connections?"
You need to click "Allow" for the server to function.  If you click "Deny" the Python app still runs
(no errors displayed) but won't take in any connections.

> python3 logging_server_python3.py 17003
ip: 0.0.0.0 , port: 17003
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
|  Ismintis UDP Logging Server  |
|  > ctrl-C    (to end server)  |
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+


 */
//
// Flutter
//
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
//
// Dart
//
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;


//
// App
//
import 'package:brmplcapp/common/app_state.dart';

import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/brm_flutter_util.dart';

import 'package:brmplcapp/brm_json/brm_json_util.dart';

import 'package:brmplcapp/logging/brm_logging.dart';
import 'package:brmplcapp/logging/brm_logging_util.dart';

class UDPLoggerMgrAppState {
  String ipAddr = AppEnv.devMachineIpAddr ;
  int port = 17003 ;

  bool clientCreatedCbValue = false ;
  bool clientStartedCbValue = false ;
  bool clientPausedCbValue = false ;
}

class _UDPLoggerMgrEphemeralState extends State {
  UDPLoggerMgrAppState _as ;

  TextEditingController _ipAddrTEC = TextEditingController();
  TextEditingController _portTEC = TextEditingController();

  bool get _buttonCreateActive => _as.clientCreatedCbValue;
  bool get _buttonStartActive {
    if (_as.clientPausedCbValue) {
      return true;
    }
    if (_as.clientStartedCbValue) {
      return false;
    }

    return _as.clientCreatedCbValue;
  }

  bool get _buttonPauseActive => _as.clientStartedCbValue && (!_as.clientPausedCbValue);
  bool get _buttonStopActive => _as.clientStartedCbValue;
  bool get _buttonRemoveActive =>
      _as.clientCreatedCbValue ? (_as.clientStartedCbValue ? false : true) : false;

  bool get _serverStartButtonActive {
    if (UDPLogSource.isStarted) return false ;
    if (UDPLogSource.isPaused) return true ;
    return true ;
  }

  bool get _serverPauseButtonActive {
    if (UDPLogSource.isPaused) {
      return false ;
    }
    return UDPLogSource.isStarted ;
  }

  bool get _serverResumeButtonActive {
    return UDPLogSource.isPaused ;
  }

  bool get _serverStopButtonActive {
    return UDPLogSource.isStarted ;
  }

  //
  // Actions
  //

  _actionServerStart() {
    BRMFlutterUtil.toast(context, 'Server start', 1) ;
    UDPLogSource.start().then((_) {
      setState(() { }) ;
      BRMFlutterUtil.toast(context, 'Local UDP logging server started') ;
    }) ;
  }

  _actionServerPause() {
    BRMFlutterUtil.toast(context, 'Server pause', 1) ;
    UDPLogSource.pause() ;
    setState(() { }) ;
    BRMFlutterUtil.toast(context, 'Local UDP logging server paused') ;
  }

  _actionServerResume() {
    BRMFlutterUtil.toast(context, 'Server resume', 1) ;
    UDPLogSource.resume() ;
    setState(() { }) ;
    BRMFlutterUtil.toast(context, 'Local UDP logging server resumed') ;
  }

  _actionServerStop() {
    BRMFlutterUtil.toast(context, 'Server stop', 1) ;
    UDPLogSource.stop() ;
    setState(() { }) ;
    BRMFlutterUtil.toast(context, 'Local UDP logging server stopped') ;
  }

  void _actionClientCreate() {
    BRMFlutterUtil.toast(context, 'creating client');
    String portStr = _portTEC.text;
    int port;
    try {
      port = int.parse(portStr);
    } catch (err) {
      BRMFlutterUtil.toast(context, 'Port must be positive integer', 3);
      return;
    }

    String ipAddr = _ipAddrTEC.text;
    String err = AppUtil.isIPAddr(ipAddr);
    if (err != null) {
      BRMFlutterUtil.toast(context, err, 3);
      return;
    }
    var body = BRMJsonUtil.jsonEncode({'port': port, 'ipAddr': ipAddr});

    BRMHttpUtil.commonPost(context, AppUtil.urlMgr.esp32AdminLogUdpCreate, body, (resp) {
      setState(() {
        _as.clientCreatedCbValue = true;
      });
    });
  }

  void _actionClientStart() {
    BRMFlutterUtil.toast(context, 'starting client', 1);
    BRMHttpUtil.commonPost(context, AppUtil.urlMgr.esp32AdminLogUdpStart, null, (resp) {
      setState(() {
        _as.clientStartedCbValue = true;
      });
    });
  }

  void _actionClientPause() {
    BRMFlutterUtil.toast(context, 'pausing client', 1);
    BRMHttpUtil.commonPost(context, AppUtil.urlMgr.esp32AdminLogUdpPause, null, (resp) {
      setState(() {
        _as.clientPausedCbValue = true;
      });
    });
  }

  void _actionClientStop() {
    BRMFlutterUtil.toast(context, 'stopping client', 1);
    BRMHttpUtil.commonPost(context, AppUtil.urlMgr.esp32AdminLogUdpStop, null, (resp) {
      setState(() {
        _as.clientStartedCbValue = false;
        _as.clientPausedCbValue = false;
      });
    });
  }

  void _actionClientRemove() {
    BRMFlutterUtil.toast(context, 'removing client', 1);
    BRMHttpUtil.commonPost(context, AppUtil.urlMgr.esp32AdminLogUdpRemove, null, (resp) {
      setState(() {
        _as.clientStartedCbValue = false;
        _as.clientPausedCbValue = false;
        _as.clientCreatedCbValue = false;
      });
    });
  }

  void _actionGetDetails() {
    BRMFlutterUtil.toast(context, 'Retrieving info...', 1);
    Future<http.Response> fr = http.post(AppUtil.urlMgr.esp32AdminLogUdpDetails);
    fr.then((response) {
      if (response.statusCode == 200) {
        var body = response.body;
        var jsonResponse = convert.jsonDecode(body);
        var result = jsonResponse['result'];
        if (result == null) {
          setState(() {
            _as.clientCreatedCbValue = false ;
            _as.clientStartedCbValue = false ;
            _as.clientPausedCbValue = false ;

//            _ipAddrTextController.text = '0.0.0.0' ;
//            _portTextController.text = '0' ;
          }) ;
          BRMFlutterUtil.toast(context, 'Client details retrieved') ;
        }
        else {
          setState(() {
            _as.clientCreatedCbValue = result['created'];
            _as.clientStartedCbValue = result['started'];
            _as.clientPausedCbValue = result['paused'];

            _ipAddrTEC.text = result['ipAddr'];
            _portTEC.text = result['port'].toString();
          });
        }
      } else {
        BRMFlutterUtil.brmShowAlertDialog(
            context, 'Client Retrieval Error', "Request failed with status: ${response.statusCode}.");
      }
    });
  }

  //
  // Build
  //
  Widget _buildESP32ClientButtonsRow() {
    return Container(
      padding: BRMAppFlutterUtil.commonPadding,
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        BRMFlutterUtil.flatButton( 'Create',_buttonCreateActive ? null : _actionClientCreate),
        Text('  '),
        BRMFlutterUtil.flatButton( 'Start', (_buttonStartActive ? _actionClientStart : null), iconPlacement: 9, icon: Icons.play_arrow),
        Text('  '),
        BRMFlutterUtil.flatButton( 'Pause', (_buttonPauseActive ? _actionClientPause : null), iconPlacement: 9, icon: Icons.pause),
        Text('  '),
        BRMFlutterUtil.flatButton( 'Stop', _buttonStopActive ? _actionClientStop : null, iconPlacement: 9, icon: Icons.stop),
        Text('  '),
        BRMFlutterUtil.flatButton( 'Remove', (_buttonRemoveActive ? _actionClientRemove : null), iconPlacement: 9, icon: Icons.delete),
      ]),
    );
  }
  
  Widget _buildIPAddrPortRow() {
    return Container(
      padding: BRMAppFlutterUtil.commonPadding,
      child: Row(children: <Widget>[
        Text('IP Address: '),
        SizedBox(width: 260, child: TextField(
            controller: _ipAddrTEC,
            onChanged: (v) => _as.ipAddr = v,
            decoration: InputDecoration(hintText: 'of server endpoint'),
            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false)
        )),
        Text('      '),
        Text('Port: '),
        SizedBox(width: 100, child: TextField(
            controller: _portTEC,
            onChanged: (v) => _as.port = int.parse(v),
            decoration: InputDecoration(hintText: 'port number'),
            keyboardType: TextInputType.numberWithOptions(decimal: false, signed: false)
        )),
      ]),
    );
  }

  Widget _buildClientCheckboxesRow() {
    return Container(
        padding: BRMAppFlutterUtil.commonPadding,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          // MrP: ??? What's with the null actions on these checkboxes
          Checkbox(value: _as.clientCreatedCbValue, onChanged: null), //_clientCreatedCbChanged),
          Text(' Created'),
          Text('  '),

          Checkbox(value: _as.clientStartedCbValue, onChanged: null), //_clientStartedCbChanged),
          Text(' Started'),
          Text('  '),

          Checkbox(value: _as.clientPausedCbValue, onChanged: null), //_clientPausedCbChanged),
          Text(' Paused'),
        ]));
  }

  Widget _buildLocalSvrButtons() {
    return Container(
      padding: BRMAppFlutterUtil.commonPadding,
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
//        Spacer(flex: 1),
        BRMFlutterUtil.flatButton( 'Start UDP Svr', (_serverStartButtonActive ? _actionServerStart : null), iconPlacement: 9, icon: Icons.play_arrow),
//        Spacer(flex: 1),
        Text('  '),
        BRMFlutterUtil.flatButton( 'Pause UDP Svr', (_serverPauseButtonActive ? _actionServerPause : null), iconPlacement: 9, icon: Icons.pause),
//        Spacer(flex: 1),
        Text('  '),
        BRMFlutterUtil.flatButton( 'Resume UDP Svr', (_serverResumeButtonActive ? _actionServerResume : null), iconPlacement: 9, icon: Icons.play_circle_filled),
//        Spacer(flex: 1),
        Text('  '),
        BRMFlutterUtil.flatButton( 'Stop UDP Svr', (_serverStopButtonActive ? _actionServerStop : null), iconPlacement: 9, icon: Icons.stop ),
//        Spacer(flex: 1),
      ]),
    );
  }

  Widget _buildOtherButtons() {
    Container c = Container(
        padding: BRMAppFlutterUtil.commonPadding,
        child: Row(
          children: <Widget>[
            BRMFlutterUtil.flatButton( 'Refresh',_actionGetDetails, iconPlacement: 9, icon: Icons.refresh),
            Text('  '),
            BRMFlutterUtil.flatButton( 'Logging Console Viewer',
                    ()=>Navigator.popAndPushNamed(context, Navi.LOGGER_CONSOLE_VIEWER), iconPlacement: 9, icon: Icons.arrow_forward_ios
            ),
          ],
        )
    );
    return c ;
  }

  Widget _buildBody() {
    Column c = Column(
      children: <Widget>[
        Container(
          padding: BRMAppFlutterUtil.commonPadding,
          child: Text('ESP32 UDP Client Config/Managment'),
        ),
        _buildIPAddrPortRow(),
        _buildClientCheckboxesRow(),
        _buildESP32ClientButtonsRow(),
        Divider(color: Colors.blueGrey),
        Container(
          padding: BRMAppFlutterUtil.commonPadding,
          child: Text('Local UDP Logging Server Config/Managment (uses Client port value)'),
        ),
        _buildLocalSvrButtons(),
        Divider(color: Colors.blueGrey),
        _buildOtherButtons(),
      ],
    ) ;

    return SingleChildScrollView(child: c) ;
  }

  //
  // App State
  //
  _appStateBuild() {
    // Provider is a great way to get easy access to data stashed in the widget parentage...
    // In this case, we really didn't need a full class, ProviderData, but is ok as we may get
    // more complex later on.
    TopLevelStateProvider provider = TopLevelStateProvider.getProvider(context) ;
    _as = provider.udpLoggerMgrAppState ;

    _ipAddrTEC.text = _as.ipAddr ;
    _portTEC.text = _as.port.toString() ;
  }

  _postFrameCallback(context) {
    // Empty for now
  }

  //
  // Framework Overrides
  //
  @override
  void initState() {
    _ipAddrTEC.text = AppEnv.devMachineIpAddr; //'192.168.1.93';
    _portTEC.text = '17003';

    super.initState() ;

    // Do this LAST and for sure after super.initState()
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallback(context)) ;
  }

  @override
  void dispose() {
    super.dispose() ;
  }

  @override
  Widget build(BuildContext context) {
    _appStateBuild() ;

    return Scaffold(
        appBar: AppBar(title: Text('ESP32 UDP Logger')),
        body: _buildBody(),
    );
  }
}

class UDPLoggerMgrScreen extends StatefulWidget {
  @override
  _UDPLoggerMgrEphemeralState createState() {
    return _UDPLoggerMgrEphemeralState();
  }
}


//  bool _clientCreatedCbValue = false;
//  _clientCreatedCbChanged(bool value) {
//    setState(() {
//      _appState.clientCreatedCbValue = value;
//    });
//  }

//  bool _clientStartedCbValue = false;
//  _clientStartedCbChanged(bool value) {
//    setState(() {
//      _appState.clientStartedCbValue = value;
//    });
//  }

//  bool _clientPausedCbValue = false;
//  _clientPausedCbChanged(bool value) {
//    setState(() {
//      _appState.clientPausedCbValue = value;
//    });
//  }
