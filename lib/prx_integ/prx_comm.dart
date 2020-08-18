//
// Flutter
//
//import 'package:flutter/material.dart'; // for ChangeNotifier

//import 'dart:io';
import 'dart:async';
//import 'dart:isolate';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

//
// App
//
import 'package:brmplcapp/prx_integ/switch_dev.dart';
import 'package:brmplcapp/prx_integ/valve_dev.dart';

/// Provides the main communications with the PLC
/// Currently all the behavior is static.
class PrxComm {
  static http.Client client = http.Client() ;

  static Future<Uint8List> getPlcData() async {
    Completer c = Completer<Uint8List>();

    http.post("http://192.168.1.177/all", headers: {'brm': 'prx'}).catchError((err) {
      print('in catchError(..) for http.post(..)');
      print(err);
      c.complete(Uint8List(0));
    }).then((response) {
      if (response == null) {
        // MrP: Not much we can do, except to skip this error condition...
        print('http.post response was null') ;

        // The .catchError(..) has already done the c.complete(Uint8List(0));
      }
      else {
        c.complete(response.bodyBytes);
      }
    });

    return c.future;
  }

  static Future<String> updateMocks(String json) async {
    Completer c = Completer<String>();

    Future<http.Response> fr =
    http.post('http://192.168.1.177/mock/set', headers: {'brm': 'prx'}, body: json).catchError((err) {
      print('in catchError(..) for http.post(..)');
      print(err);
      c.complete(null);
    }).then((response) {
      if (response == null) {
        // MrP: Not much we can do, except to skip this error condition...
        print('http.post response was null') ;
        // Note we were already completed in the .catchError(..) so no need to complete here
      }
      else {
        c.complete(response.body);
      }
    });

    return c.future;
  }

  /// Answer PLC Mock details as JSON payload.  Returns null if any communication error.
  static Future<String> getMocks() async {
    Completer c = Completer<String>();

    String body = 'mock details out' ;
    http.post('http://192.168.1.177/mock/all', headers: {'brm': 'prx'}, body: body).catchError((err) {
      print('in catchError(..) for http.post(..)');
      print(err);
      c.complete(null);
    }).then((response) {
      if (response == null) {
        // MrP: Not much we can do, except to skip this error condition...
        print('http.post response was null') ;
        // Note we were already completed in the .catchError(..) so no need to complete here
      }
      else {
        c.complete(response.body);
      }
    });

    return c.future;
  }

  static Future<String> updateValve(ValveDev dev) async {
    // We vary the URL path based on the devices current state.
    String pathOption = dev.state ? 'off' : 'on' ;
    String body = '${dev.id}' ;

    Completer c = Completer<String>();

    Future<http.Response> fr =
    http.post('http://192.168.1.177/valve/$pathOption', headers: {'brm': 'prx'}, body: body).catchError((err) {
      print('in catchError(..) for http.post(..)');
      print(err);
      c.complete(null);
    }).then((response) {
      if (response == null) {
        // MrP: Not much we can do, except to skip this error condition...
        print('http.post response was null') ;
        // Note we were already completed in the .catchError(..) so no need to complete here
      }
      else {
        c.complete(response.body);
      }
    });

    return c.future;
  }

  static Future<String> updateSwitch(SwitchDev dev) async {
    // We vary the URL path based on the devices current state.
    String pathOption = dev.state ? 'off' : 'on' ;
    String body = '${dev.id}' ;

    Completer c = Completer<String>();

    Future<http.Response> fr =
    http.post('http://192.168.1.177/sw/$pathOption', headers: {'brm': 'prx'}, body: body).catchError((err) {
      print('in catchError(..) for http.post(..)');
      print(err);
      c.complete(null);
    }).then((response) {
      if (response == null) {
        // MrP: Not much we can do, except to skip this error condition...
        print('http.post response was null') ;
        // Note we were already completed in the .catchError(..) so no need to complete here
      }
      else {
        c.complete(response.body);
      }
    });

    return c.future;
  }
}

//void main_ish() async {
//  stdout.writeln('spawning isolate...');
//  await start();
//  stdout.writeln('press enter key to quit...');
//  await stdin.first;
//  stop();
//  stdout.writeln('goodbye!');
//  exit(0);
//}

//    try {
//      BRMHttpUtil.httpGet(
//          "http://192.168.1.177/hello",
//          showErrDialog: false,
//          context: null,
//          //      timeout: Duration(seconds: 10),
//          success: ((httpResponse) {
//            var r = httpResponse.bodyBytes;
//            //          print(r) ;
//            //          PrxAggr aggr = PrxAggr() ;
//            //          aggr.from_bytes(r) ;
//            //
//            //          print(aggr) ;
//            //            return r ;
//            c.complete(r);
//          }),
//          onReqErr: (resp) {
//            print('getData had error');
//            print(resp);
//            c.complete(Uint8List(0));
//            //            c.complete(resp.body) ;
//            //          IZFlutterUtil.izShowAlertDialog(context, 'Refresh Error, Request Problem', resp.body) ;
//          },
//          onTimeout: () {
//            print('getData timed out');
//            c.complete(Uint8List(0));
//            //            c.complete('Request timed out') ;
//            //          IZFlutterUtil.izShowAlertDialog(context, 'Refresh Error', 'Request timed out') ;
//          }
//      );
//    }
//    catch(err) {
//      c.complete(Uint8List(0)) ;
//    }
//
//    return c.future ;

//  static void runTimer2(SendPort sendPort) async {
//    while (true) {
////      try {
//      Uint8List data = await getData();
//      if (data.length == 0) {
//        print('!! timeout or other error, so no data from this request');
//      } else {
//        sendPort.send(data);
//      }
////      }
////      catch(e) {
////        print('!! caught exception from getData()') ;
////        print(e) ;
////      }
//    }
////    Timer.periodic(new Duration(seconds: 5), (Timer t) {
////      getData() ;
////      sendPort.send(msg);
////    });
//  }

//  static void runTimer_orig(SendPort sendPort) {
//    int counter = 0;
//    Timer.periodic(new Duration(seconds: 5), (Timer t) {
//      counter++;
////    PrxAggr aggr = PrxAggr() ;
////    var ulist = aggr.toBytes() ;
////    sendPort.send(ulist) ;
//      String msg = 'notification ' + counter.toString();
//      stdout.writeln('SEND: ' + msg + ' - ');
//      print(msg);
//      sendPort.send(msg);
//    });
//  }


//  static Future<String> updateMocks(MockBunch mb) async {
//    Completer c = Completer<String>();
//
//    Uint8List bytes = mb.toBytes() ;
//    Future<http.Response> fr =
//    http.post('http://192.168.1.177/mock/set', headers: {'brm': 'prx'}, body: bytes).catchError((err) {
//      print('in catchError(..) for http.post(..)');
//      print(err);
//      c.complete(null);
//    }).then((response) {
//      if (response == null) {
//        // MrP: Not much we can do, except to skip this error condition...
//        print('http.post response was null') ;
//        // Note we were already completed in the .catchError(..) so no need to complete here
//      }
//      else {
//        c.complete(response.body);
//      }
//    });
//
//    return c.future;
//  }


//  static Future<Uint8List> getMocks(MockBunch mb) async {
//    Completer c = Completer<Uint8List>();
//
//    String body = 'mock details out' ;
//    Future<http.Response> fr =
//    http.post('http://192.168.1.177/mock/all', headers: {'brm': 'prx'}, body: body).catchError((err) {
//      print('in catchError(..) for http.post(..)');
//      print(err);
//      c.complete(null);
//    }).then((response) {
//      if (response == null) {
//        // MrP: Not much we can do, except to skip this error condition...
//        print('http.post response was null') ;
//        // Note we were already completed in the .catchError(..) so no need to complete here
//      }
//      else {
//        c.complete(response.bodyBytes);
//      }
//    });
//
//    return c.future;
//  }


//  static actionGetSingleUpdate() {
////      IZFlutterUtil.toast(context, "Making call to get status") ;
//    print('hello...');
//    BRMHttpUtil.httpPost(
//        "http://192.168.1.177/all",
//        headers: {'brm': 'prx'},
//        showErrDialog: false,
//        context: null,
//        timeout: Duration(seconds: 1),
//        success: ((httpResponse) {
//          var r = httpResponse.bodyBytes;
////            print(r) ;
//          setState(() {
//            // We take the PLC status binary and update the
//            AggrProvider.Global.aggr.from_bytes(r);
//            AggrProvider.Global.update();
////            PlcStatusPollerAppState.aggr.from_bytes(r) ;
////            PrxDataPump.provider.update() ;
//
//          });
////          PrxAggr2 px2 = PlcStatusPollerAppState.aggr ;
////          print('updated from bytes, $px2') ;
////            print('updated _as.aggr.from_bytes(r)') ;
//
////            print(r) ;
////            PrxAggr2 aggr = PrxAggr2() ;
////            aggr.from_bytes(r) ;
////
////            print(aggr) ;
//
//        }),
//        onReqErr: (resp) {
////            c.complete(resp.body) ;
//          BRMFlutterUtil.toast(context, "Refresh Error, Request Problem.  " + resp.body);
////            IZFlutterUtil.izShowAlertDialog(context, 'Refresh Error, Request Problem', resp.body) ;
//        },
//        onTimeout: () {
////            c.complete('Request timed out') ;
//          BRMFlutterUtil.toast(context, "Refresh Error, Request timed out.  ");
////            IZFlutterUtil.izShowAlertDialog(context, 'Refresh Error', 'Request timed out') ;
//        }
//    ) ;
//  }

//  static Future<Uint8List> getPlcData() async {
//    Completer c = Completer<Uint8List>();
//
//    String body = null ;
//    client.post('http://192.168.1.177/all', headers: {'brm': 'prx'}, body: body).catchError((err) {
//      print('in catchError(..) for http.post(..)');
//      print(err);
//      c.complete(null);
//    }).then((response) {
//      if (response == null) {
//        // MrP: Not much we can do, except to skip this error condition...
//        print('http.post /all response was null') ;
//        // Note we were already completed in the .catchError(..) so no need to complete here
////        c.complete(null) ;
//      }
//      else {
//        c.complete(response.bodyBytes);
//      }
//    });
//
//    return c.future;
//  }

