import 'dart:async';
import 'dart:developer';

import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:npay/data/cache.dart';
import 'package:npay/data/statement.dart';
import 'package:npay/data/user_data.dart';
import 'package:npay/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/npay_color.dart';

class LoginPage extends StatefulWidget {
  final bool autoLogin;

  const LoginPage({Key? key, required this.autoLogin}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  List<Widget> list = List.empty(growable: true);

  var isError = false;
  var loadPage = false;
  var isLoading = false;

  Future<void> login() async {
    var userData = UserData.getInstance();
    if (await userData.addAccount(userController.text, passController.text)) {
      await Cache.getInstance().addUser(userData.user);
      var pref = await SharedPreferences.getInstance();
      pref.getBool("all_account") ?? false
          ? await Cache.getInstance().reloadAll()
          : await Cache.getInstance().reloadUser(userData.user);
      await userData.loadPhoneBook();
      userData.saveAll();
      log("userData.user: ${userData.user}");
      setState(() {
        FLog.info(text: "Logging in");
        isError = false;
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomePage()), (r) => false);
      });
    } else {
      setState(() {
        isError = true;
      });
    }
  }

  void autoLogin(BuildContext context) async {
    UserData userData = UserData.getInstance();
    await userData.loadAll();
    if (userData.isValid()) {
      await Statement.getInstance().load();
      bool authenticated = true;
      var pref = await SharedPreferences.getInstance();
      if (pref.getBool("fingerprint") ?? false) {
        try {
          log("Trying to get fingerprint");
          var localAuth = LocalAuthentication();
          if (await localAuth.canCheckBiometrics) {
            log("Can check biometrics");
            authenticated = await localAuth.authenticate(
              localizedReason: "Autenticati per accedere al tuo account",
              options: const AuthenticationOptions(
                stickyAuth: true,
                useErrorDialogs: true,
              ),
            );
          }
        } catch (_) {}
      }
      if (authenticated) {
        log("Authenticated");
        pref.getBool("all_account") ?? false
            ? await Cache.getInstance().reloadAll()
            : await Cache.getInstance().reloadUser(userData.user);
        userData.saveAll();
        setState(() {
          FLog.info(text: "Auto logging in");
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (r) => false);
        });
      }
    } else {
      setState(() {
        loadPage = true;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  void getPage() {
    if (loadPage) {
      FLog.info(text: "Rendering page");
      list = [
        Container(
          height: 150.0,
          width: 190.0,
          padding: const EdgeInsets.only(top: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(200),
          ),
          child: Center(
            child: Image.asset("asset/images/nPayLogo.png"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: userController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Username",
              hintText: "Immetti il tuo username di NPay",
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: passController,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Password",
              hintText: "Immetti la tua password di NPay",
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: FractionallySizedBox(
            widthFactor: 0.85,
            child: ElevatedButton.icon(
              autofocus: true,
              onPressed: login,
              icon: const Icon(
                Icons.login_rounded,
                color: Colors.white,
              ),
              label: const Text(
                "Login",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Visibility(
            visible: isError,
            child: RichText(
              text: TextSpan(
                children: [
                  WidgetSpan(
                    child: Icon(
                      Icons.error_rounded,
                      size: 20,
                      color: redColor,
                    ),
                  ),
                  TextSpan(
                    text: " Credenziali Errate",
                    style: TextStyle(
                      color: redColor,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Registrazione"),
                  content: Text("Entra sul server per registrare un account"),
                );
              },
            );
          },
          child: const Text("Nuovo utente? Crea un account"),
        ),
      ];
      setState(() {
        loadPage = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoLogin) {
      setState(() {
        autoLogin(context);
        isLoading = true;
      });
    }
    list = [
      const Center(
          child: Padding(
        padding: EdgeInsets.only(top: 5),
        child: CircularProgressIndicator(),
      ))
    ];
  }

  @override
  Widget build(BuildContext context) {
    loadPage = !isLoading;
    getPage();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: ListView(
          children: list,
        ),
      ),
    );
  }
}
