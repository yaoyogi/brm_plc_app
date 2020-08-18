import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

import 'dart:collection' ;

class SeriesDiscreteData {
  double value;
  double time;
  String discriminator ;

  SeriesDiscreteData(this.value, this.time, this.discriminator);
}

class ChartAxisDef {
  double tickStart ;
  double tickEnd ;
  double tickIncrement ;
  //  String label ;
  int fontSize = 12 ;
  charts.Color color = charts.MaterialPalette.white ;

  ChartAxisDef(
      double tickStart, double tickEnd, double tickIncrement,
      {charts.Color color = charts.MaterialPalette.white , int fontSize = 12})
  {
    this.tickStart = tickStart ;
    this.tickEnd = tickEnd ;
    this.tickIncrement = tickIncrement ;

    this.color = color ;
    this.fontSize = fontSize ;
  }

  charts.NumericAxisSpec asAxisSpec() { // {bool reversed=false}) {
    charts.LineStyleSpec lineStyle = charts.LineStyleSpec(
        color: color,
    ) ;

    charts.TextStyleSpec labelStyle = charts.TextStyleSpec(
        fontSize: fontSize, // size in Pts.
        color: color,
    );

    charts.GridlineRendererSpec<num> renderSpec = charts.GridlineRendererSpec(
        labelStyle: labelStyle,
        lineStyle: lineStyle
    ) ;

    var ticks = List<charts.TickSpec<num>>() ;
    if (tickIncrement < 0) {
      for(double v = tickStart; v >= tickEnd; v += tickIncrement) {
        ticks.add(charts.TickSpec<num>(v)) ;
      }
      print('ticks in reverse') ;
    }
    else {
      for(double v = tickStart; v <= tickEnd; v += tickIncrement) {
        ticks.add(charts.TickSpec<num>(v)) ;
      }
      print('ticks forward') ;
    }

//    if (reversed) {
//      ticks = List.from(ticks.reversed);
//    }

    var tickProviderSpec = charts.StaticNumericTickProviderSpec(ticks) ;
//    var tickProviderSpecX = charts.BasicNumericTickProviderSpec(dataIsInWholeNumbers: true, desiredMinTickCount:10, desiredMaxTickCount:20, zeroBound: false) ;

    return charts.NumericAxisSpec(
        renderSpec: renderSpec,
        tickProviderSpec: tickProviderSpec,
        showAxisLine: true,
    ) ;
  }
}

class SeriesDef {
  String id ;

  // MrP: !! ** Note: do NOT directly and data via this list, use addEntry(..)
  List<SeriesDiscreteData> data ;
  charts.Color color = charts.MaterialPalette.blue.shadeDefault ;
  int maxDisplayCountBeforeShifting = 100;

  SeriesDef(this.id, this.data, this.color) ;

  // For the chart to always show the last hour of data, each new entry MUST go into the
  // first data slot. Is this true?  The data value determines the Y-axis and the time determines
  // the X-axis.  So 0.0 seconds is always the first and latest value.  How do we make this work?
  // Well, ideally we had a stack and we just keep pushing and then at some max-stack-size we
  // would remove the last entry and be in that mode for the rest of the session (add to front and
  // remove from the rear).  Unfortuantely the chart API only take a List (sigh...).  So how to
  // make this work?  It seems like continous shifting is what we would need to do, yikes!...
  // I can't figure out how to get the graph to have a 60..0 X-axis!!  I don't know why that is
  // the case!!.

  addEntry(double newValue, double time) { //}, String discriminator) {
    data.insert(0, SeriesDiscreteData(newValue, time, id)) ;
    if (data.length > 2) {
      // for now we just add the delta from the last measurement which for now we harwire as 10 seconds
      for(int i = 1; i < data.length; i++) {
        // Remember that we have our X-axis in MINUTES.  SO if we are getting roughly 4-updates a second
        // from the PLC we need to make our increment accordingly.
        data[i].time += 0.25 ; // seconds ;
      }
    }

    // How do we keep ONLY 60 minutes worth?
    // Well we need to drop any entries that have a value > 3600 seconds.  Again, this is horribly
    // inefficient...
    for(int i = data.length - 1; i > 0; i--) {
      if (data[i].time > 60) {
        data.removeAt(i) ;
      }
      else {
        break ;
      }
    }

    if (data.length > 1000) {
      data.removeLast() ;
    }
//    if (data.length == maxDisplayCountBeforeShifting) {
//      // Shift everyones x-axis value back 1.  Note we don't care about [0] as it will be removed
//      // from the data set.
//      double timeLast = data[maxDisplayCountBeforeShifting - 1].time ;
//
//      for (int i = (maxDisplayCountBeforeShifting - 1); i > 0; i--) {
//        data[i].time -= timeLast;
//      }
//
//      data.removeAt(maxDisplayCountBeforeShifting - 1);
//    } else {
//      data[_nextIndex] = SeriesDiscreteData(newValue, time, id) ;
//    }
//
//    // MrP: Note that to get the graph to redraw you have to recreate the _seriesList!
//
//    data.add(SeriesDiscreteData(newValue, time, id)); //_chartPos * 1.0, id));
  }

  addEntryOrig(double newValue, double time) { //}, String discriminator) {
    if (data.length == maxDisplayCountBeforeShifting) {
      // Shift everyones x-axis value back 1.  Note we don't care about [0] as it will be removed
      // from the data set.
      double time0 = data[0].time ;

      for (int i = 0; i < (maxDisplayCountBeforeShifting - 1); i++) {
        data[i].time -= time0;
      }

      data.removeAt(0);
    } else {
//      _chartPos++;
    }

    // MrP: Note that to get the graph to redraw you have to recreate the _seriesList!

    data.add(SeriesDiscreteData(newValue, time, id)); //_chartPos * 1.0, id));
  }

  charts.Series asChartSeries() {
    return charts.Series<SeriesDiscreteData, double>(
      id: id,
      colorFn: (_, __) => color,
      domainFn: (SeriesDiscreteData at, _) => at.time,
      measureFn: (SeriesDiscreteData at, _) => at.value,
      data: data,
    ) ;
  }
}

class LineChartDef {
//  String title = 'My Chart' ;
  List<SeriesDef> seriesDefs = List<SeriesDef>() ;
  ChartAxisDef domainAxis ;
  ChartAxisDef primaryAxis ;

  LineChartDef(this.seriesDefs, this.domainAxis, this.primaryAxis) ;

  List<charts.Series<SeriesDiscreteData, double>> createChartSeries() {
    var r = List<charts.Series<SeriesDiscreteData, double>>() ;
    seriesDefs.forEach((SeriesDef def) {
      r.add(def.asChartSeries()) ;
    }) ;
    return r ;
  }

  charts.SeriesLegend legend = charts.SeriesLegend(
    // Positions for "start" and "end" will be left and right respectively
    // for widgets with a build context that has directionality ltr.
    // For rtl, "start" and "end" will be right and left respectively.
    // Since this example has directionality of ltr, the legend is
    // positioned on the right side of the chart.
    position: charts.BehaviorPosition.end,
    // For a legend that is positioned on the left or right of the chart,
    // setting the justification for [endDrawArea] is aligned to the
    // bottom of the chart draw area.
    outsideJustification: charts.OutsideJustification.endDrawArea,
    // By default, if the position of the chart is on the left or right of
    // the chart, [horizontalFirst] is set to false. This means that the
    // legend entries will grow as new rows first instead of a new column.
    horizontalFirst: false,
    // For ex: setting this value to 2, the legend entries will grow up to two
    // rows before adding a new column.
    desiredMaxRows: 10,
    // This defines the padding around each legend entry.
    cellPadding: new EdgeInsets.only(right: 4.0, bottom: 4.0),
    // Render the legend entry text with custom styles.
    entryTextStyle: charts.TextStyleSpec(
        color: charts.Color(r: 127, g: 63, b: 191),
        fontFamily: 'Georgia',
        fontSize: 11),
  ) ;

  charts.LineChart asLineChart({List<charts.Series<SeriesDiscreteData, double>> series}) {
    if (series == null) {
      series = createChartSeries() ;
    }
    charts.NumericAxisSpec axisA = domainAxis == null   ? null : domainAxis.asAxisSpec() ; //reversed: true) ;
    charts.NumericAxisSpec axisB = primaryAxis == null ? null : primaryAxis.asAxisSpec() ; //reversed: true) ;
    charts.LineChart c = charts.LineChart(
      series,
      animate: false,  // MrP: _animate MUST be false, else charts just paint first pass and then freeze
      // MrP: The way to specify min/max axis values is to use Ticks
      domainAxis: axisB,
      primaryMeasureAxis: axisA,
      behaviors: [legend],
    );

    return c ;
  }
}

class GeneralLineChartEphemeralState extends State {
  LineChartDef _def ;

  //
  // Construction
  //
  GeneralLineChartEphemeralState(LineChartDef def) {
    _def = def ;
  }

  //
  // Framework Override(s)
  //
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Yes, we need to recreate the _seriesList EVERY build(..).  Changing the underlying data
    // contents after it is constructed does NOT work...
    charts.LineChart c = _def.asLineChart() ; //series: _series) ;
    return c ;
  }

}

class GeneralLineChartWidget extends StatefulWidget {
  LineChartDef _def ;
  GeneralLineChartWidget(this._def) ;

  @override
  GeneralLineChartEphemeralState createState() {
    GeneralLineChartEphemeralState r = GeneralLineChartEphemeralState(_def);

    return r;
  }
}


//class Iso {
//  static Isolate _isolate; // assigned in startIsolate(), stopped in stopIsolate()
//
//  static void work(SendPort sendPort) {
//    // Isolate worker msut be a static or top-level function
//    print('Start of work: ' + sendPort.toString());
//    int counter = 0;
//    // Seems we can drive 100Hz with 3 data-series is ok.  With animate, it craps out at around 20Hz.
//    Timer.periodic(new Duration(milliseconds: 1000), (Timer t) {
//      counter++;
//      String msg = 'notification ' + counter.toString();
//      sendPort.send(msg);
//    });
//  }
//
//  static void startIsolate(ReceivePort rxPort) async {
//    _isolate = await Isolate.spawn(work, rxPort.sendPort);
//  }
//
//  static void stopIsolate() {
//    if (_isolate == null) {
//      return;
//    }
//    print('Killing isolate');
//    _isolate.kill(priority: Isolate.immediate);
//  }
//}

// MrP: DO NOT init the rxPort here!!!  Do it at declaration point!!!
// Doing here, it is delayed from the construction of the Widget such that if we
// want to access the widgets state BEFORE it has completely rendered.
//    rxPort = ReceivePort() ;

//    rxPort.listen((simulateDataFromOutside) {
////      print(data) ;
//      ValueTime atYaw   = ValueTime(nextNum, _getNextVal());
//      ValueTime atPitch = ValueTime(nextNum, _getNextVal());
//      ValueTime atRoll  = ValueTime(nextNum, _getNextVal());
//
//      setState(() {
//        // We are assuming that _yawData, _pitch_Data and _rollData are updated equally and thus we
//        // can check the length of either of these 3 in the next statement.
//        if (_yawData.length == 20) {
//
//          // Shift everyone back 1
//          for(ValueTime ls in _yawData) { ls.value-- ; }
//          _yawData.removeAt(0);
//
//          for(ValueTime ls in _pitchData) { ls.value-- ; }
//          _pitchData.removeAt(0);
//
//          for(ValueTime ls in _rollData) { ls.value-- ; }
//          _rollData.removeAt(0);
//        }
//        else {
//          nextNum++ ;
//        }
//        // MrP: Note that to get the graph to redraw you have to recreate the _seriesList!
//        _yawData.add(atYaw);
//        _pitchData.add(atPitch) ;
//        _rollData.add(atRoll) ;
//      });
//    });
