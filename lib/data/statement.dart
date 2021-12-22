import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:http/http.dart' as http;
import 'package:npay/data/user_data.dart';
import 'package:path_provider/path_provider.dart';

class _Statement {
  final List<String> _statementIn = List.empty(growable: true);
  final List<String> _statementOut = List.empty(growable: true);
  final String user;

  _Statement({required this.user});

  factory _Statement.fromJson(dynamic json) {
    var statement = _Statement(user: json['user']);
    json['in'].forEach((element) {
      statement._statementIn.add(element);
    });
    json['out'].forEach((element) {
      statement._statementOut.add(element);
    });
    return statement;
  }

  Map<String, dynamic> toJson() =>
      {'user': user, 'in': _statementIn, 'out': _statementOut};

  List<String> get statementIn => _statementIn;

  List<String> get statementOut => _statementOut;

  bool listSubsetOfList<T>(List<T> a, List<T> b) {
    var isIn = true;
    for (var element in a) {
      isIn &= b.contains(element);
    }
    return isIn;
  }

  List<int> getDiff<T>(List<T> a, List<T> b) {
    List<int> indexes = List.empty(growable: true);
    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  void compareAndAdjust(List<String> tempIn, List<String> tempOut) {
    if (!listSubsetOfList(tempIn, _statementIn)) {
      var indexes = getDiff(tempIn, _statementIn);
      for (var index in indexes) {
        _statementIn.add(tempIn[index]);
      }
    }
    if (!listSubsetOfList(tempOut, _statementOut)) {
      var indexes = getDiff(tempOut, _statementOut);
      for (var index in indexes) {
        _statementOut.add(tempOut[index]);
      }
    }
  }

  Future<bool> reload() async {
    try {
      var response = await http.get(Uri.parse(
          "https://sunfire.a-centauri.com/npayapi/?richiesta=estratto&auth=${UserData.getInstance().getPass(user)}&utente=$user"));
      if (response.statusCode == 200) {
        List<String> tempIn = List.empty(growable: true);
        List<String> tempOut = List.empty(growable: true);
        var decoded = jsonDecode(response.body);
        // Vanno usati due cicli for per evitare bug stupidi con account "nuovi"
        for (int i = 1; i <= decoded['in'].length; i++) {
          if (decoded['in']['$i'].toString().isNotEmpty) {
            tempIn.add(decoded['in']['$i']);
          }
        }
        for (int i = 1; i <= decoded['out'].length; i++) {
          if (decoded['out']['$i'].toString().isNotEmpty) {
            tempOut.add(decoded['out']['$i']);
          }
        }
        compareAndAdjust(tempIn, tempOut);
        return true;
      }
    } catch (e, trace) {
      FLog.fatal(
          text: "Error reloading statements for $user",
          exception: e,
          stacktrace: trace);
    }
    return false;
  }
}

class Statement {
  Statement._internal();

  static final Statement _instance = Statement._internal();

  final List<_Statement> _statements = List.empty(growable: true);

  static Statement getInstance() => _instance;

  _Statement getUser(String user) {
    for (var statement in _statements) {
      if (statement.user == user) {
        return statement;
      }
    }
    var statement = _Statement(user: user);
    _statements.add(statement);
    return statement;
  }

  void addUser(String user) => _statements.add(_Statement(user: user));

  void removeUser(String user) {
    for (var statement in _statements) {
      if (statement.user == user) {
        _statements.remove(statement);
      }
    }
  }

  Future<void> reloadAll() async {
    for (var statement in _statements) {
      await statement.reload();
    }
    await save();
  }

  Future<void> reloadUser(String user) async {
    for (var statement in _statements) {
      if (statement.user == user) {
        await statement.reload();
      }
    }
    await save();
  }

  Future<void> save() async {
    // var file = File("${await _localPath}/statements");
    // var contents = jsonEncode(_statements);
    // await file.writeAsString(contents);
  }

  Future<void> load() async {
    // try {
    //   var file = File("${await _localPath}/statements");
    //   var contents = await file.readAsString();
    //   var statements = jsonDecode(contents);
    //   for (var statement in statements) {
    //     _statements.add(_Statement.fromJson(statement));
    //   }
    // } catch (e, trace) {
    //   FLog.severe(
    //       text: "Cannot load statements", exception: e, stacktrace: trace);
    // }
  }

  Future<String> get _localPath async =>
      (await getApplicationDocumentsDirectory()).path;
}
