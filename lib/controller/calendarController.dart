import 'dart:async';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

getDate(String date,[String hour="00h00"]){
  if(date.isNotEmpty){
    final fullTime = date.split('-');
    if(!hour.contains("00h00") && hour.isNotEmpty){
      fullTime.add(" ");
      final fullHour = hour.split('h');
      return fullTime + fullHour;
    }else{
      return fullTime;
    }
  }else{
    return null;
  }
}

class MyCalendar extends StatefulWidget {
  @override
  MyCalendarState createState() {
    return  MyCalendarState();
  }
}

class MyCalendarState extends State<MyCalendar> {
  DeviceCalendarPlugin _deviceCalendarPlugin;

  List<Calendar> _calendars;
  Calendar _selectedCalendar;
  List<Event> _calendarEvents;

  MyCalendarState() {
    _deviceCalendarPlugin =  DeviceCalendarPlugin();
  }

  @override
  initState() {
    super.initState();
    _retrieveCalendars();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar:  AppBar(
        title:  Text('Device Calendar Example'),
      ),
      body:  Column(
        children: <Widget>[
          ConstrainedBox(
            constraints:  BoxConstraints(maxHeight: 150.0),
            child:  ListView.builder(
              itemCount: _calendars?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                return  GestureDetector(
                  onTap: () async {
                    await _retrieveCalendarEvents(_calendars[index].id);
                    setState(() {
                      _selectedCalendar = _calendars[index];
                    });
                  },
                  child:  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child:  Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child:  Text(
                            _calendars[index].name,
                            style:  TextStyle(fontSize: 25.0),
                          ),
                        ),
                        Icon(_calendars[index].isReadOnly
                            ? Icons.lock
                            : Icons.lock_open)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 1,
            child:  Container(
              decoration:  BoxDecoration(color: Colors.white),
              child:  ListView.builder(
                itemCount: _calendarEvents?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  return  EventItem(
                      _calendarEvents[index], _deviceCalendarPlugin, () async {
                    await _retrieveCalendarEvents(_selectedCalendar.id);
                  });
                },
              ),
            ),
          ),
        ],
      ),
      // Create data here
      floatingActionButton: !(_selectedCalendar?.isReadOnly ?? true)
          ?  FloatingActionButton(
        onPressed: () async {
          final eventToCreate =  Event(_selectedCalendar.id);

          final _duration = 1;
          final _title = "Type - title";
          final _location = "Rue de Paris";

          final _date = "2019-06-06";
          final _hour = "12h15";

          var _startTime;
          final fullTime = getDate(_date, _hour);
          final _fyear = int.parse(fullTime[0]);
          final _fmonth = int.parse(fullTime[1]);
          final _fday = int.parse(fullTime[2]);
          if(fullTime.length >3){
            final _fhour = int.parse(fullTime[4]);
            final _fminute = int.parse(fullTime[5]);
            _startTime = DateTime(_fyear, _fmonth, _fday, _fhour, _fminute);
          }else{
            _startTime = DateTime(_fyear, _fmonth, _fday);
          }

          //data initialization
          eventToCreate.title = _title;
          eventToCreate.description = _location;
          eventToCreate.location = "localisation";
          eventToCreate.start = _startTime;
          eventToCreate.end = _startTime.add( Duration(hours: _duration));
          //end data initialization

          final createEventResult = await _deviceCalendarPlugin
              .createOrUpdateEvent(eventToCreate);
          if (createEventResult.isSuccess &&
              (createEventResult.data?.isNotEmpty ?? false)) {
            _retrieveCalendarEvents(_selectedCalendar.id);
          }
        },
        child:  Icon(Icons.add),
      )
          :  Container(),
    );
  }

  void _retrieveCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      setState(() {
        _calendars = calendarsResult?.data;
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future _retrieveCalendarEvents(String calendarId) async {
    try {
      final startDate =  DateTime.now().add( Duration(days: -30));
      final endDate =  DateTime.now().add( Duration(days: 30));
      final retrieveEventsParams =
      RetrieveEventsParams(startDate: startDate, endDate: endDate);
      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendarId, retrieveEventsParams);

      setState(() {
        _calendarEvents = eventsResult?.data;
      });
    } catch (e) {
      print(e);
    }
  }
}

class EventItem extends StatelessWidget {
  final Event _calendarEvent;
  final DeviceCalendarPlugin _deviceCalendarPlugin;

  final Function onDeleteSucceeded;

  final double _eventFieldNameWidth = 75.0;

  EventItem(
      this._calendarEvent, this._deviceCalendarPlugin, this.onDeleteSucceeded);

  @override
  Widget build(BuildContext context) {
    return  Card(
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListTile(
              title:  Text(_calendarEvent.title ?? ''),
              subtitle:  Text(_calendarEvent.description ?? '')),

          //CALENDAR PREVIEW
          Container(
            padding:  EdgeInsets.symmetric(horizontal: 16.0),
            child:  Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child:  Row(
                    children: <Widget>[
                      Container(
                        width: _eventFieldNameWidth,
                        child:  Text('All day?'),
                      ),
                      Text(
                          _calendarEvent.allDay != null && _calendarEvent.allDay
                              ? 'Yes'
                              : 'No'),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child:  Row(
                    children: <Widget>[
                      Container(
                        width: _eventFieldNameWidth,
                        child:  Text('Location'),
                      ),
                      Expanded(
                        child:  Text(
                          _calendarEvent?.location ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child:  Row(
                    children: <Widget>[
                      Container(
                        width: _eventFieldNameWidth,
                        child:  Text('Attendees'),
                      ),
                      Expanded(
                        child:  Text(
                          _calendarEvent?.attendees
                              ?.where((a) => a.name?.isNotEmpty ?? false)
                              ?.map((a) => a.name)
                              ?.join(', ') ??
                              '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ButtonTheme.bar(
            child:  ButtonBar(
              children: <Widget>[
                IconButton(
                  onPressed: () async {
                    final deleteResult =
                    await _deviceCalendarPlugin.deleteEvent(
                        _calendarEvent.calendarId, _calendarEvent.eventId);
                    if (deleteResult.isSuccess && deleteResult.data) {
                      onDeleteSucceeded();
                    }
                  },
                  icon:  Icon(Icons.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}