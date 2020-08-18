//
// Flutter
//
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

//
// Dart
//
import 'dart:convert' as convert;

//
// App
//
import 'package:brmplcapp/common/app_util.dart';
import 'package:brmplcapp/common/brm_flutter_util.dart';

import 'package:brmplcapp/brm_json/brm_json_util.dart';

import 'package:brmplcapp/logging/brm_logging.dart';

class LoggingTagEntry {
  String tag ;
  String origin ;

  bool selected = false ;   // UI ONLY

  LoggingTagEntry(this.tag, this.origin) ;

  static List<LoggingTagEntry> getSamples() {
    var list = List<LoggingTagEntry>();
    for(String tag in IZLoggingUtil.knownSystemLogTags) {
      list.add(LoggingTagEntry(tag, 'IDF')) ;
    }
    for(String tag in IZLoggingUtil.knownIZLogTags) {
      list.add(LoggingTagEntry(tag, 'Ismintis')) ;
    }
    return list;
  }
}

class LoggingLevelsDataSource extends DataTableSource {
  int _selectedCount = 0 ;
  List<LoggingTagEntry> entries = LoggingTagEntry.getSamples() ;

  reset() {
    _selectedCount = 0 ;
    entries = LoggingTagEntry.getSamples() ;
  }

  @override
  DataRow getRow(int index) {
    assert(index >= 0);
    if (index >= entries.length) return null;
    final LoggingTagEntry entry = entries[index];
    return DataRow.byIndex(
      index: index,
      selected: entry.selected,
      onSelectChanged: (bool value) {
        // Note this will change the UI selection state as well.
        selectAll(false);

        if (entry.selected != value) {
          _selectedCount += value ? 1 : -1;
          assert(_selectedCount >= 0);
          entry.selected = value;
          notifyListeners();
        }
      },
      cells: <DataCell>[
        DataCell(Text('${entry.tag}')),
        DataCell(Text('${entry.origin}')),
      ],
    );
  }

  @override
  int get rowCount => entries.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;

  void selectAll(bool checked) {
    for (LoggingTagEntry entry in entries) entry.selected = checked;
    _selectedCount = checked ? entries.length : 0;
    notifyListeners();
  }

  addEntry(LoggingTagEntry entry) {
    entries.add(entry);
    notifyListeners();
  }

  void sort<T>(Comparable<T> getField(LoggingTagEntry d), bool ascending) {
    entries.sort((LoggingTagEntry a, LoggingTagEntry b) {
      if (!ascending) {
        final LoggingTagEntry c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }
}

class _LoggingLevelsDataTableState extends State {
  LoggingLevelsDataSource _dataSource = LoggingLevelsDataSource() ;

//  int _rowsPerPage = _dataSource.entries.length;
  bool _sortAscending ;
  int _sortColumnIndex ;

  bool _originSortAsc ;
  bool _tagSortAsc  ;

  String _selectedDropdownValue ;
  String _selectedGlobalDropdownValue  ;

  //
  // Build
  //
  Widget _buildBottomRows() {
    Row r1 = Row(children: <Widget>[
      BRMFlutterUtil.flatButton( 'Add Entry...', _actionAddEntry, iconPlacement: 9, icon: Icons.add),
//      Spacer(flex: 1),
      SizedBox(width: 40),
      BRMFlutterUtil.flatButton( 'Reset List', _actionReset, iconPlacement: 9, icon: Icons.refresh),
    ]) ;

    Row r2 = Row(children: <Widget>[
      BRMFlutterUtil.flatButton( 'Set selected', _actionSetSelectedTagLevel),
//          onPressed: isEntrySelected() ? _actionSetSelectedTagLevel : null),
      Text('   '),
      BRMFlutterUtil.createDropdownButton(
          _selectedDropdownValue, IZLoggingUtil.espLogLevelsMap.keys,
          ((String newValue) {
            setState(() {
              _selectedDropdownValue = newValue;
            });
          })
      ),
      Spacer(flex: 1),
      BRMFlutterUtil.flatButton( 'Set global level', _actionSetGlobalLevel),
      Text('   '),
      BRMFlutterUtil.createDropdownButton(
          _selectedGlobalDropdownValue, IZLoggingUtil.espLogLevelsMap.keys,
          ((String newValue) {
            setState(() {
              _selectedGlobalDropdownValue = newValue;
            });
          })
      ),
      Spacer(flex: 1),
    ]) ;

    return Column(children: <Widget>[r1, r2]) ;
  }

  List<DataColumn> _buildDataColumns() {
    var list = <DataColumn>[
      DataColumn(
        label: const Text('Tag'),
        tooltip: 'Module/Component',
        onSort: (int columnIndex, bool ascending) {
          _sort<String>((LoggingTagEntry d) => d.tag, columnIndex, _tagSortAsc);
          _tagSortAsc = !_tagSortAsc;
        },
      ),
      DataColumn(
        label: const Text('Origin'),
        tooltip: "Non-semantic grouping for display use",
        onSort: (int columnIndex, bool ascending) {
          _sort<String>((LoggingTagEntry d) => d.origin, columnIndex, _originSortAsc);
          _originSortAsc = !_originSortAsc;
        },
      ),
    ] ;

    return list ;
  }

  Widget _buildTable() {
    return Expanded(
      child: SingleChildScrollView(
        child: PaginatedDataTable(
          header: const Text('Entries'),
          rowsPerPage: _dataSource.entries.length, //_rowsPerPage,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: _buildDataColumns(),
          source: _dataSource,
        ),
        scrollDirection: Axis.vertical,
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: <Widget>[
        _buildTable(),
        Container(
          padding: BRMAppFlutterUtil.commonPadding ,
          child: _buildBottomRows(),
        ),
      ],
    );
  }

  //
  // Other State/Behavior
  //
  _sort<T>(Comparable<T> getField(LoggingTagEntry d), int columnIndex, bool ascending) {
    _dataSource.sort<T>(getField, ascending);
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = !ascending;    // yes, !, as we are swapping when this is called
    });
  }

  bool isEntrySelected() {
    return _dataSource.selectedRowCount != 0;
  }

  LoggingTagEntry getSelectedEntry() {
    for (LoggingTagEntry t in _dataSource.entries) {
      if (t.selected) {
        return t;
      }
    }
    return null;
  }

  _setLevel(String tag, String level) {
    String reqUrl = AppUtil.urlMgr.esp32AdminLogLevelSet;

    var body = BRMJsonUtil.jsonEncode({'tag': tag, 'level': level}) ;
    BRMHttpUtil.httpPost(
      reqUrl, body: body,
      showErrDialog: true, context: context,
      success: ((httpResponse) {
        var jsonResponse = convert.jsonDecode(httpResponse.body);
        var result = jsonResponse['result'] ;
        if (result != null) {
          BRMFlutterUtil.toast(context, jsonResponse['result'].toString()) ;
        }
        else {
          BRMFlutterUtil.toast(context, jsonResponse['error'].toString(), 3) ;
        }
      }),
    );
  }

  //
  // Actions
  //
//  List<DropdownMenuItem<String>> _levelItems() {
//    return BRMFlutterUtil.dropdownMenuItems(IZLoggingUtil.espLogLevelsMap.keys) ;
//  }

  _actionReset() {
    setState(() {
      _dataSource.entries = LoggingTagEntry.getSamples() ;
    });
    BRMFlutterUtil.toast(context, 'Table data reset') ;
  }

  // Manually add a tag ,origin as a CSV string
  _actionAddEntry() {
    BRMFlutterUtil.toast(context, 'do add entry...') ;
    TextEditingController _tec = new TextEditingController();
    Widget content = Container(
        child: Row(
          children: <Widget>[
            Text('tag, origin CSV: '),
            Expanded(child: TextField(controller: _tec,)),
          ],
        ));
    BRMFlutterUtil.showCustomDialog(context,
        title: Text('Add Entry to List'),
        content: content,
        okBtnText: Text('Add'), okBtnFunction: () {
          var csv = _tec.text;
          if (csv.isEmpty) {
            BRMFlutterUtil.toast(context, 'Must not be empty');
            return;
          }
          print(csv) ;
          List<String> pieces = csv.split(',') ;
          if (pieces.length != 2) {
            BRMFlutterUtil.toast(context, 'Entry must be CSV with 2 values') ;
            return ;
          }
          var tag = pieces[0].trim() ;
          var origin = pieces[1].trim() ;
          for (var entry in _dataSource.entries) {
            if (entry.tag == tag) {
              BRMFlutterUtil.toast(context, 'Tag already exists', 3);
              return;
            }
          }

          LoggingTagEntry entry = LoggingTagEntry(tag, origin) ;
          setState(() {
            _dataSource.addEntry(entry) ;
          }) ;

          BRMFlutterUtil.toast(context, 'Entry added') ;
          Navigator.pop(context);
        });
  }

  _actionSetSelectedTagLevel() {
    if (! isEntrySelected()) {
      BRMFlutterUtil.toast(context, 'No entry is selected') ;
      return ;
    }

    String tag = getSelectedEntry().tag ;
    BRMFlutterUtil.toast(context, 'Setting tag: $tag log level to: $_selectedDropdownValue') ;
    _setLevel(tag, _selectedDropdownValue) ;
  }

  _actionSetGlobalLevel() {
    BRMFlutterUtil.toast(context, 'Setting global log level to $_selectedGlobalDropdownValue') ;
    String tag = '*' ;
    _setLevel(tag, _selectedGlobalDropdownValue) ;
  }

  //
  // App State
  //
  _postFrameCallback(context) {
    // Empty for now
  }

  //
  // Framework Overrides
  //
  @override
  initState() {
    //  int _rowsPerPage = _dataSource.entries.length;
    _sortAscending = false;
    _sortColumnIndex = null;

    _originSortAsc = true;
    _tagSortAsc = true ;

    _selectedDropdownValue = 'ESP_LOG_INFO' ;
    _selectedGlobalDropdownValue = 'ESP_LOG_DEBUG' ;

    super.initState() ;

    // Do this LAST and for sure after super.initState()
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallback(context)) ;
  }

  @override
  dispose() {

    super.dispose() ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Component/Module Logging Levels')),
        body: _buildBody(),
    );
  }
}

class LoggingLevelsDataTableWidget extends StatefulWidget {
  @override
  _LoggingLevelsDataTableState createState() {
    return _LoggingLevelsDataTableState();
  }
}
