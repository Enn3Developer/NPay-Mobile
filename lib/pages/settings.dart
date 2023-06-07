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
            margin: const EdgeInsetsDirectional.all(20),
            title: const Text("Sync"),
            tiles: [
              SettingsTile.switchTile(
                  title: const Text("Sincronizzazione iniziale"),
                  description:
                      const Text("Sincronizza automaticamente *tutti* gli account presenti"),
                  leading: const Icon(Icons.sync_rounded),
                  enabled: pref != null
                      ? pref!.getBool("all_account") ?? false
                      : false,
                  onToggle: (value) => setState(() {
                        pref != null
                            ? pref!.setBool("all_account", value)
                            : false;
                      }), initialValue: false,),
              SettingsTile.switchTile(
                  title: const Text("Sincronizzazione"),
                  description:
                      const Text("Sincronizza *tutti* gli account quando la sincronizzazione viene richiesta"),
                  leading: const Icon(Icons.cached_rounded),
                  enabled: pref != null
                      ? pref!.getBool("all_account_requested") ?? false
                      : false,
                  onToggle: (value) => setState(() {
                        pref != null
                            ? pref!.setBool("all_account_requested", value)
                            : false;
                      }), initialValue: false,),
            ],
          ),
          SettingsSection(
            margin: const EdgeInsetsDirectional.all(20),
            title: const Text("Sicurezza"),
            tiles: [
              SettingsTile.switchTile(
                title: const Text("Impronta digitale"),
                description: const Text("Login con impronta digitale"),
                leading: const Icon(Icons.fingerprint_rounded),
                enabled: pref != null
                    ? pref!.getBool("fingerprint") ?? false
                    : false,
                onToggle: (value) async {
                  var localAuth = LocalAuthentication();
                  if (pref != null) {
                    await pref!.setBool("fingerprint",
                        value && await localAuth.canCheckBiometrics);
                  }
                  setState(() {});
                }, initialValue: false,
              ),
            ],
          )
        ],
      ),
    );
  }
}
