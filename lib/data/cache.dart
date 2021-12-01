import 'dart:convert';

import 'package:f_logs/f_logs.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:npay/data/user_data.dart';
import 'package:npay/utils/events.dart';

class NoCacheData extends Error {}

var numberFormat = NumberFormat.currency(
    locale: 'it', name: 'CLF', symbol: 'IC', decimalDigits: 2);

// TODO: implement `Statement` integration (2.3.0-dev)

class CacheData {
  final List<String> _statementIn = List.empty(growable: true);
  final List<String> _statementOut = List.empty(growable: true);
  final String _user;
  String _money = "0";

  CacheData(this._user);

  Future<bool> reload() async {
    try {
      var response = await http.get(Uri.parse(
          "https://sunfire.a-centauri.com/npayapi/?richiesta=estratto&auth=${UserData.getInstance().getPass(_user)}&utente=$_user"));
      if (response.statusCode == 200) {
        _statementIn.clear();
        _statementOut.clear();
        var decoded = jsonDecode(response.body);
        _money = numberFormat.format(decoded['credit'].toDouble());
        // Vanno usati due cicli for per evitare bug stupidi con account "nuovi"
        for (int i = 1; i <= decoded['in'].length; i++) {
          if (decoded['in']['$i'].toString().isNotEmpty) {
            _statementIn.add(decoded['in']['$i']);
          }
        }
        for (int i = 1; i <= decoded['out'].length; i++) {
          if (decoded['out']['$i'].toString().isNotEmpty) {
            _statementOut.add(decoded['out']['$i']);
          }
        }
        return true;
      }
    } catch (e, trace) {
      FLog.fatal(
          text: "Error reloading cache for $_user",
          exception: e,
          stacktrace: trace);
    }
    return false;
  }

  String get money => _money;

  List<String> get statementIn => _statementIn;

  List<String> get statementOut => _statementOut;
}

class Cache {
  Cache._internal(); // Vedasi user_data.dart per capire il motivo di questa riga
  static final Cache _instance = Cache._internal();

  final Set<CacheData> caches = {};

  static Cache getInstance() =>
      _instance; // Stessa cosa di sopra (`Cache._internal()`)

  CacheData getCacheData(String user) {
    for (var cache in caches) {
      if (cache._user == user) {
        return cache;
      }
    }
    throw NoCacheData;
  }

  void addUser(String user) => caches.add(CacheData(user));

  Future<bool> reloadUser(String user) async {
    FLog.info(text: "Reloading user $user");
    for (var cache in caches) {
      if (cache._user == user) {
        var noError = await cache.reload();
        EventManager.getInstance()
            .dispatchEvent(const Event(name: "reload_page"));
        return noError;
      }
    }
    return false;
  }

  Future<bool> reloadAll() async {
    FLog.info(text: "Reloading all");
    var noError = true;
    for (var cache in caches) {
      noError &= await cache.reload();
    }
    EventManager.getInstance().dispatchEvent(const Event(name: "reload_page"));
    return noError;
  }
}
