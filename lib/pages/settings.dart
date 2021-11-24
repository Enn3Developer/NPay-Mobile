import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  SharedPreferences? pref;

  Future<void> getPref() async {
    pref = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (pref == null) {
      getPref();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Impostazioni"),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            titlePadding: const EdgeInsets.all(20),
            title: "Sync",
            tiles: [
              SettingsTile.switchTile(
                title: "Sincronizzazione iniziale",
                subtitle:
                    "Sincronizza automaticamente *tutti* gli account presenti",
                leading: const Icon(Icons.sync_rounded),
                switchValue: pref != null
                    ? pref!.getBool("all_account") ?? false
                    : false,
                onToggle: (value) =>
                    pref != null ? pref!.setBool("all_account", value) : false,
              ),
              SettingsTile.switchTile(
                title: "Sincronizzazione",
                subtitle:
                    "Sincronizza *tutti* gli account quando la sincronizzazione viene richiesta",
                leading: const Icon(Icons.cached_rounded),
                switchValue: pref != null
                    ? pref!.getBool("all_account_requested") ?? false
                    : false,
                onToggle: (value) => pref != null
                    ? pref!.setBool("all_account_requested", value)
                    : false,
              ),
            ],
          ),
          SettingsSection(
            titlePadding: const EdgeInsets.all(20),
            title: "Sicurezza",
            tiles: [
              SettingsTile.switchTile(
                title: "Impronta digitale",
                subtitle: "NON FUNZIONA PERCHÉ ANDROID FA SCHIFO",
                leading: const Icon(Icons.fingerprint_rounded),
                switchValue: pref != null
                    ? pref!.getBool("fingerprint") ?? false
                    : false,
                onToggle: (value) async {
                  var localAuth = LocalAuthentication();
                  if (pref != null) {
                    await pref!.setBool("fingerprint",
                        value && await localAuth.canCheckBiometrics);
                  }
                  setState(() {});
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
