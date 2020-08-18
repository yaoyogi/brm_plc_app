import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // AppEnv

//
// Dart
//
import 'dart:convert' as convert;
import 'dart:math'; // for random()
import 'dart:async'; // for Completer
import 'dart:typed_data'; // for Uint8List
import 'dart:io'; // for XXX
import 'dart:collection';   // for Map

import 'package:http/http.dart' as http;

import 'package:sprintf/sprintf.dart';

import 'package:get_ip/get_ip.dart'; // get_ip, detect ESP32 devices

import 'package:shared_preferences/shared_preferences.dart';


import 'package:connectivity/connectivity.dart';  // detect wifi, cellular

//
// Ismintis
//
import 'package:brmplcapp/brm_json/brm_json_util.dart';
import 'package:brmplcapp/common/brm_flutter_util.dart';

//
// App
//


//
// 3rd Party
//


/// Constants for Navigation
class Navi {
  static const String HOME = '/';

  static const String SPLASH = '/splash';

  static const String SETTINGS = '/app_env';

  static const String CIRCULATION = '/circulation';

  static const String IBC_TRANSFER = '/ibc_transfer';

  static const String THERMO = '/thermo';

  static const String MOCKS = '/mocks';

  static const String EVENTS = '/events';

  static const String PROCESSES = '/processes';

  static const String EX_STATE_MGMT = '/ex/state_mgmt';

  static const String OVERVIEW = '/overview' ;

  static const String GRAPHS = '/graphs' ;

  static const String HELP = '/help' ;

  static const String VALIDATOR = '/sherlock' ;

  static const String LOGGER_CONSOLE_VIEWER = '/logger/console_viewer';
  static const String LOGGER_UDP_MGR = '/logger/udp_mgr';
  static const String LOGGER_SEND_MSG = '/logger/send_msg';
//  static const String LOGGER_ESP32_SIDE_FILE_LOGGER = '/logger/esp32_side_file';
  static const String LOGGER_LOCAL_FILE_LOGGER = '/logger/local_file';
  static const String LOGGER_LEVELS = '/logger/levels';


  static const Map<String, String> map = {
    'HOME': Navi.HOME,
    'APP_ENV': Navi.SETTINGS,
    'CIRCULATION': Navi.CIRCULATION,
    'IBC_TRANSFER': Navi.IBC_TRANSFER,
    'THERMO': Navi.THERMO,
    'MOCKS': Navi.MOCKS,
    'EVENTS': Navi.EVENTS,
    'PROCESSES': Navi.PROCESSES,

    //
    // Examples, Testing, Misc -- NOT FOR PRODUCTION
    //

    'EX_STATE_MGMT': Navi.EX_STATE_MGMT,
  };
}

class AppUtil {
  static final _random = Random();
  static UrlMgr urlMgr = UrlMgr();

  static String fmt(double v, [String fmt='%10.3f']) {
    return sprintf(fmt, [v]) ;
  }

  /// Answer null if passed in String is an ip-address else answers an error String.
  static String isIPAddr(String s) {
    if (s == null) {
      return 'IP-address must not be null';
    }
    if (s.isEmpty) {
      return 'IP-address must not be empty String';
    }
    List<String> parts = s.split(RegExp('\\.'));
    if (parts.length != 4) {
      return 'Invalid IP-address syntax, must have 4 parts';
    }
    for (String part in parts) {
      int seg = int.tryParse(part);
      if (seg == null || seg < 0) {
        return 'Invalid IP-address syntax, each part must be a positive number';
      }
    }
    return null;
  }

  static void reqErrDialog(BuildContext context, String url, int statusCode) {
    BRMFlutterUtil.brmShowAlertDialog(
        context, 'Retrieval Error: ' + url, "Request failed with status: $statusCode");
  }

//  static String randomGenerateSentence(int min, int max) {
//    int r = min + _random.nextInt(max - min);
//    var s = '';
//    generateAdjective().take(r).forEach((adj) {
//      s += (adj.toString() + ' ');
//    });
//    return s;
//  }
//
//  static String randomIn(List<String> list) {
//    if (list.isEmpty) {
//      return 'nothing';
//    }
//    return list[_random.nextInt(list.length)]; // [0..length) -- exclusive of length
//  }

  /// Answer the int value from the passed in String.  The string may be in
  /// decimal format or hex.  The recognized decimal/hex formats are based on Darts int.tryParse(..).
  /// For hex we allow for '0X', '0x', 'X' and 'x' for convenience
  /// Returns null if can't be converted
  static int postiveIntFromStr(String v) {
    if (v ==  null) {
      return null ;
    }
    v = v.toLowerCase() ;
    bool isHex = false ;
    if (v.startsWith('0x')) {
      v = v.substring(2) ;
      isHex = true ;
    }
    else if (v.startsWith('x')) {
      v = v.substring(1) ;
      isHex = true ;
    }

    int r = isHex
        ? int.tryParse(v, radix: 16)
        : int.tryParse(v, radix: 10) ;

    print('in: $v, out: $r') ;

    return r ;
  }

  // We need to turn the single-space-delimited or CSV's into byte values we can write.
  // First we need to parse to get list of values
  // Each individual value:
  //    Can be decimal or hex
  //    Must convert to int value [0..255] -- a single unsigned byte
  static List<int> positiveIntsFromString(String v) {
    List<dynamic> ls ;
    if (v.contains(",")) {
      CsvToListConverter ctol = CsvToListConverter() ;
      List<List<dynamic>> lol = ctol.convert(v) ;
      if (lol.isEmpty) {
        print('Failed to parse string using commas') ;
        return [ ] ;
      }

      ls = lol[0] ;
    }
    else {
      ls = v.split(" ") ;
      if (ls.isEmpty) {
        print('Failed to parse using single-space') ;
        return [ ];
      }
    }

    // We have a list of Strings, We need to convert each value in the list to an int [0..255]
    List<int> r = List<int>(ls.length) ;
    for(int i = 0; i < ls.length; i++) {
      dynamic intVal ;    // string or number
      try {
        intVal = ls[i] ;
        intVal = (intVal is int) ? intVal : postiveIntFromStr(intVal) ;
        if (intVal == null) {
          print('Failed to convert: ${ls[i]} to int') ;
          return [ ] ;
        }
      }
      catch(ex) {
        print("Failed to convert: '${ls[i]}' to int") ;
        return [ ] ;
      }
      if (intVal < 0 || intVal > 255) {
        print("Value at position $i must be > 0 and <= 255") ;
        return [ ] ;
      }
      r[i] = intVal ;
    };

    return r ;
  }

  static bool isValidUrl(String proposedUrl) {
    try {
      Uri uri = Uri.parse(proposedUrl);
      return uri.isAbsolute;
    }
    catch (e) { // FormatException is the normal error from invalid URI --
      return false;
    }
  }

  static isNumeric(string) => num.tryParse(string) != null;
}

class BRMAppFlutterUtil {
  static Text monoText(String v, {double scale=1.0}) {
    return Text(v, style: TextStyle(fontFamily: 'IBM_Plex_Mono'), textScaleFactor: scale)  ;
  }

  static Widget createIconic() {
    return Column(
      children: <Widget>[
        Material(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          color: Colors.white,
          elevation: 10,
          child: Padding(
            padding: EdgeInsets.all(4.0),
            child: Image.asset("assets/images/splash.jpeg", height: 90, width: 90),
          ),
        ),
        Text(
          'BarrelRM',
          style: TextStyle(color: Colors.white, fontSize: 25.0),
        )
      ], mainAxisAlignment: MainAxisAlignment.center,
    ) ;
  }

  static Widget createQuickNav(BuildContext context, String choice) {
    List<String> keys = Navi.map.keys.toList() ;
    keys.sort((a, b) => a.compareTo(b));

    var megaNav = BRMFlutterUtil.createDropdownButton(
        choice,
        keys, (value) {
//      setState(() {
//        _megaNavChoice = value;
//      });
      String path = Navi.map[value] ;
      Navigator.pushNamed(context, path) ;
    }) ;
  }

  static EdgeInsets get commonPadding {
    return EdgeInsets.all(10.0);
  }

  static Decoration commonBoxDeco() {
    return BoxDecoration(border: Border.all(color: Colors.blueGrey)) ;
  }

//  static void esp32ResetViaPartitions(BuildContext context) {
//    IZFlutterUtil.toast(context, 'Telling ESP32 to reset', 1);
//    String url = AppUtil.urlMgr.esp32AdminPartitionChipReset;
//    httpPostWithJsonRpcResp(context, url, null) ;
//  }
//
//  static void esp32ResetViaPersistentInfo(BuildContext context) {
//    IZFlutterUtil.toast(context, 'Telling ESP32 to reset', 1);
//
//    BRMHttpUtil.httpPost(
//      AppUtil.urlMgr.esp32AdminPiChipReset,
//      body: null,
//      showErrDialog: true,
//      context: context,
//      timeout: Duration(seconds: 5),
//      success: ((httpResponse) {
//        var jsonResponse = convert.jsonDecode(httpResponse.body);
//        if (jsonResponse['result'] != null) {
//          var resp = jsonResponse['result'].toString() ;
////          IZFlutterUtil.toast(context, resp, 3);
//          IZFlutterUtil.izAcknowledgeDialog(context, 'Reset', resp) ;
//        } else {
//
//          IZFlutterUtil.toast(context, jsonResponse['error'].toString(), 3);
//        }
//      }),
//    );
//  }

  // Body can be bytes or JSON
  static void httpPostWithJsonRpcResp(BuildContext context, String postUrl, dynamic body) {
    print('post url: ' + postUrl + ' body: ' + body.toString());

    BRMHttpUtil.httpPost(
      postUrl,
      body: body,
      showErrDialog: true,
      context: context,
      success: ((httpResponse) {
        var jsonResponse = convert.jsonDecode(httpResponse.body);
        if (jsonResponse['result'] != null) {
          BRMFlutterUtil.brmAcknowledgeDialog(context, 'Response', jsonResponse['result'].toString());
        } else {
          BRMFlutterUtil.brmShowAlertDialog(context, 'Request Error', jsonResponse['error'].toString());
        }
      }),
    );
  }

//  static void xxx(BuildContext context, String label, bool setAsBoot, bool chipReset, List<int> bytes) {
//    int newBinaryLen = bytes.length ;
//    // The ESP32 in this usage case does about 50K/second for flashing.
//    double sizeInK = newBinaryLen / 1000.0 ;
//    int approxFlashTimeInSecs = (sizeInK / 50.0).toInt() ;
//    String msg = 'read bytes: $newBinaryLen, approx flash time: $approxFlashTimeInSecs seconds' ;
//    print(msg);
//    IZFlutterUtil.toast(context, msg, 8) ;
//    String reqUrl = AppUtil.urlMgr.esp32AdminPartitionUpdatePartitionFromBody ;
//    if (label == '<next partition>') {
//      // If we don't send the label param, the call will look for the next-update-partition
//      reqUrl += ('?set_as_boot=$setAsBoot&chip_reset=$chipReset');
//    }
//    else {
//      reqUrl += ('?label=$label&set_as_boot=$setAsBoot&chip_reset=$chipReset');
//    }
//
//    IZAppFlutterUtil.httpPostWithJsonRpcResp(context, reqUrl, bytes);
//  }

//  static Future<List<int>> getUrlContents(BuildContext context, String localUrl) async {
//    Completer<List<int>> completer = Completer() ;
//
//    List<int> bytes = List<int>();
//    HttpClient client = HttpClient();
//    Uri uri = Uri.parse(localUrl);
//    Future<HttpClientRequest> futureReq = client.getUrl(uri);
//    futureReq.timeout(Duration(seconds: 8)).then((req) {
//      // Need return here to complete the future contract
//      return req.close();
//    }).then((resp) {
//      resp.listen((d) {
//        bytes.addAll(d);
//      }, onDone: () {
//        completer.complete(bytes) ;
//      }, onError: (err) {
//        print(err.toString());
//        IZFlutterUtil.toast(context, 'Error getting bytes from URL. ' + err.toString(), 3);
//        completer.complete(null) ;
//      });
//    }).whenComplete(() {
//      print('What is this?') ;
//    });
//
//    return completer.future ;
//  }

//  static updatePartitionFromLocalFile(
//      BuildContext context, String filePath, String partitionLabel,
//      {bool set_as_boot=false, bool chip_reset=false})
//  {
//    File fil = File(filePath);
//    if (!fil.existsSync()) {
//      IZFlutterUtil.izShowAlertDialog(context, 'Incorrect Info', 'Could not find specified file');
//      return;
//    }
//
//    if (!(fil is File)) {
//      IZFlutterUtil.izShowAlertDialog(context, 'Incorrect Info', 'Update file must not be a directory');
//      return;
//    }
//
//    Uint8List bytes;
//    try {
//      bytes = fil.readAsBytesSync();
//      print('read num bytes: ${bytes.length}');
//    } on Error {
//      IZFlutterUtil.izShowAlertDialog(context, 'Error', 'Error reading file, update cancelled');
//      return;
//    }
//
//    String reqUrl = AppUtil.urlMgr.esp32AdminPartitionUpdatePartitionFromBody ;
//    if (partitionLabel == '<next partition>') {
//      // If we don't send the label param, the call will look for the next-update-partition
//      reqUrl += ('?set_as_boot=$set_as_boot&chip_reset=$chip_reset');
//    }
//    else {
//      reqUrl += ('?label=$partitionLabel&set_as_boot=$set_as_boot&chip_reset=$chip_reset');
//    }
//    BRMAppFlutterUtil.httpPostWithJsonRpcResp(context, reqUrl, bytes);
//  }
//
//  static updateFromResourceAccessOnESP32(
//      BuildContext context, String resource, {String label, bool set_as_boot=false, bool chip_reset=false})
//  {
//    var body = {'resource': resource, 'set_as_boot': set_as_boot, 'chip_reset': chip_reset} ;
//    if (label != null) {
//      body['label'] = label ;
//    }
//    var jsonBody = BRMJsonUtil.jsonEncode(body);
//
//    String url = AppUtil.urlMgr.esp32AdminPartitionUpdatePartitionFromResource ;
//    BRMAppFlutterUtil.httpPostWithJsonRpcResp(context, url, jsonBody);
//  }
}

class BRMHttpUtil {
  static String urlFromMap(Map<String, dynamic> map) {
    bool firstSeen = false ;
    String r = '' ;
    map.forEach((k, v) {
      if (firstSeen) {
        r += '&' ;
      }
      r += k ;
      r += '=' ;
      r += Uri.encodeQueryComponent(v.toString()) ;

      firstSeen = true ;
    }) ;

    return r;
  }

  static void commonPost(BuildContext context, String url, dynamic body, Function(String response) onSuccess) {
    if (body == null) {
      body = BRMJsonUtil.jsonEncode({});
    }
    BRMHttpUtil.httpPost(
      url,
      body: body,
      showErrDialog: true,
      context: context,
      success: ((httpResponse) {
        var jsonResponse = convert.jsonDecode(httpResponse.body);
        var result = jsonResponse['result'];
        if (result != null) {
          var r = jsonResponse['result'].toString();
          onSuccess(r);
          BRMFlutterUtil.toast(context, r);
        } else {
          BRMFlutterUtil.toast(context, jsonResponse['error'].toString(), 3);
        }
      }),
    );
  }

  // body:xxx is String, List or Map -- see _httpBodyOp(..) for details
  static void httpPost(
      String url, {
        // named optional arguments
        Map<String, String> headers,
        dynamic body,
        convert.Encoding encoding,
        Function(http.Response r) success,
        Function(http.Response r) onReqErr,
        Duration timeout = const Duration(seconds: 0),
        Function() onTimeout,
        bool showErrDialog = false,
        BuildContext context,
      }) async {
    _httpBodyOp('post', url,
        headers: headers,
        body: body,
        encoding: encoding,
        success: success,
        onReqErr: onReqErr,
        timeout: timeout,
        onTimeout: onTimeout,
        showErrDialog: showErrDialog,
        context: context);
  }

  // body:xxx is String, List or Map -- see _httpBodyOp(..) for details
  static void httpPut(
      String url, {
        // named optional arguments
        Map<String, String> headers,
        dynamic body,
        convert.Encoding encoding,
        Function(http.Response r) success,
        Function(http.Response r) onReqErr,
        Duration timeout = const Duration(seconds: 0),
        Function() onTimeout,
        bool showErrDialog = false,
        BuildContext context,
      }) async {
    _httpBodyOp('put', url,
        headers: headers,
        body: body,
        encoding: encoding,
        success: success,
        onReqErr: onReqErr,
        timeout: timeout,
        onTimeout: onTimeout,
        showErrDialog: showErrDialog,
        context: context);
  }

  static void httpGet(
      String url, {
        // named optional arguments
        Map<String, String> headers,
        Function(http.Response r) success,
        Function(http.Response r) onReqErr,
        Duration timeout = const Duration(seconds: 0),
        Function() onTimeout,
        bool showErrDialog = false,
        BuildContext context,
      }) async {
    _httpBodyOp('get', url,
        headers: headers,
        success: success,
        onReqErr: onReqErr,
        timeout: timeout,
        onTimeout: onTimeout,
        showErrDialog: showErrDialog,
        context: context);
  }

  static void httpDelete(
      String url, {
        // named optional arguments
        Map<String, String> headers,
        Function(http.Response r) success,
        Function(http.Response r) onReqErr,
        Duration timeout = const Duration(seconds: 0),
        Function() onTimeout,
        bool showErrDialog = false,
        BuildContext context,
      }) async {
    _httpBodyOp('delete', url,
        headers: headers,
        success: success,
        onReqErr: onReqErr,
        timeout: timeout,
        onTimeout: onTimeout,
        showErrDialog: showErrDialog,
        context: context);
  }

  // This works for all HTTP verbs.  For the head, get, delete verbs the body and
  // encoding are no-ops.
  // onReqErr is for non-200 HTTP responses.  Note this MAY NOT be the right choice
  // as some success operations would be 404 or 409 or such...
  //
  // body:xxx sets the body of the request. It can be a String, a List or a Map. If it's a String,
  // it's encoded using encoding and used as the body of the request. The content-type of
  // the request will default to "text/plain".
  // If body is a List, it's used as a list of bytes for the body of the request.
  // If body is a Map, it's encoded as form fields using encoding. The content-type of the
  // request will be set to "application/x-www-form-urlencoded"; this cannot be overridden.
  static void _httpBodyOp(
      String op,
      String url, {
        // named optional arguments
        Map<String, String> headers,
        dynamic body,
        convert.Encoding encoding,
        Function(http.Response r) success,
        Function(http.Response r) onReqErr,
        Duration timeout = const Duration(seconds: 0),
        Function() onTimeout,
        bool showErrDialog = false,
        BuildContext context,
      }) async {
    Future<http.Response> fr;
    if (op == 'post')
      fr = http.post(url, headers: headers, body: body, encoding: encoding);
    else if (op == 'put')
      fr = http.put(url, headers: headers, body: body, encoding: encoding);
    else if (op == 'patch')
      fr = http.patch(url, headers: headers, body: body, encoding: encoding);

    // GET, DELETE, HEAD have no body/encoding
    else if (op == 'get')
      fr = http.get(url, headers: headers);
    else if (op == 'delete')
      fr = http.get(url, headers: headers);
    else if (op == 'head')
      fr = http.get(url, headers: headers);
    else
      throw new UnsupportedError('unknown HTTP operation: ' + op);

    if (timeout.inSeconds != 0) {
      // If onTimeout is not specified then a timeout will result in TimeoutException being thrown
      fr.timeout(timeout, onTimeout: onTimeout);
    }
    fr.then((response) {
      if (response.statusCode == 200) {
//        var jsonResponse = convert.jsonDecode(response.body);
        success(response);
      } else {
        if (onReqErr != null) {
          onReqErr(response);
        }
        if (showErrDialog) {
          AppUtil.reqErrDialog(context, url, response.statusCode);
        }
      }
    }).catchError((err) {
      // This would be unexpected error vs HTTP error response.
      print("Fatal error on request execution.");
      print(err.toString());
//      if (onReqErr != null) {
//        onReqErr(err.toString()) ;
//      }
      if (showErrDialog) {
        AppUtil.reqErrDialog(context, 'URL: $url, failed with: ${err.toString()}', -1);
      }

      // MrP: This death to the client at this point unless we throw something.
      // I think we need to throw some sort of catchall exception we own vs. trying to unwind via
      // handlers etc...
      throw err ;
    });
  }
}

class ComparableListItem<T extends Comparable<T>> {
  bool isSelected = false; //Selection property to highlight or not
  T data; //Data of the user
  Icon leadingIcon;
  Icon trailingIcon;
  ComparableListItem(this.data, this.isSelected); //Constructor to assign the data
}

/// All of the getters results should NOT be cached by clients.
class UrlMgr {
  UrlMgr() {
    // Empty on purpose
  }

  // As this is public it can be poked by code.  Currently the Find-ESP32's screen can poke this
  // value when a broadcasting mDNS ESP32 is "made current"
  String esp32IpAddr = AppEnv.esp32DeviceIpAddr ; //'192.168.1.200';
  String esp32WebAccessScheme = 'http'; // or 'https'
//  String esp32WebsocketAccessScheme = 'ws' ; // or 'wss'

  //
  // NVS
  //
//  String get esp32AdminNvsList =>           wsep('/admin/nvs/list') ;
//  String get esp32AdminNvsSetValue =>       wsep('/admin/nvs/set_value') ;
//  String get esp32AdminNvsEraseKey =>       wsep('/admin/nvs/erase_key') ;
//  String get esp32AdminNvsEraseNamespace => wsep('/admin/nvs/erase_namespace') ;

  //
  // Persistent Info
  //
//  String get esp32AdminPi => wsep('/admin/pi');               // for GET and POST

  //
  // Partitions
  //
//  String get esp32AdminPartitionChipReset => wsep('/admin/partitions/chip_reset');

  //
  // Dev OTA
  //

  //
  // Admin
  //
//  String get esp32AdminChipReset => wsep('/admin/chip/reset');
//  String get esp32AdminListWseps => wsep('/admin/list_wseps');

  //
  // FS
  //
//  String get esp32AdminFsExists => wsep('/admin/fs/exists');
//  String get esp32AdminFsListEntriesStat => wsep('/admin/fs/list_entries_stat');
//  String get esp32AdminFsListEntries => wsep('/admin/fs/list_entries');
//  String get esp32AdminFsMkdir => wsep('/admin/fs/mkdir');
//  String get esp32AdminFsRemove => wsep('/admin/fs/remove');
//  String get esp32AdminFsCopy => wsep('/admin/fs/copy');
//  String get esp32AdminFsRead => wsep('/admin/fs/read');
//  String get esp32AdminFsRename => wsep('/admin/fs/rename');
//  String get esp32AdminFsWrite => wsep('/admin/fs/write');
//  String get esp32AdminFsStat => wsep('/admin/fs/stat');
//  String get esp32AdminFsIsDir => wsep('/admin/fs/is_dir');
//  String get esp32AdminFsIsFile => wsep('/admin/fs/is_file');
//  String get esp32AdminFsVfsDetails =>wsep('/admin/fs/vfs_details');
//  String get esp32AdminFsVfsOp => wsep('/admin/fs/vfs_op');
//  String get esp32AdminFsUrlToFile => wsep('/admin/fs/url_to_file');

  //
  // Logging
  //
  String get esp32AdminLogUdpCreate =>  wsep('/admin/esp_log/udp/create');
  String get esp32AdminLogUdpStart =>   wsep('/admin/esp_log/udp/start');
  String get esp32AdminLogUdpDetails => wsep('/admin/esp_log/udp/details');
  String get esp32AdminLogUdpPause =>   wsep('/admin/esp_log/udp/pause');
  String get esp32AdminLogUdpStop =>    wsep('/admin/esp_log/udp/stop');
  String get esp32AdminLogUdpRemove =>  wsep('/admin/esp_log/udp/remove');
  String get esp32AdminLogWrite =>      wsep('/admin/esp_log_write');
  String get esp32AdminLogFileCreate => wsep('/admin/esp_log/file/create');
  String get esp32AdminLogFileDetails =>wsep('/admin/esp_log/file/details');
  String get esp32AdminLogFileStart =>  wsep('/admin/esp_log/file/start');
  String get esp32AdminLogFilePause =>  wsep('/admin/esp_log/file/pause');
  String get esp32AdminLogFileStop =>   wsep('/admin/esp_log/file/stop');
  String get esp32AdminLogFileRemove => wsep('/admin/esp_log/file/remove');
  String get esp32AdminLogLevelSet =>   wsep('/admin/esp_log_level_set'); // POST 'tag': 'xxx', 'level': 'xxx'

  /// Path must begin with a "/"
  String wsep(String path) {
    if (path == null || (! path.startsWith("/"))) {
      print('WSEP path must not be null and must start with "/"') ;
      return "bad path" ;
    }

    // ex: http://192.168.1.200/admin/pi
    String s = esp32WebAccessScheme + '://' + esp32IpAddr + path;
    print(s);
    return s;
  }
}

class AppSession {
  static AppSession only = AppSession();

}

class AppEnv {
  static const String barrelrm_app_note = 'BarrelRM PLC Processor Companion, v1.0.0   2020 \u00a9 BarrelRM' ;

  static String    _devMachineIpAddr = 'unknown';    // The machine this code is running on
  static String get devMachineIpAddr => _devMachineIpAddr ;
  static void   set devMachineIpAddr(String addr) {

    _devMachineIpAddr = addr ;
  }

  static String    _devMachine2IpAddr = 'unknown';   // Secondary machine (possibly servers etc...)
  static String get devMachine2IpAddr => _devMachine2IpAddr ;
  static void   set devMachine2IpAddr(String addr) {

    _devMachine2IpAddr = addr ;
  }

  static int     _udpLoggingPort = 17003 ;
  static int get  udpLoggingPort => _udpLoggingPort ;
  static void set udpLoggingPort(int port) {

    _udpLoggingPort = port ;
  }

  static String    _esp32DeviceIpAddr =  '192.168.4.1' ; // '192.168.1.200'  Primary ESP32 device we interact with
  static String get esp32DeviceIpAddr => _esp32DeviceIpAddr ;
  static void   set esp32DeviceIpAddr(String addr) {
    _esp32DeviceIpAddr = addr ;
    AppUtil.urlMgr.esp32IpAddr = addr ;

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('esp32DeviceIpAddr', addr) ;
    });
  }

  static String    _esp32Device2IpAddr = 'unknown' ;// '192.168.1.201'
  static String get esp32Device2IpAddr => _esp32Device2IpAddr ;
  static void   set esp32Device2IpAddr(String addr) {

    _esp32Device2IpAddr = addr ;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  static Future<void> initPlatformState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getKeys()) ;
    if (prefs.containsKey('esp32DeviceIpAddr')) {
      String s = prefs.getString('esp32DeviceIpAddr') ;
//      setState(() {
      _esp32DeviceIpAddr = s ;  // Don't use SETTER since we don't want to store the value again!
//      }) ;

    }


//    String ipAddress;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      _devMachineIpAddr = await GetIp.ipAddress;
      print('Got IP address: $devMachineIpAddr');
    } on PlatformException {
      print('Failed to get ipAddress');
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      print('I am connected to a mobile network') ;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      print('I am connected to a wifi network.') ;
    }

//    Connectivity c = Connectivity() ;
//    var wifiBSSID = await c.getWifiIP() ;
//    var wifiName = await c.getWifiName() ;
//    var wifiIP = await c.getWifiIP() ;
//    print('wifiIP: $wifiIP') ;

    // Semantics for read are EXCEPTION if not found!!!
    // Semantics for setXXX(null) is same as REMOVE


  }

//  static Future<Socket> _ping(String host, int port, Duration timeout) {
//    return Socket.connect(host, port, timeout: timeout).then((socket) {
//      return socket;
//    });
//  }

//  static Future<bool> detectEndpoint(
//      String host, int port, {Duration duration=const Duration(seconds: 3)}) async
//  {
//    Completer<bool> c = Completer<bool>();
//    try {
//      final Socket s = await Socket.connect(host, port, timeout: duration);
//      s.destroy();
//      c.complete(true);
//    }
//    catch (e) {
//      c.complete(false);
//    }
//    return c.future;
//  }
}


class doubleW{
  double value;
  doubleW(this.value);

  String toString(){
    return value.toString();
  }
}

class intW {
  int value;
  intW(this.value);

  String toString(){
    return value.toString();
  }
}

class boolW{
  bool value;
  boolW(this.value);

  String toString(){
    return value.toString();
  }
}


