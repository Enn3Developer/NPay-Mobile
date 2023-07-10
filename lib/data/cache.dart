import 'dart:convert';

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

  RGData(this._fixed, this._variable, this._total);

  String get fixed => _fixed;

  String get variable => _variable;

  String get total => _total;
}

class CacheData {
  List<String> _statementIn = List.empty(growable: true);
  List<String> _statementOut = List.empty(growable: true);
  final String _user;
  String _money = "0";
  RGData _rgData;

  CacheData(this._user, this._rgData);

  Future<bool> reload() async {
    try {
      var response = await http.get(Uri.parse(
          "https://rest.rgbcraft.com/npayapi/?richiesta=verifica&auth=${UserData
              .getInstance().getPass(_user)}&utente=$_user"));
      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        _money = numberFormat.format(decoded['credit'].toDouble());
        await Statement.getInstance().reloadUser(_user);
        var statements = Statement.getInstance().getUser(_user);
        _statementIn = statements.statementIn;
        _statementOut = statements.statementOut;

        response = await http.get(Uri.parse(
            "https://rgbasics.rgbcraft.com/rg-energy/checkBill.php?user=$_user"));
        if (response.statusCode != 200) {
          throw Error();
        }
        var data = response.body
            .replaceAll("[", "")
            .replaceAll("]", "")
            .replaceAll("=", ":");
        decoded = jsonDecode(data.replaceRange(data.length - 2, null, "}"));
        var fixed = numberFormat.format(decoded['fisse'].toDouble());
        var variable = numberFormat.format(decoded['variabili'].toDouble());
        var total = numberFormat.format(decoded['totale'].toDouble());
        _rgData = RGData(fixed, variable, total);

        return true;
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

  RGData get rgData => _rgData;
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

  Future<void> addUser(String user) async {
    try {
      var response = await http.get(Uri.parse(
          "https://rgbasics.rgbcraft.com/rg-energy/checkBill.php?user=$user"));
      if (response.statusCode != 200) {
        throw Error();
      }
      var data = response.body
          .replaceAll("[", "")
          .replaceAll("]", "")
          .replaceAll("=", ":");
      var decoded = jsonDecode(data.replaceRange(data.length - 2, null, "}"));
      var fixed = numberFormat.format(decoded['fisse'].toDouble());
      var variable = numberFormat.format(decoded['variabili'].toDouble());
      var total = numberFormat.format(decoded['totale'].toDouble());
      RGData rgData = RGData(fixed, variable, total);
      caches.add(CacheData(user, rgData));
    } catch (e, trace) {
      FLog.fatal(
        text: "Error getting rgdata for $user",
        exception: e,
        stacktrace: trace,
      );
    }
  }

  Future<bool> reloadUser(String user) async {
    FLog.info(text: "Reloading user $user");
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
    FLog.info(text: "Reloading all");
    var noError = true;
    for (var cache in caches) {
      noError &= await cache.reload();
    }
    EventManager.getInstance()
        .dispatchEvent(Event(name: "reload_page", data: noError));
    return noError;
  }
}
