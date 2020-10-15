import '../../game/game_barrel.dart';

import '../../appsettings/settings_barrel.dart';
import '../../core/inapp/inapp_barrel.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

import '../core_barrel.dart';

class InAppModule extends AbstractModule {
  static final InAppModule _instance = InAppModule._init();

  InAppModule._init() : super();

  factory InAppModule() {
    return _instance;
  }

  @override
  void configure(Injector injector) {
    injector.map<InAppRepo>((i) => InAppRepo(GameModule().get<GameProvider>(), SettingsModule().get<SettingsRepo>()), isSingleton: true);
  }
}
