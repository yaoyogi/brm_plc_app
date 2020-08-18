//
// Flutter
//

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

//
// App
//
import 'package:brmplcapp/prx_integ/prx_aggr.dart';
import 'package:brmplcapp/prx_integ/prx_comm.dart';


/**
 * This is a polling-based Isolate.  The isolate will periodically call the PLC to get its bulk
 * status.  The status values are converted to a PrxAggr2 and made available via the provider
 * member.  The provider is a ChangeNotifier and you can register interest in the notifier for
 * when new PLC data is available.  See notes on the AggrProvider such as copying the values from
 * it to have a private copy that won't be updated on the next poll.
 *
 * Note that errors from the PLC are not visible and for that poll, no new Aggr values are produced.
 * This is not optimal solution, but enough to get us going for now...
 *
 * The polling period a Duration.  It's value can be changed by calling setPollDuration(Duration).
 * If the isolate
 */
class PrxDataPump {
  static Isolate _isolate;
  static Capability _pauseCapability ;
  static bool isStarted = false ;
  static bool isPaused = false ;

  static Timer _timer ;
  static Duration _pollDuration = Duration(milliseconds: 250) ;

  static bool get isStopped {
    return !isStarted;
  }

  /**
   * Answer true is the pump isStarted or isActive, else answer false
   */
  static bool get isActive {
    return isStarted || isPaused ;
  }

  static void start() async {
    ReceivePort receivePort = ReceivePort(); //port for this main isolate to receive messages.

    _isolate = await Isolate.spawn(_runTimer, receivePort.sendPort);
    isStarted = true ;
    isPaused = false ;
    _pauseCapability = null ;

    receivePort.listen((data) {
      Uint8List v = data;
      if (v.length == 0) {
        // We got an error from the PLC, so no bytes for this poll period
      } else {
        AggrProvider.Global.aggr.from_bytes(data);
        AggrProvider.Global.notifyListeners() ;
//        provider.notifyListeners();
      }
    });
  }

  static void _runTimer(SendPort sendPort) async {
    print(">> _runTimer(..)") ;
    _timer = Timer.periodic(_pollDuration, (Timer t) {
//      PrxComm.getPlcData().then((data) {
      PrxComm.getPlcData().then((data) {
        if (data == null || data.length == 0) {
          print('!! timeout or other error, so no data available from this request');
        } else {
          sendPort.send(data);
        }
      });
    });
  }

  /**
   * NOTE: stop() does NOT clear any of the AggProvider registered listeners.  This is
   * by design.
   *
   *
   */
  static void stop() {
    if (_timer != null) {
      stdout.writeln("cancelling the timer") ;
      _timer.cancel();
    }

    if (_isolate == null) {
      return;
    }

    stdout.writeln('killing PrxDataPump isolate');
    _isolate.kill(priority: Isolate.immediate);

    _isolate = null;
    _pauseCapability = null ;
    _timer = null ;

    isStarted = false ;
    isPaused = false ;
  }

  static void pause() {
    if (_isolate == null) {
      return ;
    }

    if (_pauseCapability != null) {
      print('Already paused') ;
      return ;
    }

    _pauseCapability = _isolate.pause() ;

    isPaused = true ;
  }

  static void resume() {
    if (_isolate == null) {
      return ;
    }

    if (_pauseCapability == null) {
      print('Not paused') ;
      return ;
    }

    _isolate.resume(_pauseCapability) ;

    _pauseCapability = null ;
    isPaused = false ;
  }
}