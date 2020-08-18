import 'package:brmplcapp/common/app_util.dart';

///
///    typedef enum {
///    ESP_LOG_NONE,       /*!< No log output */
///    ESP_LOG_ERROR,      /*!< Critical errors, software module can not recover on its own */
///    ESP_LOG_WARN,       /*!< Error conditions from which recovery measures have been taken */
///    ESP_LOG_INFO,       /*!< Information messages which describe normal flow of events */
///    ESP_LOG_DEBUG,      /*!< Extra information which is not necessary for normal use (values, pointers, sizes, etc). */
///    ESP_LOG_VERBOSE     /*!< Bigger chunks of debugging information, or frequent messages which can potentially flood the output. */
///    } esp_log_level_t;
class LogLevel {
  int level ;
  String name ;
  LogLevel(this.level, this.name) ;

  static List<LogLevel> _levels = <LogLevel>[
//   LogLevel(0, 'none'),
    LogLevel(1, 'error'),
    LogLevel(2, 'warn'),
    LogLevel(3, 'info'),
    LogLevel(4, 'debug'),
    LogLevel(5, 'verbose'),
  ] ;

  static List<LogLevel> getLevels() {
    return _levels ;
  }

  static LogLevel findByLevel(int levelNum) {
    var itr = getLevels().iterator ;
    while(itr.moveNext()) {
      if (itr.current.level == levelNum) {
        return itr.current ;
      }
    };
    return null ;
  }

  static LogLevel findByName(String levelName) {
    var itr = getLevels().iterator ;
    while(itr.moveNext()) {
      if (itr.current.name == levelName) {
        return itr.current ;
      }
    };
    return null ;
  }
}

class IZLoggingUtil {
  static List<String> get knownSystemLogTags => [
    'app_trace', 'app_update', 'aws_iot', 'boot', 'bt', 'clk', 'cpu_start', 'esp_image',
    'esp_tls', 'ethernet', 'heap_init', 'intr_alloc', 'lwip', 'nvs', 'phy', 'phy_init',
    'RTC_MODULE', 'stack_chk', 'system_api', 'tcpip_adapter', 'wifi',
  ] ;

  static List<String> get knownIZLogTags => [
    'iz_app', 'iz_app_console', 'iz_ble', 'iz_ble_provision_app', 'iz_ble_svc', 'iz_blex', 'iz_bluetooth',
    'iz_captive_portal', 'iz_cmd', 'iz_common', 'iz_console', 'iz_console_cmd', 'iz_dns', 'iz_env',
    'iz_frtos', 'iz_gpio', 'iz_graph', 'iz_gtest', 'iz_gtest_console', 'iz_http_client', 'iz_http_svr',
    'iz_i2c', 'iz_imu', 'iz_json', 'iz_json_rpc', 'iz_json_rpcs', 'iz_logging', 'iz_mdns', 'iz_module',
    'iz_net', 'iz_ota', 'iz_pwm', 'iz_sdcard', 'iz_socket', 'iz_time', 'iz_timer', 'iz_web', 'iz_ws_client',
    'iz_wifi', 'iz_wii', 'iz_wseps',
  ] ;

  static Map<String, int> espLogLevelsMap = {
    'ESP_LOG_NONE': 0,
    'ESP_LOG_ERROR': 1,
    'ESP_LOG_WARN': 2,
    'ESP_LOG_INFO': 3,
    'ESP_LOG_DEBUG': 4,
    'ESP_LOG_VERBOSE': 5,
  } ;

  static List<String> get espLogLevels => [
    'ESP_LOG_NONE', 'ESP_LOG_INFO', 'ESP_LOG_WARN', 'ESP_LOG_DEBUG', 'ESP_LOG_ERROR', 'ESP_LOG_VERBOSE',
  ] ;

  // We pass the consoleMsg "as-is" since there can be ANSI color values and for example
  // it starts with \033[xxxM, so we don't want to lose the fact we start with \033 so we
  // can properly strip it out later.  Note \033 is non-printable.

  /**
   * Examples:
   * "\033[0;32mI (13629) websocket_logging_ex: logging: 18[0m"   -- start/ends
   * "I (13629) websocket_logging_ex: logging: 18[0m"			    -- just ends with
   * @param s
   * @return
   */
  static bool hasAnsiColorCodes(String s) {
    return startsWithAnsiColorCode(s) || (endsWithAnsiColorCodeReset(s) != -1) ;
  }

  static bool startsWithAnsiColorCode(String s) {
    if (s[0].codeUnits[0] == 27) {
//    if (s.startsWith("\u001b[")) {
//      if (Character.isDigit(s.charAt(2))) {
      if (AppUtil.isNumeric(s[2])) {
        return true ;
      }
    }
    return false ;
  }

  static int endsWithAnsiColorCodeReset(String s) {
//    return s.lastIndexOf("\033[0m") ;
    return s.lastIndexOf("[0m") ;
  }

  /**
   * ANSI color codes and other sequences are a bit varied so we can rely on
   * some simple rules to extract the log message.  The ANSI escape sequences
   * start with: \033[XXXm  and end with "\033[0m" where XXX is a series of semicolon
   * separated values.
   * <p>
   * We first off if we start with a "\033[", we know we are color coded coming from
   * the ESP32 console log messages.  Since the initial sequence can be quite "busy"
   * we can just look for the first space (" ") and backup 1 to get to the log
   * level.  We then can substring upto the ending "\033[" sequence (if there is one)
   * <p>
   * Example: "\033[0;32mI (13629) websocket_logging_ex: logging: ok\033[0m"
   */
  static String stripAnsiColorCodes(String s) {
    bool startsWith = false ;
    bool endsWith = false ;
    if (startsWithAnsiColorCode(s)) {
      int firstSpace = s.indexOf(" ") ;
      s = s.substring(firstSpace - 1) ; // so we get the log level single character
      startsWith = true ;
    }
    int lastIndex = endsWithAnsiColorCodeReset(s) ;
    if (lastIndex != -1) {
      s = s.substring(0, lastIndex) ;
      endsWith = true ;
    }
//		System.out.println("starts/ends: " + startsWith + "/" + endsWith + " : " + s) ;
    return s ;
  }

//  /**
//   * Answers combined list of {@link #esp32_logging_tags()} plus {@link #iz_logging_tags()}
//   * @return
//   */
//  static List<String> get allLoggingTags {
//    List<String>r = esp32_logging_tags ;
//    r.addAll(iz_logging_tags) ;
//    return r ;
//  }
}