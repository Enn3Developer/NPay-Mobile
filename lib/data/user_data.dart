import 'dart:convert';
import 'dart:io';

import 'package:f_logs/f_logs.dart';
import 'package:http/http.dart' as http;
import 'package:npay/data/cache.dart';
import 'package:npay/data/statement.dart';
import 'package:path_provider/path_provider.dart';

class Credentials {
  final String user;
  final String pass;

  const Credentials(this.user, this.pass);

  Future<bool> isValid() async {
    FLog.info(text: "Validating user $user");
    if (user != "" && pass != "") {
      try {
        var response = await http.get(Uri.parse(
            "https://rest.rgbcraft.com/npayapi/?richiesta=verifica&auth=$pass&utente=$user"));
        return response.statusCode == 200;
      } catch (_) {}
    }
    return false;
  }

  static Credentials fromString(String str) {
    final contents = str.split(":::");
    return Credentials(contents[0], contents[1]);
  }

  static Credentials empty() => const Credentials("", "");

  static Future<bool> checkUser(String user) async {
    FLog.info(text: "Checking user $user");
    try {
      var response = await http.get(Uri.parse(
          "https://rest.rgbcraft.com/npayapi/?richiesta=verifica&auth=pass_pRoVa_user_123456&utente=$user"));
      if (response.statusCode == 403) {
        // se qualcuno usa quella password allora F per lui e nessuno può inviargli soldi da NPay Mobile
        return jsonDecode(response.body)['detail'] == "Credenziali errate";
      }
    } catch (e) {
      FLog.fatal(text: "Error on checking", exception: e);
    }
    return false;
  }

  @override
  String toString() => "$user:::$pass";

  @override
  bool operator ==(Object other) =>
      other is Credentials && user == other.user && pass == other.pass;

  @override
  int get hashCode => Object.hash(user, pass);
}

class UserData {
  // È utile solo per evitare che io instanzia di nuovo questa classe per sbaglio
  UserData._internal(); // Elimina il costruttore di default e lo sostituisce con uno privato
  static final UserData _instance = UserData._internal();

  Set<Credentials> credentialsList = {};
  Set<String> phoneBook = {};
  String _defaultUser = "error_no_u_LEGO69";

  // Molto utile per accedere ai dati senza dover passare l'istanza per mezzo programma
  static UserData getInstance() => _instance;

  // È compito del resto del programma controllare che l'utente di default sia valido
  void setDefaultUser(String user) => _defaultUser = user;

  String get pass => getPass(_defaultUser);

  String get user => _defaultUser;

  String getPass(String user) {
    for (var credentials in credentialsList) {
      if (credentials.user == user) {
        return credentials.pass;
      }
    }
    return "error";
  }

  void removeDefaultUser() => _defaultUser = "error_no_u_LEGO69";

  bool containsUser(String user) {
    for (var credentials in credentialsList) {
      // Esiste solo un account con uno specifico nome
      // quindi è inutile cercare per due o più account
      if (credentials.user == user) {
        return true;
      }
    }
    return false;
  }

  Future<bool> addAccount(String user, String pass) =>
      addAccountFromCredentials(Credentials(user, pass));

  Future<bool> addAccountFromCredentials(Credentials credentials) async {
    FLog.info(text: "Adding account ${credentials.user}");
    if (!credentialsList.contains(credentials) && await credentials.isValid()) {
      Statement.getInstance().addUser(credentials.user);
      _defaultUser =
          _defaultUser == "error_no_u_LEGO69" ? credentials.user : _defaultUser;
      credentialsList.add(credentials);
      return true;
    }
    return false;
  }

  void removeAccount(String user) {
    FLog.info(text: "Removing account: $user");
    Statement.getInstance().removeUser(user);
    if (user == _defaultUser) {
      FLog.info(text: "User is default");
      removeDefaultUser();
    }
    for (int i = 0; i < credentialsList.length; i++) {
      if (credentialsList.elementAt(i).user == user) {
        credentialsList.remove(credentialsList.elementAt(i));
      }
    }
  }

  Future<bool> addToPhoneBook(String user) async {
    if (await Credentials.checkUser(user)) {
      phoneBook.add(user);
      return true;
    }
    return false;
  }

  void removeFromPhoneBook(String user) => phoneBook.remove(user);

  Future<void> saveCredentialsList() async {
    final file = File("${await _localPath}/credentials");
    await file.writeAsString("$_defaultUser\n${credentialsList.join("\n")}");
  }

  Future<void> loadCredentialsList() async {
    FLog.info(text: "Loading credentials");
    try {
      final file = File("${await _localPath}/credentials");
      final contents = await file.readAsString();
      final lines = contents.split("\n");
      for (int i = 1; i < lines.length; i++) {
        var credentials = Credentials.fromString(lines[i]);
        await addAccountFromCredentials(credentials);
        Cache.getInstance().addUser(credentials.user);
      }
      if (lines.isNotEmpty && await Credentials.checkUser(lines[0])) {
        _defaultUser = lines[0];
      }
      if (!containsUser(_defaultUser)) {
        _defaultUser = credentialsList.elementAt(0).user;
      }
    } catch (_) {}
  }

  Future<void> savePhoneBook() async {
    final file = File("${await _localPath}/phonebook");
    await file.writeAsString(phoneBook.join("\n"));
  }

  Future<void> loadPhoneBook() async {
    FLog.info(text: "Loading phonebook");
    try {
      final file = File("${await _localPath}/phonebook");
      final contents = await file.readAsString();
      for (var line in contents.split("\n")) {
        addToPhoneBook(line);
      }
    } catch (_) {}
  }

  Future<void> saveAll() async {
    await saveCredentialsList();
    await savePhoneBook();
    await Statement.getInstance().save();
  }

  Future<void> loadAll() async {
    await loadCredentialsList();
    await loadPhoneBook();
  }

  bool isValid() => _defaultUser.isNotEmpty && credentialsList.isNotEmpty;

  Future<String> get _localPath async =>
      (await getApplicationDocumentsDirectory()).path;
}
