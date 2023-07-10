import 'dart:async';
import 'dart:math';

import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:npay/data/cache.dart';
import 'package:npay/data/user_data.dart';
import 'package:npay/pages/login.dart';
import 'package:npay/pages/statement.dart';
import 'package:npay/utils/events.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/npay_color.dart';
import 'settings.dart';

enum PopupAccount {
  change,
  add,
  exit,
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var money = "0";
  var userData = UserData.getInstance();
  final _textFieldController = TextEditingController();
  var connection = true;

  Future<void> displayTextInputDialog(
      BuildContext context,
      TextEditingController controller,
      TextInputType type,
      String title,
      String hint,
      Function f) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              keyboardType: type,
              controller: controller,
              decoration: InputDecoration(hintText: hint),
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(redColor),
                ),
                child: const Text(
                  "TORNA INDIETRO",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(greenColor),
                ),
                onPressed: (() {
                  f();
                  setState(() {
                    controller.clear();
                    Navigator.pop(context);
                  });
                }),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        });
  }

  Future<void> sendMoney(
      String user, double amount, BuildContext context) async {
    FLog.info(text: "Sending money");
    var response = await http.get(Uri.parse(
        "https://rest.rgbcraft.com/npayapi/?richiesta=trasferimento&auth=${userData.pass}&utente=${userData.user}&valore=$amount&beneficiario=$user"));
    if (response.statusCode != 200) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            title: Text("Errore"),
            content: Text("È avvenuto un errore durante l'ultimo pagamento"),
          );
        },
      );
    }
    reloadPage();
  }

  List<Widget> getUsers() {
    FLog.info(text: "Getting users");
    List<Widget> users = [];
    for (var user in userData.phoneBook) {
      users.add(
        TextButton(
          onLongPress: (() {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Rimuovi"),
                    content: Text(
                        "Sei sicuro di voler rimuovere $user dalla rubrica?"),
                    actions: <Widget>[
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(redColor),
                        ),
                        child: const Text(
                          "NO",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            Navigator.pop(context);
                          });
                        },
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(greenColor),
                        ),
                        onPressed: (() {
                          setState(() {
                            userData.removeFromPhoneBook(user);
                            Navigator.pop(context);
                          });
                        }),
                        child: const Text(
                          "SI",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                });
          }),
          onPressed: (() {
            displayTextInputDialog(
              context,
              _textFieldController,
              TextInputType.number,
              "Invia soldi",
              "Inserire il numero di IC da inviare",
              (() {
                String str = "";
                int k = 0;
                for (int i = 0; i < _textFieldController.text.length; i++) {
                  var char = _textFieldController.text[i];
                  if (double.tryParse(char) != null) {
                    str += char;
                  } else if (char == ',' || char == '.') {
                    str += '.';
                  } else if (char == 'k') {
                    k++;
                  }
                }
                double money = double.parse(str);
                money *= pow(1000, k);
                sendMoney(user, money, context);
              }),
            );
          }),
          child: Text(
            user,
            style: TextStyle(
              color:
                  MediaQuery.of(context).platformBrightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
              fontSize: 20,
            ),
          ),
        ),
      );
    }
    users.add(TextButton(
      onPressed: (() {
        displayTextInputDialog(
          context,
          _textFieldController,
          TextInputType.text,
          "Aggiungi utente alla lista",
          "Username utente",
          (() async {
            await userData.addToPhoneBook(_textFieldController.text);
            await userData.savePhoneBook();
            setState(() {});
          }),
        );
      }),
      child: const Icon(Icons.person_add_rounded),
    ));
    return users;
  }

  DateTime getDate(String raw) {
    var splitted = raw.split("|");
    var str = "${splitted[0].substring(0, splitted[0].length - 1)}:00";
    var day = str.substring(0, 2);
    var month = str.substring(3, 5);
    var year = str.substring(6, 10);
    var hour = str.substring(11, str.length);
    str = "$year-$month-$day $hour";
    return DateTime.parse(str);
  }

  String getLastMovements() {
    int min(a, b) {
      return a <= b ? a : b;
    }

    FLog.info(text: "Getting last movements");
    var _in = Cache.getInstance().getCacheData(userData.user).statementIn;
    var _out = Cache.getInstance().getCacheData(userData.user).statementOut;
    List<String> total = List.empty(growable: true);
    String lastMovements = "";
    for (var raw in _in) {
      total.add(raw);
    }
    for (var raw in _out) {
      total.add(raw);
    }
    total.sort((a, b) {
      var aDate = getDate(a);
      var bDate = getDate(b);
      return -aDate.compareTo(bDate);
    });
    for (int i = 0; i < min(total.length, 5); i++) {
      lastMovements = "$lastMovements${total[i]}\n";
    }
    return lastMovements;
  }

  List<TextSpan> getLastMovementsText() {
    FLog.info(text: "Getting last movements");
    try {
      var lastMovements = getLastMovements();
      List<TextSpan> texts = List.empty(growable: true);
      FLog.info(text: "lastMovements: ${lastMovements.split('\n')}");
      for (var last in lastMovements.split('\n')) {
        var color = last.contains('+') ? greenColor : redColor;
        // Rimuove tutti i segni positivi e negativi
        // all'utente basta solo il colore per capire
        last = last.replaceAll('-', '').replaceAll('+', '');
        texts.add(TextSpan(
          text: "$last\n",
          style: TextStyle(
            color: color,
            fontSize: 18,
          ),
        ));
      }
      String? text = texts.last.text;
      if (text != null) {
        text = text.substring(0, text.length - 1);
        texts.last = TextSpan(text: text, style: texts.last.style);
      }
      return texts;
    } catch (e, trace) {
      FLog.fatal(
          text: "Error on getting last movements",
          exception: e,
          stacktrace: trace);
      return [TextSpan(text: "ERROR ${e.runtimeType}")];
    }
  }

  void addAccount() {
    FLog.info(text: "Adding account");
    userData.removeDefaultUser();
    userData.saveCredentialsList();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LoginPage(autoLogin: false)));
  }

  Future<void> reloadPage() async {
    try {
      var pref = await SharedPreferences.getInstance();
      pref.getBool("all_account_requested") ?? false
          ? Cache.getInstance().reloadAll()
          : Cache.getInstance().reloadUser(userData.user);
    } catch (e) {
      FLog.fatal(
          text: "Error on asking reloading for ${userData.user}; trying anyway",
          exception: e);
      try {
        Cache.getInstance().reloadUser(userData.user);
      } catch (e) {
        FLog.fatal(text: "Error on asking the second time", exception: e);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    EventManager.getInstance().addListener(EventListener(
      eventName: "reload_page",
      function: ((noError) {
        try {
          setState(() {
            if (noError != connection) {
              if (!noError) {
                final snackBar = SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: const Text("Impossibile connettersi al server"),
                  backgroundColor: redColor,
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              } else {
                final snackBar = SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: const Text("Riconnesso al server"),
                  backgroundColor: greenColor,
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            }
            money = Cache.getInstance().getCacheData(userData.user).money;
          });
        } catch (e, trace) {
          FLog.fatal(
              text: "Error on loading money", exception: e, stacktrace: trace);
        }
      }),
    ));
    const duration = Duration(seconds: 5);
    Timer.periodic(duration, (timer) async {
      await reloadPage();
    });
    FLog.info(text: "Initialized");
  }

  // l'istruzione sotto serve ad evitare possibili errori di tema
  // MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white : Colors.black
  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text("NPay"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
              onPressed: () async {
                await reloadPage();
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton(
                  icon: Icon(
                    Icons.account_circle_rounded,
                    color: blueColor,
                  ),
                  onSelected: (PopupAccount value) {
                    switch (value) {
                      case PopupAccount.change:
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                                title: const Text("Seleziona Account"),
                                actions: [
                                  TextButton(
                                    child: const Text("Aggiungi"),
                                    onPressed: () {
                                      addAccount();
                                    },
                                  ),
                                ],
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: userData.credentialsList.length,
                                    itemBuilder: (context, i) {
                                      return userData.credentialsList
                                                  .elementAt(i)
                                                  .user !=
                                              userData.user
                                          ? TextButton(
                                              child: Text(userData
                                                  .credentialsList
                                                  .elementAt(i)
                                                  .user),
                                              onPressed: () async {
                                                userData.setDefaultUser(userData
                                                    .credentialsList
                                                    .elementAt(i)
                                                    .user);
                                                userData.saveCredentialsList();
                                                var pref =
                                                    await SharedPreferences
                                                        .getInstance();
                                                pref.getBool(
                                                            "all_account_requested") ??
                                                        false
                                                    ? false
                                                    : await Cache.getInstance()
                                                        .reloadUser(
                                                            userData.user);
                                                Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            const HomePage()),
                                                    (r) => false);
                                              },
                                            )
                                          : const SizedBox(
                                              height: 0,
                                              width: 0,
                                            );
                                    },
                                  ),
                                ));
                          },
                        );
                        break;
                      case PopupAccount.add:
                        addAccount();
                        break;
                      case PopupAccount.exit:
                        userData.removeAccount(userData.user);
                        userData.saveCredentialsList();
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const LoginPage(autoLogin: false)),
                            (r) => false);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<PopupAccount>>[
                    PopupMenuItem(
                      value: PopupAccount.change,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(
                                Icons.people_alt_rounded,
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: " Cambia account",
                              style: TextStyle(
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: PopupAccount.add,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(
                                Icons.person_add_rounded,
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: " Aggiungi account",
                              style: TextStyle(
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: PopupAccount.exit,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(
                                Icons.logout_rounded,
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: " Esci",
                              style: TextStyle(
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: 20,
                ),
                child: Center(
                  child: Text(
                    "Benvenuto",
                    style: TextStyle(
                      color: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  userData.user,
                  style: TextStyle(
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 20),
                child: Center(
                  child: Text(
                    Cache.getInstance().getCacheData(userData.user).money,
                    style: TextStyle(
                      color: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 75,
                child: Card(
                  child: ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    children: getUsers(),
                  ),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("Bolletta RG Energy",
                          style: TextStyle(
                            fontSize: 18,
                          )),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "Fisse: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                "${Cache.getInstance().getCacheData(userData.user).rgData.fixed}\n",
                          ),
                          const TextSpan(
                            text: "Variabili: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                "${Cache.getInstance().getCacheData(userData.user).rgData.variable}\n",
                          ),
                          const TextSpan(
                            text: "Totale: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: Cache.getInstance()
                                .getCacheData(userData.user)
                                .rgData
                                .total,
                          ),
                        ],
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                            onPressed: () async {
                              await http.get(Uri.parse(
                                  "https://rgbasics.rgbcraft.com/rg-energy/checkBill.php?user=${userData.user}&action=pay&password=${userData.pass}"));
                              await sendMoney(
                                  "NInc.",
                                  Cache.getInstance()
                                      .getCacheData(userData.user)
                                      .rgData
                                      .commissions,
                                  context);
                            },
                            child: const Text("Paga bolletta")),
                      ],
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("Ultimi movimenti",
                          style: TextStyle(
                            fontSize: 18,
                          )),
                    ),
                    RichText(
                      text: TextSpan(
                        children: getLastMovementsText(),
                      ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const StatementPage()));
                          },
                          child: const Text("Mostra altro"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // TextButton(
              //   onPressed: () async {
              //     await Statement.getInstance().save();
              //   },
              //   child: const Text("Save"),
              // ),
              // TextButton(
              //   onPressed: () async {
              //     await Statement.getInstance().load();
              //     reloadPage();
              //   },
              //   child: const Text("Load"),
              // ),
            ],
          ),
        ),
      );
    } catch (e, trace) {
      FLog.fatal(text: "Error loading page", exception: e, stacktrace: trace);
      return Scaffold(
        body: Center(
          child: Text("Error type ${e.runtimeType}"),
        ),
      );
    }
  }
}
