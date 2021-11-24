import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:npay/data/cache.dart';
import 'package:npay/utils/events.dart';
import 'package:npay/utils/npay_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/user_data.dart';

class StatementPage extends StatefulWidget {
  const StatementPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StatementPage();
}

class _StatementPage extends State<StatementPage> {
  List<DataRow> rows = List.empty(growable: true);
  bool toUpdate = true;

  List<DataCell> rawToCells(String raw, MaterialColor color) {
    List<DataCell> cells = List.empty(growable: true);

    var splitted = raw.split("|");
    cells.add(DataCell(Text(splitted[0], style: TextStyle(color: color))));

    for (int i = 0; i < splitted[1].length - 1; i++) {
      if (splitted[1][i] == "I" &&
          splitted[1][i + 1] == "C" &&
          splitted[1][i + 2] == " ") {
        String result = "";
        for (int j = 0; j < splitted[1].length; j++) {
          if (j == (i + 2)) {
            cells.add(DataCell(Text(result, style: TextStyle(color: color))));
            result = "";
          }
          result += splitted[1][j];
        }
        cells.add(DataCell(Text(result, style: TextStyle(color: color))));
      }
    }

    return cells;
  }

  void getDataRows() {
    setState(() {
      var cache = Cache.getInstance().getCacheData(UserData.getInstance().user);
      for (var raw in cache.statementIn) {
        rows.add(DataRow(cells: rawToCells(raw, greenColor)));
      }
      for (var raw in cache.statementOut) {
        rows.add(DataRow(cells: rawToCells(raw, redColor)));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    EventManager.getInstance().addListener(EventListener(
      eventName: "reload_page",
      function: (() {
        setState(() {
          toUpdate = true;
        });
      }),
    ));
    FLog.info(text: "Initialized");
  }

  @override
  Widget build(BuildContext context) {
    if (toUpdate) {
      toUpdate = false;
      getDataRows();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estratto conto"),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
            onPressed: () async {
              var pref = await SharedPreferences.getInstance();
              pref.getBool("all_account_requested") ?? false
                  ? Cache.getInstance().reloadAll()
                  : Cache.getInstance().reloadUser(UserData.getInstance().user);
            },
          ),
        ],
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            DataTable(
              headingRowColor:
                  MaterialStateColor.resolveWith((states) => blueColor),
              columns: const <DataColumn>[
                DataColumn(
                  label: Text(
                    "Data",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Quantità",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Direzione",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}
