import 'dart:convert' as dartConvert;

class BRMJsonUtil {
  /// MrP: Using named-optional param to start with as I think we will expose a couple
  /// of more parameters later on...
  static String prettyPrintJson(String rawJson, {String indent = '    '}) {
    Map<String, dynamic> jsonMap = jsonDecode(rawJson) ;
    dartConvert.JsonEncoder encoder = dartConvert.JsonEncoder.withIndent(indent) ;
    String prettyJson = encoder.convert(jsonMap) ;
    return prettyJson ;
  }

  static String minimize(String json) {
    Map<String, dynamic> jsonMap = dartConvert.jsonDecode(json) ;
    String j = dartConvert.jsonEncode(jsonMap) ;
    return j ;
  }

  static bool isValidJson(String rawJson) {
    dartConvert.JsonDecoder jdc = dartConvert.JsonDecoder() ;
    try {
      jdc.convert(rawJson);
      return true ;
    }
    on FormatException catch(e) { // FormatException as specific ex
      return false ;
    }
  }

  // Maybe add some extra handling/transformation, error handling etc... later for these two
  static String jsonEncode(Map<String, dynamic> map) {
    return dartConvert.jsonEncode(map) ;
  }

  static dynamic jsonDecode(String json) {
    return dartConvert.jsonDecode(json) ;
  }

}