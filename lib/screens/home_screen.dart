//
// Flutter
//
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//
// App
//
import 'package:brmplcapp/common/app_util.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

//  Widget _createSamplesExamplesMiscMenu() {
//    return CustomListTile(Icons.zoom_out_map, "Sample, Examples, Misc", () {
//
//      Widget exampleStateMgmtScreen = SimpleDialogOption(
//        child: Row(
//          children: <Widget>[
//            Icon(Icons.account_balance),
//            Text('   '),
//            const Text('Example State Management'),
//          ],
//        ),
//        onPressed: () => Navigator.pushNamed(context, Navi.EX_STATE_MGMT),
//      );
//
//      SimpleDialog dialog = SimpleDialog(
//        title: Center(child: const Text('Ex State Mgmt')),
//        children: <Widget>[
//          Card(child: exampleStateMgmtScreen),
//        ],
//      );
//
//      // show the dialog
//      showDialog(
//        context: context,
//        builder: (BuildContext context) {
//          return dialog;
//        },
//      );
//    });
//  }

  Widget _createLoggingMenu() {
    return CustomListTile(Icons.screen_share, "Logging", () {
      // set up the list options
      Widget optionConsoleViewer = SimpleDialogOption(
        child: Row(
          children: <Widget>[Icon(Icons.call_to_action), Text('   '), const Text('Console Viewer')],
        ),
        onPressed: () => Navigator.pushNamed(context, Navi.LOGGER_CONSOLE_VIEWER),
      );
      Widget optionUDPMgr = SimpleDialogOption(
        child: Row(
          children: <Widget>[
            Icon(Icons.account_balance),
            Text('   '),
            const Text('UDP Manager'),
          ],
        ),
        onPressed: () => Navigator.pushNamed(context, Navi.LOGGER_UDP_MGR),
      );
      Widget optionSendMessage = SimpleDialogOption(
        child: Row(
          children: <Widget>[
            Icon(Icons.message),
            Text('   '),
            const Text('Send Message'),
          ],
        ),
        onPressed: () => Navigator.pushNamed(context, Navi.LOGGER_SEND_MSG),
      );
//      Widget optionESP32SideFileLogger = SimpleDialogOption(
//        child: Row(
//          children: <Widget>[
//            Icon(Icons.movie_filter),
//            Text('   '),
//            const Text('ESP32-side File Logger'),
//          ],
//        ),
//        onPressed: () => Navigator.pushNamed(context, Navi.LOGGER_ESP32_SIDE_FILE_LOGGER),
//      );
      Widget optionLocalFileLogger = SimpleDialogOption(
        child: Row(
          children: <Widget>[
            Icon(Icons.filter),
            Text('   '),
            const Text('Local File Logger'),
          ],
        ),
        onPressed: () => Navigator.pushNamed(context, Navi.LOGGER_LOCAL_FILE_LOGGER),
      );
      Widget optionLoggerLevels = SimpleDialogOption(
        child: Row(
          children: <Widget>[
            Icon(Icons.assistant_photo),
            Text('   '),
            const Text('Logger Levels'),
          ],
        ),
        onPressed: () => Navigator.pushNamed(context, Navi.LOGGER_LEVELS),
      );

      SimpleDialog dialog = SimpleDialog(
        title: Center(child: const Text('Logging')),
        children: <Widget>[
          Card(child: optionConsoleViewer),
          Card(child: optionUDPMgr),
          Card(child: optionSendMessage),
//          Card(child: optionESP32SideFileLogger),
//          Card(child: optionLocalFileLogger),
          Card(child: optionLoggerLevels),
//                  Icon(Icons.screen_share)
        ],
      );

      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
    });
  }

  Widget _buildDrawer() {
    return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: <Color>[Colors.lightBlue, Colors.blue])),
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Material(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        color: Colors.white,
                        elevation: 10,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Image.asset("assets/images/splash.jpeg", height: 60, width: 60),
                        ),
                      ),
                      Text(
                        'BarrelRM',
                        style: TextStyle(color: Colors.white, fontSize: 25.0),
                      )
                    ],
                  ),
                )),
            CustomListTile(Icons.settings, "Settings", () {
              Navigator.pushNamed(context, Navi.SETTINGS);
            }),
            CustomListTile(Icons.filter_hdr, "Oveview", () {
              Navigator.pushNamed(context, Navi.OVERVIEW);
            }),
//            CustomListTile(Icons.refresh, "Main Circulation Loop", () {
//              Navigator.pushNamed(context, Navi.CIRCULATION);
//            }),
//            CustomListTile(Icons.repeat, "IBC Transfer", () {
//              Navigator.pushNamed(context, Navi.IBC_TRANSFER);
//            }),
//            CustomListTile(Icons.ac_unit, "Thermo", () {
//              Navigator.pushNamed(context, Navi.THERMO);
//            }),
            CustomListTile(Icons.event, "Events", () {
              Navigator.pushNamed(context, Navi.EVENTS);
            }),
            CustomListTile(Icons.show_chart, "Graphs", () {
              Navigator.pushNamed(context, Navi.GRAPHS);
            }),
            _createLoggingMenu(),
            CustomListTile(Icons.content_paste, "Validator", () {
              Navigator.pushNamed(context, Navi.VALIDATOR);
            }),
            CustomListTile(Icons.border_color, "Mocks", () {
              Navigator.pushNamed(context, Navi.MOCKS);
            }),
            CustomListTile(Icons.help, "HELP", () {
              Navigator.pushNamed(context, Navi.HELP);
            }),

//            CustomListTile(Icons.pages, "Processes", () {
//              Navigator.pushNamed(context, Navi.PROCESSES);
//            }),
//            _createSamplesExamplesMiscMenu(),
          ],
        )) ;
  }

  Widget _buildBody(BuildContext context) {
//    Column col = Column(
//      children: <Widget>[
//        Material(
//          borderRadius: BorderRadius.all(Radius.circular(10.0)),
//          color: Colors.white,
//          elevation: 10,
//          child: Padding(
//            padding: EdgeInsets.all(4.0),
//            child: Image.asset("assets/images/splash.jpeg", height: 90, width: 90),
//          ),
//        ),
//        Text(
//          'Ismintis',
//          style: TextStyle(color: Colors.white, fontSize: 25.0),
//        )
//      ], mainAxisAlignment: MainAxisAlignment.center,
//    ) ;

    InkWell iw = InkWell(
        onTap: () {
          // MrP: This won't work ...
          ScaffoldState scaff = Scaffold.of(context) ;
          scaff.openDrawer() ;
        },
        child: Container(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: BRMAppFlutterUtil.createIconic(),
            )
        )
    );
    return Center(child: Material(child: iw)) ;
  }

  Widget _buildScaffold() {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      drawer: _buildDrawer(),
      body: Builder(
        builder: (BuildContext context) {
          return _buildBody(context) ;
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold() ;
  }
}

class CustomListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Function onTap;

  CustomListTile(this.icon, this.text, this.onTap);
  @override
  Widget build(BuildContext context) {
    //ToDO
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade400))),
        child: InkWell(
            splashColor: Colors.orangeAccent,
            onTap: onTap,
            child: Container(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(icon),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                        ),
                        Text(
                          text,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_right)
                  ],
                ))),
      ),
    );
  }
}
