import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:npay/data/cache.dart';
import 'package:npay/utils/events.dart';
import 'package:npay/utils/npay_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/user_data.dart';

final NumberFormat numberFormat = NumberFormat.currency(
    locale: 'it', name: 'CLF', symbol: 'IC', decimalDigits: 2);
final DateFormat dateFormat = DateFormat("dd/MM/yyyy HH:mm");

class _Movement {
  final DateTime date;
  final String money;
  final double rawMoney;
  final String direction;
  final MaterialColor color;

  const _Movement(
      {required this.date,
      required this.money,
      required this.rawMoney,
      required this.direction,
      required this.color});
}

class StatementPage extends StatefulWidget {
  const StatementPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StatementPage();
}

class _StatementPage extends State<StatementPage> {
  List<_Movement> movements = List.empty(growable: true);
  bool isAscending = false;
  int? index;
  bool from = true;
  bool to = true;

  DateTime getDate(String raw) {
    var splitted = raw.split("|");
    var str = splitted[0].substring(0, splitted[0].length - 1) + ":00";
    var day = str.substring(0, 2);
    var month = str.substring(3, 5);
    var year = str.substring(6, 10);
    var hour = str.substring(11, str.length);
    str = "$year-$month-$day $hour";
    return DateTime.parse(str);
  }

  _Movement rawToMovement(String raw, MaterialColor color) {
    var date = getDate(raw);
    var money = "";
    var rawMoney = 0.0;
    var direction = "";
    var splitted = raw.split('|');
    for (int i = 0; i < splitted[1].length - 1; i++) {
      // splitted[1] = " XXXX IC ..."
      if (splitted[1][i] == "I" &&
          splitted[1][i + 1] == "C" &&
          splitted[1][i + 2] == " ") {
        String result = "";
        for (int j = 0; j < splitted[1].length; j++) {
          if (j == (i - 1)) {
            rawMoney = double.parse(result.replaceAll(',', '.'));
            money = numberFormat.format(rawMoney); // Soldi
            if (rawMoney < 0) {
              rawMoney = -rawMoney;
            }
            result = "";
          }
          if (j == (i + 2)) {
            result = "";
          }
          result += splitted[1][j];
        }
        // nel ciclo for di sopra, dopo aver preparato i soldi,
        // viene resettato `result` per rimuovere "IC "
        // ed il rimanente è la direzione
        direction = result.trim(); // Direzione
      }
    }
    return _Movement(
        date: date,
        money: money,
        rawMoney: rawMoney,
        direction: direction,
        color: color);
  }

  void prepareMovements() {
    var cache = Cache.getInstance().getCacheData(UserData.getInstance().user);
    for (var raw in cache.statementIn) {
      movements.add(rawToMovement(raw, greenColor));
    }
    for (var raw in cache.statementOut) {
      movements.add(rawToMovement(raw, redColor));
    }
  }

  List<DataRow> getRows() {
    final rows = List.generate(
        movements.length,
        (int index) => DataRow(cells: [
              DataCell(Text(dateFormat.format(movements[index].date),
                  style: TextStyle(color: movements[index].color))),
              DataCell(Text(movements[index].money.replaceAll('-', ''),
                  style: TextStyle(color: movements[index].color))),
              DataCell(Text(movements[index].direction,
                  style: TextStyle(color: movements[index].color))),
            ]));
    return rows;
  }

  void applyFilters() {
    movements.clear();
    prepareMovements();
    setState(() {
      movements.removeWhere((element) {
        if (!from && !to) {
          return element.direction.split(' ')[0] == "da" ||
              element.direction.split(' ')[0] == "a";
        } else if (!from) {
          return element.direction.split(' ')[0] == "da";
        } else if (!to) {
          return element.direction.split(' ')[0] == "a";
        }
        return false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    prepareMovements();
    EventManager.getInstance().addListener(EventListener(
      eventName: "reload_page",
      function: ((noError) {
        setState(() {
          movements.clear();
          prepareMovements();
        });
      }),
    ));
    FLog.info(text: "Initialized");
  }

  @override
  Widget build(BuildContext context) {
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
              sortColumnIndex: index,
              sortAscending: isAscending,
              headingRowColor:
                  MaterialStateColor.resolveWith((states) => blueColor),
              columns: <DataColumn>[
                DataColumn(
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      isAscending = ascending;
                      index = columnIndex;
                      if (ascending) {
                        movements.sort((a, b) => a.date.compareTo(b.date));
                      } else {
                        movements.sort((a, b) => -a.date.compareTo(b.date));
                      }
                    });
                  },
                  label: const Text(
                    "Data",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      isAscending = ascending;
                      index = columnIndex;
                      if (ascending) {
                        movements
                            .sort((a, b) => a.rawMoney.compareTo(b.rawMoney));
                      } else {
                        movements
                            .sort((a, b) => -a.rawMoney.compareTo(b.rawMoney));
                      }
                    });
                  },
                  label: const Text(
                    "Quantità",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(
                  label: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Filtri"),
                            content: SizedBox(
                              height: 150,
                              child: Column(
                                // shrinkWrap: true,
                                children: <Widget>[
                                  const Text("Utenti"),
                                  Row(
                                    children: [
                                      StatefulBuilder(
                                        builder: (BuildContext context,
                                            StateSetter setState) {
                                          return Checkbox(
                                            value: from,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value != null) {
                                                  from = value;
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      const Text("Da"),
                                      StatefulBuilder(
                                        builder: (BuildContext context,
                                            StateSetter setState) {
                                          return Checkbox(
                                            value: to,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value != null) {
                                                  to = value;
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      const Text("A"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text("Salva filtri"),
                                onPressed: () {
                                  applyFilters();
                                  Navigator.maybePop(context);
                                },
                              )
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(
                      "Direzione",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              rows: getRows(),
            ),
          ],
        ),
      ),
    );
  }
}
