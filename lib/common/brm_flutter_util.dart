import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
export 'dart:ui' show AppLifecycleState, VoidCallback;
import 'dart:collection';

//
// 3rd Party
//
import 'package:toast/toast.dart';      // 3rd party - Android'ish toast messages

/// Note that this calls typedChoiceDialog(..) with a horizontal layout for the choices.
/// Note that if you click outside of the dialog, null is returned!!
class BRMFlutterUtil {
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait ;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape ;
  }

  static VoidCallback longPressShow(BuildContext ctx, String msg) {
//    Text longPressShowText ;
//    if (longPressShow is String) {
//      longPressShowText = Text(text) ;
//    }
//    else if (longPressShow is Text) {
//      longPressShowText = text ;
//    }
//    else {
//      print('longPressShow must be either String or Text') ;
//      longPressShowText = Text('longPressShow must be either String or Text') ;
//    }

    return (()  {
      BRMFlutterUtil.brmShowAlertDialog(ctx, 'Info', msg) ;
    }) ;
  }

  static Widget buildCircle(double size, Color color) {
    Widget bigCircle = new Container(
      width: size,
      height: size,
      decoration: new BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

    return bigCircle;
  }

  /// iconPlacement 12 (top), 3 (right), 6 (bottom), 9 (left) -- like clock hands
  static FlatButton flatButton(dynamic label, VoidCallback callback,
      {VoidCallback longPress, dynamic icon, int iconPlacement = 12, Color color = Colors.orangeAccent})
  {
    if (label is Text) {
      // Use as is
    }
    else {
      label = Text(label.toString());
    }

    if (icon != null) {
      if (icon is Icon) {
        // Use as is
      }
      else if (icon is IconData) {
        icon = Icon(icon);
      }
      else {
        print('Unexpected icon value, expected Icon or IconData');
        icon = Icon(Icons.sentiment_very_dissatisfied);
      }
    }

    Widget orientedLabelAndIcon;
    if (icon == null) {
      orientedLabelAndIcon = label;
    }
    else {
      // We have 12, 3, 6, and 9 placemement of the icon -- think 9oclock, 3oclock
      switch (iconPlacement) {
        case 12:
          orientedLabelAndIcon = Column(children: <Widget>[icon, label]);
          break;
        case 6:
          orientedLabelAndIcon = Column(children: <Widget>[label, icon]);
          break;
        case 3:
          orientedLabelAndIcon = Row(children: <Widget>[label, Text(' '), icon]);
          break;
        case 9:
        // yes fall through to default
        default:
          orientedLabelAndIcon = Row(children: <Widget>[icon, Text(' '), label]);
          break;
      }
    }

//    List<Widget> widgets = (icon == null) ? [label] : [icon, label] ;
    return FlatButton(
      color: color,
      padding: EdgeInsets.all(5.0),
      onPressed: callback,
      onLongPress: longPress,
      child: orientedLabelAndIcon,
      shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
    );
  }

  static void _popContext(BuildContext context) {
    Navigator.pop(context);
  }

  static void showCustomDialog(BuildContext context,
      {@required Text title,
        Text okBtnText = const Text("Ok"),
        Text cancelBtnText = const Text("Cancel"),
        @required Widget content,
        @required Function okBtnFunction,
        Function cancelBtnFunction}) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: title,
            content: content,
            actions: <Widget>[
              FlatButton(
                child: okBtnText,
// MrP: We leave the dismissal of the dialog to the function itself as it may do validation or other tweaking
//                onPressed: () {
//                  okBtnFunction() ;
//                  Navigator.pop(context);
//                },
                onPressed: okBtnFunction,
              ),
              FlatButton(
                  child: cancelBtnText,
                  onPressed: (cancelBtnFunction == null)
                      ? () => Navigator.pop(context)
                      : cancelBtnFunction),
            ],
          );
        });
  }

  static Future<T> typedBinaryChoiceDialog<T>(BuildContext context,
      String title,
      Text choiceA,
      T choiceAChosen,
      Text choiceB,
      T choiceBChosen) async {
    Map<Text, T> map = new LinkedHashMap<Text, T>();
    map[choiceA] = choiceAChosen;
    map[choiceB] = choiceBChosen;
    Future<T> r = typedChoiceDialog(context, title, true, map);
    return r;
  }

  /// if not horizontalLayout, the choices are in a vertical layout
  /// Note that if you click outside of the dialog, null is returned!!
  /// Use LinkedHashMap if you want order of options preserved.
  static Future<T> typedChoiceDialog<T>(BuildContext context, String title,
      bool horizontalLayout, Map<Text, T> choices) async {
    List<Widget> kids = new List<Widget>();

    choices.forEach((key, value) {
      kids.add(SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, value);
        },
        child: key,
      ));
    });

    Widget optionContainer =
    horizontalLayout ? new Row(children: kids) : new Column(children: kids);

    T r = await showDialog<T>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(title),
            children: [optionContainer],
          );
        });
    return r;
  }

  static Widget dropDownArrowFromList(BuildContext context, String title, List<String> choices,
      Function(String) callback) {
    Map<Text, String> textChoices = {};
    choices.forEach((v) => textChoices[Text(v)] = v);
    return dropDownArrowFromMap(context, title, textChoices, callback);
  }

  static Widget dropDownArrowFromMap<T>(BuildContext context, String title, Map<Text, T> choices,
      Function(T) callback) {
//    Map<Text, T> dropdownChoices = { } ;
//    rawChoices.forEach((k, v)=> dropdownChoices[k] = v) ;

    Widget arrowDropDown = BRMFlutterUtil.flatButton('', () {
      BRMFlutterUtil.typedChoiceDialog(context, title, false, choices).then((pick) {
        if (callback != null) {
          callback(pick);
        }
      });
    }, iconPlacement: 9, icon: Icons.arrow_downward);
    Container cont = Container(
        child: arrowDropDown,
        constraints: BoxConstraints(maxWidth: 40)
    );
    return cont;
  }

  /// Modal ack dialog.  This is NOT a choice dialog, it only presents "Ok" button.
  static Future<void> brmAcknowledgeDialog(BuildContext context, String title, String msg) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(title)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(msg),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// This is just a 'close' option dialog.  There is NO action aspect, it pure notify and note that
  /// this call will return BEFORE the dialog shows up; it is not modal-blocking.
  static void brmShowAlertDialog(BuildContext callerBuildCtx, String title, String msg,
      [Duration autoClose]) {
    if (autoClose == null) {
      autoClose = Duration(days: 100);
    }

    AlertDialog alert = AlertDialog(
      title: Center(child: new Text(title)),
      content: new Text(msg),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))),
      actions: <Widget>[
        // usually buttons at the bottom of the dialog
        new FlatButton(
          child: new Text("Close"),
          onPressed: () {
            Navigator.of(callerBuildCtx).pop();
          },
        ),
      ],
    );

    showDialog(
        context: callerBuildCtx,
        builder: (context) {
          Future.delayed(autoClose, () {
            Navigator.of(context).pop(true);
          });
          return alert;
        });
  }

  static LinearProgressIndicator buildProgressBarTile() {
    return new LinearProgressIndicator();
  }

  static List<DropdownMenuItem<String>> dropdownMenuItems(Iterable<String> keys) {
    return keys.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  static DropdownButton createDropdownButton(String initial_value, Iterable<String> keys,
      ValueChanged<String> onChanged) {
    return DropdownButton<String>(
      value: initial_value,
      icon: Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      style: TextStyle(
        color: Colors.white, //Colors.deepPurple
      ),
      underline: Container(
        height: 2,
        color: Colors.white38, //Colors.deepPurpleAccent,
      ),
      onChanged: onChanged,
      items: BRMFlutterUtil.dropdownMenuItems(keys),
    );
  }

  /// Note that is call results in the func being called ONLY once.
  /// There is no way to "un" register such a callback.
  /// This is a good substitute for stateless widgets replacement for initState().
  /// ONLY safe way to execute code that can rely on the entire build(..) rendering
  //  being completed.  Note this is big issue with ScopedModel approach as we loose
  //  the natural StatefulWidget lifecycle, and this mechanism is our replacement...
  static void addPostFrameCallback(Function func, [BuildContext context]) {
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        func();
      });
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        func();
      });
    }
  }

  /// If label contains ':' it is used as is, otherwise ': ' is added
  /// If label is null or is empty no label is presented.
  static Widget buildTextField(var label, TextEditingController tec, Function(String) cb,
      {double maxWidth: 300, String decoText: '', TextInputType textInputType, bool readOnly: false,
        int maxLines: 1, TextStyle fieldStyle})
  {
    Text labelText ;
    if (label == null || label is String) {
      if (label == null || label.isEmpty) {
        label = '';
      }
      else {
        label = (label.contains(':')) ? label : (label + ': ');
      }
      labelText = Text(label) ;
    }
    else {
      labelText = label ;
    }


    Row row = Row(children: <Widget>[
      labelText, //Text(label, style: null), //TextStyle(color: Colors.blue)),
      Container(
          constraints: (maxWidth == null) ? null : BoxConstraints(maxWidth: maxWidth),
          child: TextField(
            controller: tec,
            onChanged: (v) => cb(v),
            decoration: InputDecoration(hintText: decoText),
            keyboardType: textInputType,
            readOnly: readOnly,
            maxLines: maxLines,
            style: fieldStyle,
          )
      ),
    ]);
    return row;
  }

  /**
      property	        description
      ---------------   ----------------------------------
      msg	              String (Not Null)(required)
      context	          BuildContext (Not Null)(required)
      duration	        Toast.LENGTH_SHORT or Toast.LENGTH_LONG (optional)
      gravity	          Toast.TOP (or) Toast.CENTER (or) Toast.BOTTOM
      textColor	        Color (default white)
      backgroundColor	  Color (default Color(0xAA000000))
      backgroundRadius	double （default 16)
      border	          Border (optional)
   */
  static void toast(BuildContext ctx, String msg, [int time = 2]) {
    Toast.show(msg, ctx, duration: time, gravity: Toast.BOTTOM);
  }
}

class BlinkWidget extends StatefulWidget {
  final List<Widget> children;
  final int interval;

  BlinkWidget({@required this.children, this.interval = 500, Key key}) : super(key: key);

  @override
  _BlinkWidgetState createState() => _BlinkWidgetState();
}

class _BlinkWidgetState extends State<BlinkWidget> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  int _currentWidget = 0;

  initState() {
    super.initState();

    _controller = new AnimationController(
        duration: Duration(milliseconds: widget.interval),
        vsync: this
    );

    _controller.addStatusListener((status) {
      if(status == AnimationStatus.completed) {
        setState(() {
          if(++_currentWidget == widget.children.length) {
            _currentWidget = 0;
          }
        });

        _controller.forward(from: 0.0);
      }
    });

    _controller.forward();
  }

  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.children[_currentWidget],
    );
  }
}

//  static Future<T> typedBinaryChoiceDialogOrig<T>(
//      BuildContext context,
//      String title,
//      Text choiceA,
//      T choiceAChosen,
//      Text choiceB,
//      T choiceBChosen) async {
//    return await showDialog<T>(
//        context: context,
//        builder: (BuildContext context) {
//          return SimpleDialog(
//            title: Text(title),
//            children: <Widget>[
//              Row(
//                children: <Widget>[
//                  SimpleDialogOption(
//                    onPressed: () {
//                      Navigator.pop(context, choiceAChosen);
//                    },
//                    child: choiceA,
//                  ),
//                  Spacer(flex: 1),
//                  SimpleDialogOption(
//                    onPressed: () {
//                      Navigator.pop(context, choiceBChosen);
//                    },
//                    child: choiceB,
//                  ),
//                ],
//              )
//            ],
//          );
//        });
//  }


//  /// iconPlacement 12 (top), 3 (right), 6 (bottom), 9 (left) -- like clock hands
//  static FlatButton flatButton(
//      dynamic label, VoidCallback callback,
//      {Icon icon, int iconPlacement=12, Color color=Colors.orangeAccent})
//  {
//    if (label is Text) {
//      // Use as is
//    }
//    else {
//      label = Text(label.toString()) ;
//    }
//
//    List<Widget> widgets = (icon == null) ? [label] : [icon, label] ;
//    return FlatButton(
//        color: color,
//        padding: EdgeInsets.all(5.0),
//        onPressed: callback,
//        child: Column(children: widgets),
//        shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
//    );
//  }

//  static FlatButton flatButton(Icon icon, dynamic label, VoidCallback callback) {
//    return _customFlatButton(icon, label, callback) ;
//  }
