import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'program_detail_page.dart'; // <-- Import your detail page

class ProgramCalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> programs;

  const ProgramCalendarPage({super.key, required this.programs});

  @override
  State<ProgramCalendarPage> createState() => _ProgramCalendarPageState();
}

class _ProgramCalendarPageState extends State<ProgramCalendarPage> {
  late Map<DateTime, List<Map<String, dynamic>>> events;
  Map<int, Color> programColors = {}; // programId → color

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _generateProgramColors();
    events = _convertProgramsToEvents(widget.programs);
  }

  // assign a unique color to each program
  void _generateProgramColors() {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.pink,
      Colors.cyan,
    ];

    int i = 0;
    for (var program in widget.programs) {
      int id = program["programId"];
      programColors[id] = colors[i % colors.length];
      i++;
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }

  // Create event for each date in the program's range
  Map<DateTime, List<Map<String, dynamic>>> _convertProgramsToEvents(
      List<Map<String, dynamic>> programs) {
    Map<DateTime, List<Map<String, dynamic>>> map = {};

    for (var p in programs) {
      DateTime start = _parseDate(p["programStartDate"]);
      DateTime end = _parseDate(p["programEndDate"]);

      for (DateTime d = start;
          d.isBefore(end.add(const Duration(days: 1)));
          d = d.add(const Duration(days: 1))) {
        DateTime key = DateTime(d.year, d.month, d.day);

        if (!map.containsKey(key)) map[key] = [];
        map[key]!.add(p);
      }
    }
    return map;
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Program Calendar"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,

            eventLoader: _getEventsForDay,

            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,

            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),

            // ---------- CUSTOM EVENT MARKERS ----------
            calendarBuilders: CalendarBuilders(
  markerBuilder: (context, date, events) {
    if (events.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 3,
      children: events.map((event) {
        if (event is! Map<String, dynamic>) return const SizedBox();

        final int programId = event["programId"] ?? 0;
        final Color color = programColors[programId] ?? Colors.grey;

        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  },
),


            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text("Select a date"))
                : _buildEventList(),
          )
        ],
      ),
    );
  }

  // ---------- LIST OF PROGRAMS UNDER THE CALENDAR ----------
  Widget _buildEventList() {
    final selectedEvents = _getEventsForDay(_selectedDay!);

    if (selectedEvents.isEmpty) {
      return const Center(child: Text("No programs on this day"));
    }

    return ListView.builder(
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final program = selectedEvents[index];
        final color = programColors[program["programId"]] ?? Colors.grey;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color),
            title: Text(program["programName"] ?? ""),
            subtitle: Text(program["programType"] ?? ""),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),

            // ---- NAVIGATE TO PROGRAM DETAIL PAGE ----
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProgramDetailPage(program: program), // IMPORTANT
                ),
              );
            },
          ),
        );
      },
    );
  }
}
