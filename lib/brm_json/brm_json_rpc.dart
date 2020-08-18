import 'dart:convert';

import 'package:brmplcapp/brm_json/brm_json_util.dart';
import 'package:brmplcapp/common/brm_flutter_util.dart';

// Allow us to have a typed function signature to enable flexibility in the
// RPC request/response handler implementation.
typedef Future<IZJsonRpcResp> ProcessRpc(IZJsonRpcReq request) ;

/// Used when we are chunking/streaming a JSON-RPC request or response that exceeds
/// some transport limit or some practical size.  Note for BLE-RPC's we are limited
/// to 600 bytes on BLE-Characteristic read/write so chunking is needed for even
/// simple RPC's.
class IZJsonRpcChunk {
  String id ; // original request id, NOT "iz.chunk"

  int sequence ;

  // Total number of bytes being chunked/streamed.  If unknown, must be -1
  int num_total_bytes ;

  int bytes_sent_so_far ;

  // Actual chunk payload
  String payload ;

  //
  // Constructor(s)
  //
  IZJsonRpcChunk(String id, int sequence, int num_total_bytes, int bytes_sent_so_far, String payload) {
    this.id = id ;
    this.sequence = sequence ;
    this.num_total_bytes = num_total_bytes ;
    this.bytes_sent_so_far = bytes_sent_so_far ;
    this.payload = payload ;
  }

  IZJsonRpcChunk.fromJsonStr(String json) {
    Map<String, dynamic> mj = jsonDecode(json);
    _fromJsonMap(mj) ;
  }

  IZJsonRpcChunk.fromJsonMap(Map<String, dynamic> mj) {
    _fromJsonMap(mj) ;
  }

  //
  // API
  //
  bool is_last_chunk() {
    // Even in streaming case where we don't know upfront what n or total bytes are
    // we rely on the last chunk properly setting num_total_bytes.
    return bytes_sent_so_far == num_total_bytes ;
  }

  Map<String, dynamic> toJsonMap() {
    Map<String, dynamic> map = {
      'id': id,
      'sequence': sequence,
      'num_total_bytes': num_total_bytes,
      'bytes_sent_so_far': bytes_sent_so_far,
      'payload': payload
    };
    return map ;
  }

  String toJson() {
    return jsonEncode(toJsonMap()) ;
  }

  @override String toString() {
    return toJson() ;
  }

  //
  // Private
  //
  _fromJsonMap(Map<String, dynamic> mj) {
    id = mj['id'] ;
    sequence = mj['sequence'] ;
    num_total_bytes = mj['num_total_bytes'] ;
    bytes_sent_so_far = mj['bytes_sent_so_far'] ;
    payload = mj['payload'] ;
  }
}

/// A rpc call is represented by sending a Request object to a Server.
class IZJsonRpcReq {
  /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
  String jsonrpc = '2.0' ;

  /// A String containing the name of the method to be invoked. Method names that begin
  /// with the word rpc followed by a period character (U+002E or ASCII 46) are reserved
  /// for rpc-internal methods and extensions and MUST NOT be used for anything else.
  String method ;

  /// A Structured value that holds the parameter values to be used during the invocation
  /// of the method. This member MAY be omitted.  If specified the type must be a List
  /// or a Map
  Object _params ;

  /// An identifier established by the Client that MUST contain a String, Number, or
  /// NULL value if included. If it is not included it is assumed to be a notification.
  /// The value SHOULD normally not be Null [1] and Numbers SHOULD NOT contain fractional parts [2]
  String id ;

  //
  // Constructor(s)
  //
  IZJsonRpcReq.jsonStrParams(String method, String json, [String id]) {
    this.method = method ;
    if (json != null) {
      Map<String, dynamic> mapParams =  jsonDecode(json);
      setParams(mapParams) ;
    }
    if (id != null) {
      this.id = id ;
    }
  }
  IZJsonRpcReq.mapParams(String method,  Map<String, dynamic> params, [String id]) {
    this.method = method ;
    if (params != null) {
      setParams(params) ;
    }
    if (id != null) {
      this.id = id ;
    }
  }
  IZJsonRpcReq.listParams(String method,  List<dynamic> params, [String id]) {
    this.method = method ;
    if (params != null) {
      setParams(params) ;
    }
    if (id != null) {
      this.id = id ;
    }
  }

  IZJsonRpcReq.fromJsonStr(String json) {
    Map<String, dynamic> mj = jsonDecode(json);
    _fromJsonMap(mj) ;
  }

  IZJsonRpcReq.fromJsonMap(Map<String, dynamic> mj) {
    _fromJsonMap(mj) ;
  }

  //
  // API
  //
  static String isValidJson(String json) {
    if (! BRMJsonUtil.isValidJson(json)) {
      return 'Ill-formed JSON' ;
    }

    Map<String, dynamic> m = jsonDecode(json);

    if (m.containsKey('jsonrpc')) { // required - String value 2.0
      if (!m['jsonrpc'] is String) {
        // jsonrpc member must be a String
        return 'jsonrpc member must be a String' ;
      }
    }
//    else {
//      // missing jsonrpc member
//      return false ;
//    }

    if (m.containsKey('method')) { // required - String
      if (! (m['method'] is String)) {
        // method must be String
        return "member 'method' must be a String" ;
      }
    }
    else {
      // missing method member
      return "member 'method' is missing" ;
    }

    if (m.containsKey('id')) { // optional - String
      if (! (m['id'] is String)) {
        // id must be String
        return "member 'id' must be String" ;
      }
    }

    // optional - per JSON-RPC 2.0 spec - should be JSON (Array or Object)
    if (m.containsKey('params')) {

    }

    return '' ; // no errors
  }

  // Cant use { } initialization literal as it will result in Map<String, String>
  Map<String, dynamic> toJsonMap() {
    Map<String, dynamic> map = {
      'jsonrpc': jsonrpc,
      'method': method,
    };

    if (_params != null) {
      map['params'] = _params ; //_params ;
    }

    if (id != null) {
      map['id'] = id ;
    }

//    print(map) ;

    return map ;
  }

  Object getParams() {
    return _params ;
  }

  setParams(Object params) {
    var isList = params is List ;
    var isMap = params is Map ;
    var ok = isList || isMap ;
    if (!ok) {
      throw Exception("member 'params' must be List or Map per JSON RPC 2.0") ;
    }
    print(params) ;
    _params = params ;
    print("done with params") ;
  }

  String toJson() {
    return jsonEncode(toJsonMap()) ;
  }

  @override String toString() {
    return toJson() ;
  }

  //
  // Private
  //
  _fromJsonMap(Map<String, dynamic> mj) {
    if (mj.containsKey('jsonrpc')) { // should be required but we default to 2.0 if not present
      jsonrpc = mj['jsonrpc'] ;
    }
    else {
      jsonrpc = '2.0' ;
    }

    method = mj['method'] ;

    if (mj.containsKey('params')) {
      _params = mj['params'] ;
    }

    if (mj.containsKey('id')) {
      id = mj['id'] ;
    }
  }
}

/// When a rpc call is made, the Server MUST reply with a Response, except for in the
/// case of Notifications. The Response is expressed as a single JSON Object
class IZJsonRpcResp {
  /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
  String jsonrpc = '2.0' ;


  /// This member is REQUIRED.
  // It MUST be the same as the value of the id member in the Request Object.
  // If there was an error in detecting the id in the Request object (e.g. Parse error/Invalid Request),
  // it MUST be Null.
  String id ;

  /// This member is REQUIRED on success.
  // This member MUST NOT exist if there was an error invoking the method.
  // The value of this member is determined by the method invoked on the Server.
  Object result ;

  /// This member is REQUIRED on error.
  // This member MUST NOT exist if there was no error triggered during invocation.
  // The value for this member MUST be an Object as defined in section 5.1.
  IZJsonRpcErr error ;

  //
  // Constructors
  //
  IZJsonRpcResp.ok(String id, Object result) {
    this.id = id ;
    this.result = result ;
  }

  IZJsonRpcResp.err(String id, IZJsonRpcErr error) {
    this.id = id ;
    this.error = error ;
  }

  IZJsonRpcResp.fromJsonStr(String json) {
    Map<String, dynamic> mj = jsonDecode(json);
    _fromJsonMap(mj) ;
  }

  IZJsonRpcResp.fromJsonMap(Map<String, dynamic> mj) {
    _fromJsonMap(mj) ;
  }

  //
  // API
  //
  static String isValidJson(String json) {
    if (! BRMJsonUtil.isValidJson(json)) {
      return 'Ill-formed JSON' ;
    }

    Map<String, dynamic> m = jsonDecode(json);

    if (m.containsKey('jsonrpc')) { // required - String value 2.0
      if (! (m['jsonrpc'] is String)) {
        // jsonrpc member must be a String
        return "member 'jsonrpc' must be a JSON-String" ;
      }
    }
//    else {
//      // missing jsonrpc member
//      return false ;
//    }

    if (m.containsKey('id')) { // optional - String
      if (! (m['id'] is String)) {
        // id must be String
        return "member 'id' must be a JSON-String" ;
      }
    }

    // Must contain result or error but not both
    if (! m.containsKey('result') && ! m.containsKey('error')) {
      return "Response JSON must contain either 'result' or 'error' members, both are missing" ;
    }

    if (m.containsKey('result') && m.containsKey('error')) {
      return "Response JSON must contain either 'result' or 'error' members, both are specified" ;
    }

    if (m.containsKey('result')) {

    }

    if (m.containsKey('error')) {
      // MrP: check if valid error structure
      if (! (m['error'] is Map))  {
        return "member 'error'  is not JSON-Object type" ;
      }

      String errorJson = (m['error']).toString() ;
      print('errorJson: ' + errorJson) ;

      String errorCheck = IZJsonRpcErr.isValidJson(errorJson) ;
      if (errorCheck != '') {
        return errorCheck ;
      }
    }

    return "" ;  // no errors
  }

  bool isSuccess() => result != null ;
  bool isError() => error != null ;

  //
  // Serialization
  //
  _fromJsonMap(Map<String, dynamic> mj) {
    if (mj.containsKey('jsonrpc')) { // should be required but we default to 2.0 if not present
      jsonrpc = mj['jsonrpc'] ;
    }
    else {
      jsonrpc = '2.0' ;
    }

    id = mj['id'] ;

    if (mj.containsKey('result')) {
      result = mj['result'] ;
    }

    if (mj.containsKey('error')) {
      error = IZJsonRpcErr.fromJsonMap(mj['error']) ;
    }
  }

  // Cant use { } initialization literal as it will result in Map<String, String>
  Map<String, dynamic> toJsonMap() {
    Map<String, dynamic> map = {
      'jsonrpc': jsonrpc,
      'id': id,
    };

    if (result != null) {
      map['result'] = result ;
    }

    if (error != null) {
      map['error'] = error.toJsonMap() ;
    }

//     print(map) ;

    return map ;
  }

  String toJson() {
    return jsonEncode(toJsonMap()) ;
  }

  @override String toString() {
    return toJson() ;
  }
}

/// When a rpc call encounters an error, the Response Object MUST contain the error
/// member with a value that is a Object with the following members
/// The error codes from and including -32768 to -32000 are reserved for pre-defined errors.
/// Any code within this range, but not defined explicitly below is reserved for future use.
/// The error codes are nearly the same as those suggested for XML-RPC at the following
/// url: http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php
///
/// code	message	meaning
/// -32700	Parse error	Invalid JSON was received by the server.
/// An error occurred on the server while parsing the JSON text.
/// -32600	Invalid Request	The JSON sent is not a valid Request object.
/// -32601	Method not found	The method does not exist / is not available.
/// -32602	Invalid params	Invalid method parameter(s).
/// -32603	Internal error	Internal JSON-RPC error.
/// -32000 to -32099	Server error	Reserved for implementation-defined server-errors.
/// The remainder of the space is available for application defined errors.
class IZJsonRpcErr {
  //See https://www.jsonrpc.org/specification for values/explanations:
  static const int JSON_RPC_ERROR_PARSE =-32700 ;
  static const String JSON_RPC_ERROR_PARSE_MSG = "Parse error" ;

  static const int JSON_RPC_ERROR_INVALID_REQUEST = -32600 ;
  static const String JSON_RPC_ERROR_INVALID_REQUEST_MSG = "Invalid Request" ;

  static const int JSON_RPC_ERROR_METHOD_NOT_FOUND = -32601 ;
  static const String JSON_RPC_ERROR_METHOD_NOT_FOUND_MSG = "Method not found" ;

  static const int JSON_RPC_ERROR_INVALID_PARAMS = -32602 ;
  static const String JSON_RPC_ERROR_INVALID_PARAMS_MSG = "Invalid params" ;

  static const int JSON_RPC_ERROR_INTERNAL_ERROR = -32603 ;
  static const String JSON_RPC_ERROR_INTERNAL_ERROR_MSG = "Internal error" ;

  /// A Number that indicates the error type that occurred.
  // This MUST be an integer.
  int code ;

  /// A String providing a short description of the error.
  // The message SHOULD be limited to a concise single sentence.
  String message ;

  /// A Primitive or Structured value that contains additional information about the error.
  // This may be omitted.
  // The value of this member is defined by the Server (e.g. detailed error information, nested errors etc.).
  String data ;

  //
  // Constructor(s)
  //
  IZJsonRpcErr(int code, String message, [String data]) {
    this.code = code ;
    this.message = message ;
    if (data != null) {
      this.data = data ;
    }
  }

  IZJsonRpcErr.fromJsonStr(String json) {
    Map<String, dynamic> mj = jsonDecode(json);
    _fromJsonMap(mj) ;
  }

  IZJsonRpcErr.fromJsonMap(Map<String, dynamic> mj) {
    _fromJsonMap(mj) ;
  }

  //
  // API
  //
  static String isValidJson(String json) {
    if (! BRMJsonUtil.isValidJson(json)) {
      return 'Ill-formed JSON' ;
    }

    Map<String, dynamic> m = jsonDecode(json);

    if (m.containsKey('code')) { // required - String value 2.0
      if (!m['code'] is String) {
        // jsonrpc member must be a String
        return "member 'code' must be a JSON-String" ;
      }
    }
    else {
      return "member 'code' is missing" ;
    }

    if (m.containsKey('id')) { // optional - String
      if (!m['id'] is String) {
        // id must be String
        return "member 'id' must be a JSON-String" ;
      }
    }
    else {
      return "member 'id' is missing" ;
    }

    if (m.containsKey('data')) {

    }

    return "" ;  // no errors
  }

  Map<String, dynamic> toJsonMap() {
    var map = {
      'code': code,
      'message': message,
    };
    if (message != null) {
      map['message'] = message ;
    }
    if (data != null) {
      map['data'] = data ;
    }
    return map ;
  }

  String toJson() {
    return jsonEncode(toJsonMap()) ;
  }

  @override String toString() {
    return toJson() ;
  }

  //
  // Private
  //
  _fromJsonMap(Map<String, dynamic> mj) {
    code = mj['code'] ;
    if (mj.containsKey('message')) {
      message = mj['message'];
    }
    if (mj.containsKey('data')) {
      data = mj['data'] ;
    }
  }
}

/// We need the BluetoothDevice, Data-characteristic and Notify-charactertic
/// We can view the characteristic pairing as a "Channel".
/// The general nature is async such that we naturally decouple the request
/// from the response (if any).
///
/// We can think of a Q for the requests and Q for the response (for req with an id)
/// In the first incarnation, we can simply do the direct characteristic-data
/// write and wait for BLE response.  This guarantee we get the request onto the
/// server-side.  The server-side will process the request and respond by poking
/// the notify-characteristic.  We listen to the notify and then we will read
/// from the characteristic-data.  Note that we need to synchronize access to the
/// characteristic-data as we use it for both read and write.  Remember we can't
/// blindly just read the data-charac since it's value is the same no matter how
/// many times we read it.
/// How do we sync between writes and reads? Maybe we should use different
/// charactersitics for each.  We always write to A and we always read from B.
/// We only read from B when we get a notify on C.  This seems much less error
/// prone since we can continually keep writing on A and not worry about stepping
/// on a response from the server.  I was thinking that maybe we should do an
/// Indicate vs. a Notify on C.  With Indicate we need to ack vs Notify which
/// could get lost.
///
///
//class JsonBleRpc {
//  BluetoothDevice _device ;
//
//  BluetoothCharacteristic _characA ; // R/W - client(W), server(R)
//  BluetoothCharacteristic _characB ; // R/W - client(R), server(W)
//  BluetoothCharacteristic _characC ; // R/I - client(R), server(I)
//
//  JsonBleRpc(BluetoothDevice device) {
//    _device = device ;
//
//    // Obtain/cache these right up front so we don't need to constantly do lookups
//    BLEComm.getRPCDataCharacteristic(_device, (bc)=> _characA = bc) ;
//    BLEComm.getRPCNotifyCharacteristic(_device, (bc)=> _characC = bc) ;
//
////    _device.setNotifyValue(characteristic, notify) ;
////    _rpcDataCharacteristic.isNotifying ;
//
//    // Does this trigger if "same" value is written, aka - updated vs "chanaged"?
//    // We could write an alternating sequence or such so that from
//    _device.onValueChanged(_characC).listen((event) {
//      debugPrint(event.toString()) ;
//      // T
//    });
//  }
//
//  //
//  // RPC
//  //
//  BluetoothCharacteristic getRPCDataCharacteristic() {
//    return _characA ;
//  }
//
//  BluetoothCharacteristic getRPCNotifyCharacteristic() {
//    return _characC ;
//  }
//
//  bool send_no_reply(JsonBleRpcReq req) {
//    String jsonReq = req.toJson();
//    List<int> list_ints = jsonReq.codeUnits;
//    // Currently this waits till we get a response that the characteristic was written.
//    // Note this is BLE protocol level and has nothing to do with what the server-side
//    // is doing with the request.
//    var sent = _device.writeCharacteristic(_characA, list_ints,
//        type: CharacteristicWriteType.withResponse);
//    debugPrint(
//        "sendRPC data response: " + ((sent == null) ? "null" : sent.toString()));
//    return sent != null ;
//  }
//
//  Future<JsonBleRpcResp> send(JsonBleRpcReq req, {int timeout=10}) async {
//    bool sent = send_no_reply(req) ;
//
////    // We are basically just reading the NotifyCharacteristic.  I think that the
////    // notify should just return the request-id, which means the request-id has
////    // completed on the server side and asking for it's results is possible.
////    // Note that in such a setup, it means the server is somehow caching responses
////    // keyed by request-id.  This can be a resource issue as to how long do we keep
////    // responses around.  This means we need some sort of ageing mechanism to drop
////    // responses from the server-side cache...
////    _device.onValueChanged(_rpcNotifyCharacteristic).listen((event) {
////      debugPrint(event.toString()) ;
////    });
////
////    _device.readCharacteristic(_rpcNotifyCharacteristic).then((v) {
////      String data = String.fromCharCodes(_rpcNotifyCharacteristic.value);
//////      callback(data) ;
////    });
//  }
//
////  Future<JsonBleRpcResp>send(JsonBleRpcReq req, int timeoutMillis) async {
////    String jsonReq = req.toJson() ;
////    print(jsonReq) ;
////  }
////
////  bool notify(JsonBleRpcReq req) {
////    String jsonReq = req.toJson() ;
////    print(jsonReq) ;
////  }
//}