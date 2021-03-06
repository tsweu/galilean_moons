import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:galilean_moons/satellite_data.dart';
import 'package:galilean_moons/styles.dart';
import 'satellite_painter.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class MoonDisplay extends StatefulWidget {
  @override
  _MoonsState createState() => _MoonsState();
}

class _MoonsState extends State<MoonDisplay> {
  DateTime selectedDate = DateTime.now();
  View selectedView = View.direct;
  SatelliteData data = SatelliteData();
  bool nightMode = false;
  bool loading = true;

  bool neg(bool value) {
    if (value == true) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _mainDisplay();
    // if (loading) {
    //   // _loadData();
    //   return _loadingScreen();
    // } else {
    //   return _mainDisplay();
    // }
  }

  CupertinoPageScaffold _mainDisplay() {
    return CupertinoPageScaffold(
        backgroundColor: Styles.backgroundColor,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: _viewChangerWidget()),
                _nightModeWidget(),
              ],
            ),
            _displayWidget(),
            Row(
              children: <Widget>[
                Expanded(child: _currentDateWidget()),
                _nowWidget(),
              ],
            ),
          ],
        ));
  }

  Widget _startScreen() {
    return CupertinoPageScaffold(
      backgroundColor: Styles.launchBackground,
      child: Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 100),
          child: Image(
            image: AssetImage('images/launchJupiter.png')
          ),
        ),
        CupertinoButton(
        child: Text('Start', style: Styles().getBigTextStyle(nightMode)),
        onPressed: () => setState(() => loading = false),
        ),
      ],
    )
    );
  }

  // Widget _loadingScreen() {
  //   return Center(child: CircularProgressIndicator());
  // }

  // void _loadData() {
  //       // load jupiter data
  //   final content = _getFileContent('jupiter');
  //   content.then((content) {
  //     data.jData = const CsvToListConverter().convert(content);

  //     int numRows = data.jData.length;
  //     data.startDate = DateFormat('yyyy-MMM-dd hh:mm').parse(data.jData[1][0]);
  //     data.endDate = DateFormat('yyyy-MMM-dd hh:mm').parse(data.jData[numRows - 1][0]);
  //     data.intervalTime = DateFormat('yyyy-MMM-dd hh:mm')
  //         .parse(data.jData[2][0])
  //         .difference(data.startDate);

  //         // load moon data
  //   Moon.values.forEach((m) {
  //     final content = _getFileContent(getName(m).toLowerCase());
  //     content.then((content) {
  //       print('loading moon ${m.index}');
  //       data.moonData[m.index] = const CsvToListConverter().convert(content);

  //       if (data.moonData[Moon.callisto.index] != null) {
  //       setState(() {
  //         print('done loading moons');
  //         loading = false;
  //       });
  //       }});
  //   });
  //   });
  // }

  // Future<String> _getFileContent(String filename) async {
  //   return await rootBundle.loadString('data/$filename.csv');
  // }

  Expanded _displayWidget() {
    return Expanded(
        child: Center(
            child: CustomPaint(
      foregroundPainter: SatellitePainter(
          data.getCoords(selectedDate), selectedView, nightMode),
    )));
  }

  CupertinoSegmentedControl _viewChangerWidget() {
    return CupertinoSegmentedControl(
      children: const <View, Widget>{
        View.direct: Padding(child: Text('Direct'), padding: Styles.segPadding),
        View.inverted:
            Padding(child: Text('Inverted'), padding: Styles.segPadding),
        View.mirrored:
            Padding(child: Text('Mirrored'), padding: Styles.segPadding),
      },
      groupValue: selectedView,
      unselectedColor: Styles.backgroundColor,
      selectedColor: Styles().getPrimaryOrNight(nightMode),
      borderColor: Styles.backgroundColor,
      pressedColor: Styles.backgroundColor,
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      onValueChanged: (input) {
        setState(() {
          selectedView = input;
        });
      },
    );
  }

  FlatButton _nightModeWidget() {
    return FlatButton(
      child: Icon(CupertinoIcons.eye_solid, color: Styles.nightColor),
      onPressed: () {
        setState(() => nightMode = neg(nightMode));
      },
    );
  }

  GestureDetector _currentDateWidget() {
    return GestureDetector(
      child: Padding(
          child: Text(
            _dateToString(selectedDate),
            style: Styles().getBigTextStyle(nightMode),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10)),
      onTap: () {
        DatePicker.showDateTimePicker(context,
            showTitleActions: true,
            minTime: data.endDate,
            maxTime: data.startDate, onChanged: (date) {
          _setDate(date);
        }, onConfirm: (date) {
          _setDate(date);
        },
            currentTime: selectedDate,
            locale: LocaleType.en,
            theme: Styles().getPickerTheme(nightMode));
      },
    );
  }

  void _setDate(date) {
    if (date.isBefore(data.startDate)) {
      showAlertDialog(
          'Please pick a date after ${_dateToString(data.startDate)}',
          data.startDate);
    } else if (date.isAfter(data.endDate)) {
      showAlertDialog(
          'Please pick a date before ${_dateToString(data.endDate)}',
          data.endDate);
    } else {
      setState(() {
        selectedDate = date;
      });
    }
  }

  void showAlertDialog(String message, DateTime resetDate) {
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Date Limit Exceeded'),
            content: Align(
              child: Text(message),
              alignment: Alignment.centerLeft,
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                  child: Text('Dismiss'),
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context, 'Dismiss');
                    Navigator.pop(context);
                    setState(() {
                      selectedDate = resetDate;
                    });
                  })
            ],
          );
        });
  }

  FlatButton _nowWidget() {
    return FlatButton(
      child: Icon(CupertinoIcons.refresh,
          color: Styles().getPrimaryOrNight(nightMode)),
      onPressed: () {
        setState(() => selectedDate = DateTime.now());
      },
    );
  }

  String _dateToString(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }
}
