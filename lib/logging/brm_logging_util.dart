import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:sprintf/sprintf.dart';

//
// Ismintis
//
//import 'package:iz_esp32_integ_pkg/iz_json/iz_json_util.dart';

import 'package:brmplcapp/logging/brm_logging.dart';
import 'package:brmplcapp/brm_json/brm_json_util.dart';

/// Model for discrete parts of an ESP32 console log message
class ConsoleLoggerEntry {
  int count;  // NOT part of ECP32 console log msg

  String level; // 'D' for debug, 'I' for info, etc...
  int time;     // timestamp
  String tag;   // logging tag
  String msg;   // the actual logged messsage

  static const String FMT = '%-7s%-3s%-10s%-20s%-25s' ;

  ConsoleLoggerEntry(this.count, this.level, this.time, this.tag, this.msg);

  // I (514210) iz_http_svr: _process_req:540{120820}|0|@5 request URI: /admin/esp_log_write, looking for handler for: /admin/esp_log_write
  // I -- level
  // (514210) -- timestamp
  // iz_http_svr: -- tag
  // _process_req:540{120820}|0|@5 -- function:line{free_heap}|core|priority (IZ-extension)
  // request URI: /admin/esp_log_write, looking for handler for: /admin/esp_log_write -- message
  //
  // D (5805) wpa: WPA: Key negotiation completed with 00:1f:f3:c3:75:1a [PTK=CCMP GTK=TKIP]
  // D -- level
  // (5805) -- timestamp
  // wpa: -- tag
  // (no IZ-extension)
  // WPA: Key negotiation completed with 00:1f:f3:c3:75:1a [PTK=CCMP GTK=TKIP] -- msg
  static ConsoleLoggerEntry fromConsoleMsg(String encodedLogEntry) {
    try {
      // We pass the consoleMsg "as-is" since there can be ANSI color values and for example
      // it starts with \033[xxxM, so we don't want to lose the fact we start with \033 so we
      // can properly strip it out later.  Note \033 is non-printable.
      encodedLogEntry = IZLoggingUtil.stripAnsiColorCodes(encodedLogEntry) ;

      String level = encodedLogEntry.substring(0, 1) ;

      int leftParenIndex = encodedLogEntry.indexOf('(') ;
      int rightParenIndex = encodedLogEntry.indexOf(')', leftParenIndex + 1) ;
      String tsStr = encodedLogEntry.substring(leftParenIndex + 1, rightParenIndex) ;
      int tsLong = int.tryParse(tsStr) ;

      int firstColonIndex = encodedLogEntry.indexOf(':', rightParenIndex + 1) ;
      String tag = encodedLogEntry.substring(rightParenIndex + 1, firstColonIndex).trim();

      String msg = encodedLogEntry.substring(firstColonIndex + 1).trim();

      // It's possible the msg end with [0m   So we test/handle for that
      if (msg.endsWith("[0m")) {
        int index = msg.lastIndexOf("[0m]") ;
        msg = msg.substring(0, index) ;
      }

      ConsoleLoggerEntry logMsg = ConsoleLoggerEntry(0, level, tsLong, tag, msg) ;

      return logMsg ;
    }
    catch(err) {
      print('Unable to decode: $encodedLogEntry') ;
      return null ;
    }
  }

  static ConsoleLoggerEntry fromJson(String json) {
    var map = BRMJsonUtil.jsonDecode(json) ;
    return fromMap(map) ;
  }

  //
  // API
  //
  String get toFormattedString {
    var r = sprintf(FMT, [count.toString(), level, time.toString(), tag, msg]) ;
    return r ;
  }

  //
  // JSON
  //
  static ConsoleLoggerEntry fromMap(Map<String, dynamic> map) {
    ConsoleLoggerEntry r = ConsoleLoggerEntry(
        map['count'], map['level'], map['time'], map['tag'], map['msg']
    ) ;
    return r ;
  }

  String get toJson {
    return BRMJsonUtil.jsonEncode(toJsonMap) ;
  }

  Map<String, dynamic> get toJsonMap {
    return {
      'count': count,
      'level': level,
      'time': time,
      'tag': tag,
      'msg': msg
    } ;
  }
}

///
///UDPLogSource ls = UDPLogSource() ;
/// ReceivePort rxPort = ReceivePort();
/// ls.start(rxPort)
/// rxPort.listen((data) {
///     print('Receiving: ' + data + ', ');
///     ConsoleLoggerEntry cle = ConsoleLogEntry.fromMap(data) ;
///     // now we can push it to the console log viewer
/// });
/// // later on...
/// ls.pause()..
/// ls.resume() ..
/// ls.stop()
///
/// Internally the UDP server is on an Isolate and we get UDP messages over the _rxPort.sendPort
//  This entity creates a Stream<ConsoleLoggerEntry> for clients to access.
//  start() will start the UDP server and as messages arrive, they are decoded to
//  ConsoleLoggerEntry's and add to the sink.
//  stop() will end the UDP server and the stream too.
class UDPLogSource {

  static Isolate _isolate;
  static bool _isPaused = false ;
  static bool get isPaused => _isPaused ;

  static bool _isStarted = false ;
  static bool get isStarted => _isStarted ;

//  static Timer _timer ;
  static RawDatagramSocket _socket ;
  static int _port=17003 ;

  static ReceivePort _rxPort ;
  static StreamController<ConsoleLoggerEntry> _streamController = StreamController.broadcast() ;
  static Stream<ConsoleLoggerEntry> get stream => _streamController.stream ;
  static bool get hasListener => _streamController.hasListener ;

  static Future<void> start() async {
    _rxPort = ReceivePort() ;
    _isolate = await Isolate.spawn(
//      _logMessageGenerator,
        _setupUDPSvr,
        _rxPort.sendPort);
    _rxPort.listen((data) {
        print(data) ;
        ConsoleLoggerEntry cle = ConsoleLoggerEntry.fromMap(data) ;
        print(cle.toFormattedString) ;
        _streamController.sink.add(cle) ;
    }) ;
    _isStarted = true ;
    _isPaused = false ;
  }

  static void pause() {
    _isolate.pause() ;
    _isPaused = true ;
  }

  static void resume() {
    _isolate.resume(Capability()) ;
    _isPaused = false ;
  }

  static void stop() {
    if (stream != null) {
      _streamController.close() ;
    }

//    if (_timer != null) {
//      _timer.cancel() ;
//    }

    if (_socket != null) {
      _socket.close() ;
    }

    if (_isolate != null) {
      print('Stopping Isolate...');
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;
    }

    _isStarted = false ;
    _isPaused = false ;
    _rxPort = null ;
  }

  static void _setupUDPSvr(SendPort sendPort) {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, _port).then((RawDatagramSocket socket){
      _socket = socket ;
      print('Local UDP Logging server ready to receive');
      print('${socket.address.address}:${socket.port}');

      socket.listen((RawSocketEvent e){
        Datagram d = socket.receive();
        if (d == null) {
          print('null datagram...') ;
        }
        else {
          String encodedLogEntry = new String.fromCharCodes(d.data);

          print(encodedLogEntry) ;

          // May or may-not have ANSI color encoding info
          ConsoleLoggerEntry cle = ConsoleLoggerEntry.fromConsoleMsg(encodedLogEntry) ;
          if (cle == null) {
            // decode of log msg failed
          }
          else {
            // Don't send entry to controller is it is paused or has NO listeners.  hasListener answers
            // whether or not there is a subscriber on the Stream.
            if (! _streamController.isPaused) {
//            if (_streamController.hasListener && (! _streamController.isPaused) ) {
              sendPort.send(cle.toJsonMap);
            }
          }
        }
      });
    });
  }
}

/// Toggle between running and paused
//  static void toggle() {
//    if (isPaused) {
//      _isolate.resume(Capability()) ;
//    }
//    else {
//      _isolate.pause() ;
//    }
//  }


//        print('Datagram from ${d.address.address}:${d.port}: ${message.trim()}');
//
//        socket.send(message.codeUnits, d.address, d.port);


///// This can be used to simulate console log msgs
//static void _logMessageGenerator(SendPort sendPort) {
//  int _count = 0 ;
//
//  _timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
//  String level = AppUtil.randomIn(['E', 'D', 'W', 'I', 'V']) ;
//  int time = (DateTime.now().millisecondsSinceEpoch / 10000).toInt() ;
//  String msg = AppUtil.randomGenerateSentence(3, 15) ;
//  String tag = AppUtil.randomIn(['foo', 'bar', 'zot', 'wingo', 'mo', 'wifi', 'i2c']) ;
//  var entry = ConsoleLoggerEntry(_count++, level, time, tag, msg);
//  sendPort.send(entry.toJsonMap) ;
//  });
//}



//  // Will continually send generated ConsoleLoggerEntry.toJsonMap every 2 seconds
//  static void start(SendPort sendPort) async {
//    // Isolate is now its own Thread.  We can only communicate over the ports
//    _isolate = await Isolate.spawn(
////        _logMessageGenerator,
//        _setupUDPSvr,
//        sendPort);
//  }