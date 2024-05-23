import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mp3_player/db/audio_model.dart';
import 'package:mp3_player/db/favorite_song_model.dart';
import 'package:mp3_player/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/adapters.dart';
import 'db/audio_box.dart';
late final SharedPreferences preferences;
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();  //Initialized HIVE DB
  Hive.registerAdapter(AudioModelAdapter()); /// Registered Adapters
  Hive.registerAdapter(FavoriteSongAdapter());/// Registered Adapters
  audioBox = await Hive.openBox('songsBox');
  favoriteBox = await Hive.openBox('favoriteSongsBox');
  preferences = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      // Use builder only if you need to use library outside ScreenUtilInit context
      builder: (_ , child) {
        return GetMaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
            useMaterial3: false,
          ),
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}

