import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mp3_player/songs_of_album.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<SongModel> songList = [];
  List<SongModel> albumList = [];
  List<SongModel> folderList = [];
  List<String> pathList = [];
  List<String> folderNameList = [];
  bool audioIsPlaying = false;
  int currentlyPlayingIndex = -1;
  final _audioQuery = OnAudioQuery();
  final audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  playSong(String? uri)async{
    try{
      audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri!)));
      await audioPlayer.play();
    }on Exception catch (e){
      print(e.toString());
    }
  }

  void _initPermissions() async{
    if(!await Permission.manageExternalStorage.request().isGranted){
      await Permission.manageExternalStorage.request().isGranted.whenComplete(() {
        try{
          _audioQuery.permissionsRequest().whenComplete(() async{
            print('permissions granted');
            _audioQuery.querySongs(
              uriType: UriType.EXTERNAL,
            ).then((value) {
              print('audioList: ${value.toList().first}');
              setState(() {
                songList.clear();
                songList = value.toList();
                for(var artists in songList){
                  albumList.add(SongModel({
                    "album_id" : artists.albumId,
                    "album" : artists.album,

                  }));
                  print('artist_IDs: ${artists.albumId}');
                }
                var seenint = Set<int>();
                List<SongModel> uniqueArtists = albumList.where((numone) => seenint.add(numone.albumId!)).toList();
                albumList = uniqueArtists;
                print('artListLength: ${albumList.length}');
              });
            });
            pathList = await _audioQuery.queryAllPath();
            for(var element in pathList){
              String lastWord = extractLastWord(element);
              folderNameList.add(lastWord);
              folderList = await _audioQuery.querySongs(path: element);
              print('folderName: ${lastWord}');
              print('foldersSongs: $folderList');
            }
            print('folderNameList: $folderNameList');
            print('pathList: $pathList}');
          });

          // print('_audioQuery: ${_audioQuery.queryAllPath()}');
        }catch (e){
          print('exception: ${e.toString()}');
        }
      });
    }else {
      try{
        _audioQuery.permissionsRequest().whenComplete(() async{
          print('permissions granted');
          _audioQuery.querySongs(
            uriType: UriType.EXTERNAL,
          ).then((value) {
            print('audioList: ${value.toList().first}');
            setState(() {
              songList = value.toList();
            });
          });
          pathList = await _audioQuery.queryAllPath();
          for(var element in pathList){
            String lastWord = extractLastWord(element);
            folderNameList.add(lastWord);
            folderList = await _audioQuery.querySongs(path: element);
            print('folderName: ${lastWord}');
            print('foldersSongs: $folderList');
          }
          print('folderNameList: $folderNameList');
          print('pathList: $pathList}');
        });

        // print('_audioQuery: ${_audioQuery.queryAllPath()}');
      }catch (e){
        print('exception: ${e.toString()}');
      }

    }
  }

  String extractLastWord(String text) {
    // Split the text by '/' to get segments
    List<String> segments = text.split('/');

    // Filter out empty segments (e.g., if there are multiple '/' characters)
    List<String> nonEmptySegments = segments.where((segment) => segment.isNotEmpty).toList();

    // Check if there are any segments
    if (nonEmptySegments.isNotEmpty) {
      // Return the last segment, which is the last word in this context
      return nonEmptySegments.last;
    } else {
      // If there are no non-empty segments, return an empty string
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          albumList.isNotEmpty ? Expanded(
            child: ListView.builder(
                itemCount: albumList.length,
                itemBuilder: (context, index){
                  final isCurrentlyPlaying = index == currentlyPlayingIndex;
                  return ListTile(
                    onTap: (){
                      print("SongPath ${albumList[index].albumId}");
                      Get.to(() => SongsOfAlbum(albumId: albumList[index].albumId ?? 0, albumTitle: albumList[index].album ?? ''));
                      // playSong(albumList[index].uri);
                    },
                    title: Text(albumList[index].album.toString()),
                    // trailing: GestureDetector(
                    //   onTap: () async {
                    //     if (isCurrentlyPlaying) {
                    //       setState(() {
                    //         currentlyPlayingIndex = -1; // Reset to -1 to indicate no audio is playing
                    //       });
                    //       await audioPlayer.pause();
                    //     } else {
                    //       playSong(songList[index].uri);
                    //       setState(() {
                    //         currentlyPlayingIndex = index; // Update the currently playing index
                    //       });
                    //     }
                    //   },
                    //   child: isCurrentlyPlaying
                    //       ? Icon(Icons.pause_circle, size: 35.r, color: Colors.green,)
                    //       : Icon(Icons.play_circle, size: 35.r, color: Colors.orangeAccent,),
                    // ),
                  );
                }),
          ) : const Center(child: CircularProgressIndicator(),),
        ],
      ),
    );
  }
}
