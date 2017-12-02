import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';

class DialogViewModel {
  final WeightEntry weightEntry;
  final String unit;
  final bool isEditMode;
  final Function(WeightEntry) onEntryChanged;
  final Function() onDeletePressed;
  final Function() onSavePressed;

  DialogViewModel({
    this.weightEntry,
    this.unit,
    this.isEditMode,
    this.onEntryChanged,
    this.onDeletePressed,
    this.onSavePressed,
  });
}

class WeightEntryDialog extends StatefulWidget {

  @override
  State<WeightEntryDialog> createState() {
    return new WeightEntryDialogState();
  }
}

class WeightEntryDialogState extends State<WeightEntryDialog> {
  TextEditingController _textController;
  bool wasBuiltOnce = false;

  @override
  void initState() {
    super.initState();
    _textController = new TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<ReduxState, DialogViewModel>(
      converter: (store) {
        return new DialogViewModel(
            weightEntry: store.state.activeEntry,
            unit: store.state.unit,
            isEditMode: store.state.isEditMode,
            onEntryChanged: (entry) =>
                store.dispatch(new UpdateActiveWeightEntry(entry)),
            onDeletePressed: () {
              store.dispatch(new RemoveEntryAction(store.state.activeEntry));
              Navigator.of(context).pop();
            },
            onSavePressed: () {
              if (store.state.isEditMode) {
                store.dispatch(new EditEntryAction(store.state.activeEntry));
              } else {
                store.dispatch(new AddEntryAction(store.state.activeEntry));
              }
              Navigator.of(context).pop();
            });
      },
      builder: (context, viewModel) {
        if (!wasBuiltOnce) {
          wasBuiltOnce = true;
          _textController.text = viewModel.weightEntry.note;
        }
        return new Scaffold(
          appBar: _createAppBar(context, viewModel),
          body: new Column(
            children: [
              new ListTile(
                leading: new Icon(Icons.today, color: Colors.grey[500]),
                title: new DateTimeItem(
                  dateTime: viewModel.weightEntry.dateTime,
                  onChanged: (dateTime) =>
                      viewModel.onEntryChanged(
                          viewModel.weightEntry..dateTime = dateTime),
                ),
              ),
              new ListTile(
                leading: new Image.asset(
                  "assets/scale-bathroom.png",
                  color: Colors.grey[500],
                  height: 24.0,
                  width: 24.0,
                ),
                title: new Text(
                  viewModel.weightEntry.weight.toString() +
                      " " +
                      viewModel.unit,
                ),
                onTap: () => _showWeightPicker(context, viewModel),
              ),
              new ListTile(
                leading: new Icon(Icons.speaker_notes, color: Colors.grey[500]),
                title: new TextField(
                    decoration: new InputDecoration(
                      hintText: 'Optional note',
                    ),
                    controller: _textController,
                    onChanged: (value) {
                      viewModel
                          .onEntryChanged(viewModel.weightEntry..note = value);
                    }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _createAppBar(BuildContext context, DialogViewModel viewModel) {
    TextStyle actionStyle =
    Theme
        .of(context)
        .textTheme
        .subhead
        .copyWith(color: Colors.white);
    Text title = viewModel.isEditMode
        ? const Text("Edit entry")
        : const Text("New entry");
    List<Widget> actions = [];
    if (viewModel.isEditMode) {
      actions.add(
        new FlatButton(
          onPressed: viewModel.onDeletePressed,
          child: new Text(
            'DELETE',
            style: actionStyle,
          ),
        ),
      );
    }
    actions.add(new FlatButton(
      onPressed: viewModel.onSavePressed,
      child: new Text(
        'SAVE',
        style: actionStyle,
      ),
    ));

    return new AppBar(
      title: title,
      actions: actions,
    );
  }

  _showWeightPicker(BuildContext context, DialogViewModel viewModel) {
    showDialog(
      context: context,
      child: new NumberPickerDialog.decimal(
        minValue: 1,
        maxValue: 300,
        initialDoubleValue: viewModel.weightEntry.weight,
        title: new Text("Enter your weight"),
      ),
    ).then((value) {
      if (value != null) {
        viewModel.onEntryChanged(viewModel.weightEntry..weight = value);
      }
    });
  }
}

class DateTimeItem extends StatelessWidget {
  DateTimeItem({Key key, DateTime dateTime, @required this.onChanged})
      : assert(onChanged != null),
        date = dateTime == null
            ? new DateTime.now()
            : new DateTime(dateTime.year, dateTime.month, dateTime.day),
        time = dateTime == null
            ? new DateTime.now()
            : new TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
        super(key: key);

  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Expanded(
          child: new InkWell(
            onTap: (() => _showDatePicker(context)),
            child: new Padding(
                padding: new EdgeInsets.symmetric(vertical: 8.0),
                child: new Text(new DateFormat('EEEE, MMMM d').format(date))),
          ),
        ),
        new InkWell(
          onTap: (() => _showTimePicker(context)),
          child: new Padding(
              padding: new EdgeInsets.symmetric(vertical: 8.0),
              child: new Text(time.format(context))),
        ),
      ],
    );
  }

  Future _showDatePicker(BuildContext context) async {
    DateTime dateTimePicked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: date.subtract(const Duration(days: 365)),
        lastDate: new DateTime.now());

    if (dateTimePicked != null) {
      onChanged(new DateTime(dateTimePicked.year, dateTimePicked.month,
          dateTimePicked.day, time.hour, time.minute));
    }
  }

  Future _showTimePicker(BuildContext context) async {
    TimeOfDay timeOfDay =
        await showTimePicker(context: context, initialTime: time);

    if (timeOfDay != null) {
      onChanged(new DateTime(
          date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute));
    }
  }
}
