import 'dart:convert';
import 'dart:developer';

import 'package:f_logs/f_logs.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:npay/data/statement.dart';
import 'package:npay/data/user_data.dart';
import 'package:npay/utils/events.dart';

class NoCacheData extends Error {}

var numberFormat = NumberFormat.currency(
    locale: 'it', name: 'CLF', symbol: 'IC', decimalDigits: 2);

class RGData {
  final String _fixed;
  final String _variable;
  final String _total;
  final double _commissions;

  RGData(this._fixed, this._variable, this._total, this._commissions);

  String get fixed => _fixed;

  String get variable => _variable;

  String get total => _total;

  double get commissions => _commissions;
}

class CacheData {
  List<String> _statementIn = List.empty(growable: true);
  List<String> _statementOut = List.empty(growable: true);
  final String _user;
  String _money = "0";

  CacheData(this._user);

  Future<bool> reload() async {
    try {
      var response = await http.get(Uri.parse(
          "https://rest.rgbcraft.com/npayapi/?richiesta=verifica&auth=${UserData.getInstance().getPass(_user)}&utente=$_user"));
      if (response.statusCode == 200) {
        log("good response");
        log("${response.body}");
        var decoded = jsonDecode(response.body);
        _money = numberFormat.format(decoded['credit'].toDouble());
        await Statement.getInstance().reloadUser(_user);
        var statements = Statement.getInstance().getUser(_user);
        _statementIn = statements.statementIn;
        _statementOut = statements.statementOut;
        return true;
      } else {
        log("no good response");
      }
    } catch (e, trace) {
      FLog.fatal(
        text: "Error reloading cache for $_user",
        exception: e,
        stacktrace: trace,
      );
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

  CacheData? getCacheData(String user) {
    for (var cache in caches) {
      if (cache._user == user) {
        return cache;
      }
    }
    return null;
  }

  Future<void> addUser(String user) async {
    try {
      var cache = CacheData(user);
      await cache.reload();
      caches.add(cache);
    } catch (e, trace) {
      FLog.fatal(
        text: "Error getting data for $user",
        exception: e,
        stacktrace: trace,
      );
    }
  }

  Future<bool> reloadUser(String user) async {
    log("Reloading user $user");
    log("Cache is empty: ${caches.isEmpty}");
    if (caches.isEmpty) {
      caches.add(CacheData(user));
    }

    for (var cache in caches) {
      if (cache._user == user) {
        var noError = await cache.reload();
        EventManager.getInstance()
            .dispatchEvent(Event(name: "reload_page", data: noError));
        return noError;
      }
    }
    return false;
  }

  Future<bool> reloadAll() async {
    log("Reloading all; len: ${caches.length}");
    var noError = true;
    for (var cache in caches) {
      noError &= await cache.reload();
    }
    EventManager.getInstance()
        .dispatchEvent(Event(name: "reload_page", data: noError));
    return noError;
  }
}
