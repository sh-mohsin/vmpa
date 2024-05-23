import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mp3_player/db/audio_box.dart';
import 'package:mp3_player/db/favorite_song_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> with AutomaticKeepAliveClientMixin<SongsScreen> {
  List<SongModel> songList = [];
  List<SongModel> folderList = [];
  List<String> pathList = [];
  List<String> folderNameList = [];
  List<Map<String, dynamic>> appSongList = [];
  bool isAudioPlaying = false;
  int currentlyPlayingIndex = -1;
  bool isFavorite = false;
  int currentItemIndex = 0;
  final _audioQuery = OnAudioQuery();
  final audioPlayer = AudioPlayer();
  late PlayerState playerState;
  List<CustomSongModel> favoriteSongs = [];
  int counter = 0;
  String? keyword = '';
  TextEditingController searchController = TextEditingController();

  Stream<PositionData> get _positionDataStream => Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(audioPlayer.positionStream, audioPlayer.bufferedPositionStream,
      audioPlayer.durationStream, (position, bufferPosition, duration) => PositionData(position, bufferPosition, duration ?? Duration.zero));

  @override
  void initState() {
    super.initState();
    // favoriteBox.clear();
    // audioBox.clear();
    _initPermissions();
  }

  playSong(String? uri) async {
    try {
      audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri!)));
      // Listen to the player position stream to get updates on playback progress
      audioPlayer.playerStateStream.listen((PlayerState state) {
        // Handle the playback position updates here
        setState(() {
          playerState = state;
        });
        if (kDebugMode) {
          print('Current position: $state');
        }
      });
      await audioPlayer.play();
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  void _initPermissions() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      await Permission.manageExternalStorage.request().isGranted.whenComplete(() {
        try {
          audioBox.clear();
          CustomSongModel customSongModel = CustomSongModel();
          _audioQuery.permissionsRequest().whenComplete(() async {
            if (kDebugMode) {
              print('permissions granted');
            }
            _audioQuery
                .querySongs(
              uriType: UriType.EXTERNAL,
            )
                .then((value) {
              // print('audioList: ${value.toList().first}');
              setState(() {
                songList.clear();
                songList = value.toList();
                for (var songs in songList) {
                  if (kDebugMode) {
                    print('songs: ${songs.data}');
                  }
                  customSongModel = CustomSongModel(title: songs.displayNameWOExt, artistName: songs.artist.toString(), audioPath: songs.data, isFavorite: false);
                  Map<String, dynamic> audioMap = {
                    'title': customSongModel.title,
                    'artistName': customSongModel.artistName,
                    'isFavorite': customSongModel.isFavorite,
                    'audioPath': customSongModel.audioPath,
                  };
                  if (kDebugMode) {
                    print('audioMap: $audioMap');
                  }
                  if (!audioBox.values.contains(customSongModel)) {
                    if (kDebugMode) {
                      print('song not yet added');
                    }
                    setState(() {
                      audioBox.add(audioMap);
                      refreshItems();
                    });
                  } else {
                    if (kDebugMode) {
                      print('song already added');
                    }
                  }
                }
              });
            });
            pathList = await _audioQuery.queryAllPath();
            for (var element in pathList) {
              String lastWord = extractLastWord(element);
              folderNameList.add(lastWord);
              folderList = await _audioQuery.querySongs(path: element);
            }
          });

          // print('_audioQuery: ${_audioQuery.queryAllPath()}');
        } catch (e) {
          if (kDebugMode) {
            print('exception: ${e.toString()}');
          }
        }
      });
    } else {
      audioBox.clear();
      try {
        CustomSongModel customSongModel = CustomSongModel();
        _audioQuery.permissionsRequest().whenComplete(() async {
          if (kDebugMode) {
            print('permissions granted');
          }
          _audioQuery
              .querySongs(
            uriType: UriType.EXTERNAL,
          )
              .then((value) {
            // print('audioList: ${value}');
            setState(() {
              songList.clear();
              songList = value.toList();
              for (var songs in songList) {
                if (kDebugMode) {
                  print('songsElse: ${songs.data}');
                }
                customSongModel = CustomSongModel(title: songs.displayNameWOExt, artistName: songs.artist, audioPath: songs.data, isFavorite: false);

                Map<String, dynamic> audioMap = {
                  'title': customSongModel.title,
                  'artistName': customSongModel.artistName,
                  'isFavorite': customSongModel.isFavorite,
                  'audioPath': customSongModel.audioPath,
                };
                if (kDebugMode) {
                  print('audioMap: $audioMap');
                }
                if (!audioBox.values.contains(customSongModel)) {
                  if (kDebugMode) {
                    print('song not yet added');
                  }
                  setState(() {
                    audioBox.add(audioMap);
                  });
                } else {
                  if (kDebugMode) {
                    print('song already added');
                  }
                }
              }
              if (kDebugMode) {
                print('myList: ${audioBox.keys.map((key) {
                  var value = audioBox.get(key);
                  // print('audioValue: ${value}');
                  return {
                    "key": key,
                    "title": value['title'],
                    "artistName": value['artistName'],
                    "isFavorite": value['isFavorite'],
                    "audioPath": value['audioPath'],
                  };
                }).toList()}');
              }
            });
          });
          pathList = await _audioQuery.queryAllPath();
          for (var element in pathList) {
            String lastWord = extractLastWord(element);
            folderNameList.add(lastWord);
            folderList = await _audioQuery.querySongs(path: element);
            // print('folderName: ${lastWord}');
            // print('foldersSongs: $folderList');
          }
          // print('folderNameList: $folderNameList');
          // print('pathList: $pathList}');
        });

        // print('_audioQuery: ${_audioQuery.queryAllPath()}');
      } catch (e) {
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

  playSongs(int index) async {
    try {
      audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(appSongList[index]['audioPath'])));
      // ... rest of your method
    } on Exception catch (e) {
      // ... error handling
    }
  }

  playNext() {
    if (currentlyPlayingIndex < appSongList.length - 1) {
      int nextIndex = currentlyPlayingIndex + 1;
      playSongs(nextIndex);
      setState(() {
        currentlyPlayingIndex = nextIndex;
      });
    }
  }

  playPrevious() {
    if (currentlyPlayingIndex > 0) {
      int previousIndex = currentlyPlayingIndex - 1;
      playSongs(previousIndex);
      setState(() {
        currentlyPlayingIndex = previousIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: TextFormField(
              controller: searchController,
              onChanged: (String value) {
                setState(() {
                  keyword = value;
                });
              },
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.purple, width: 2))),
            ),
          ),
          songList.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: appSongList.length,
                    itemBuilder: (context, index) {
                      final isCurrentlyPlaying = index == currentlyPlayingIndex;
                      // var currentBox = box.getAt(index);
                      print('currentBox: ${appSongList[index]['audioPath'].toString()}');
                      if (keyword.toString().toLowerCase().contains(appSongList[index]['title'].toString().toLowerCase())) {
                        return Container(
                          height: 100,
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appSongList[index]['title'],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      Text(appSongList[index]['artistName'].toString()),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                        onPressed: () async {
                                          print('audioPath: ${appSongList[index]['audioPath']}');
                                          await Share.shareFiles([appSongList[index]['audioPath'].toString()]);
                                        },
                                        icon: const Icon(Icons.share)),
                                    GestureDetector(
                                      onTap: () async {
                                        if (isCurrentlyPlaying) {
                                          setState(() {
                                            currentlyPlayingIndex = -1; // Reset to -1 to indicate no audio is playing
                                          });
                                          await audioPlayer.pause();
                                        } else {
                                          print('audioPath: ${appSongList[index]['audioPath']}');
                                          // playSong(appSongList[index]['audioPath']);
                                          playSongs(index);
                                          setState(() {
                                            currentlyPlayingIndex = index; // Update the currently playing index
                                            isAudioPlaying = true;
                                          });
                                        }
                                      },
                                      child: isCurrentlyPlaying
                                          ? Icon(
                                              Icons.pause_circle,
                                              size: 35.r,
                                              color: Colors.green,
                                            )
                                          : Icon(
                                              Icons.play_circle,
                                              size: 35.r,
                                              color: Colors.orangeAccent,
                                            ),
                                    ),
                                    // ClipRRect(
                                    //   borderRadius: BorderRadius.circular(100),
                                    //   child: Material(
                                    //     color: Colors.transparent,
                                    //     child: IconButton(
                                    //         style: const ButtonStyle(
                                    //             backgroundColor: MaterialStatePropertyAll(Colors.grey)
                                    //         ),
                                    //         onPressed: (){
                                    //           setState(() {
                                    //             isFavorite = !isFavorite; // Toggle the favorite state
                                    //           });
                                    //           CustomSongModel customModel = CustomSongModel(
                                    //               title: songList[index].title ?? '',
                                    //               artistName: songList[index].artist ?? '',
                                    //               isFavorite: true,
                                    //               audioPath: songList[index].data ?? ''
                                    //           );
                                    //           FavoriteSong model = FavoriteSong(
                                    //               songName: songList[index].title ?? '',
                                    //               songDescription: songList[index].artist ?? '',
                                    //               isFavorite: true,
                                    //               audioPath: songList[index].data ?? ''
                                    //           );
                                    //           saveToDb(index, customModel);
                                    //           addToFavoriteSongs(model);
                                    //           refreshItems();
                                    //         },
                                    //         icon: Icon(appSongList[index]['isFavorite'] ? Icons.favorite : Icons.favorite_outline_rounded, )),
                                    //   ),
                                    // )
                                    IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_rounded))
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }
                      return Container(
                        height: 100,
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appSongList[index]['title'],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    Text(appSongList[index]['artistName'].toString()),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                      onPressed: () async {
                                        print('audioPath: ${appSongList[index]['audioPath']}');
                                        await Share.shareFiles([appSongList[index]['audioPath'].toString()]);
                                      },
                                      icon: const Icon(Icons.share)),
                                  GestureDetector(
                                    onTap: () async {
                                      if (isCurrentlyPlaying) {
                                        setState(() {
                                          currentlyPlayingIndex = -1; // Reset to -1 to indicate no audio is playing
                                        });
                                        await audioPlayer.pause();
                                      } else {
                                        print('audioPath: ${appSongList[index]['audioPath']}');
                                        // playSong(appSongList[index]['audioPath']);
                                        playSongs(index);
                                        setState(() {
                                          currentlyPlayingIndex = index; // Update the currently playing index
                                          isAudioPlaying = true;
                                        });
                                      }
                                    },
                                    child: isCurrentlyPlaying
                                        ? Icon(
                                            Icons.pause_circle,
                                            size: 35.r,
                                            color: Colors.green,
                                          )
                                        : Icon(
                                            Icons.play_circle,
                                            size: 35.r,
                                            color: Colors.orangeAccent,
                                          ),
                                  ),
                                  PopupMenuButton(
                                    onSelected: (value) {
                                      // your logic
                                    },
                                    itemBuilder: (BuildContext bc) {
                                      return [
                                        PopupMenuItem(
                                          value: '/create_playlist',
                                          onTap: () {
                                            showAdaptiveDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    backgroundColor: Colors.transparent,
                                                    content: Container(
                                                      height: 170,
                                                      padding: EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(10)
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          Text('Create Playlist'),
                                                          SizedBox(
                                                            height: 10,
                                                          ),
                                                          TextFormField(
                                                            decoration: InputDecoration(
                                                                contentPadding: EdgeInsets.zero,
                                                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey))),
                                                          ),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                            children: [
                                                              OutlinedButton(
                                                                  onPressed: () {},
                                                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                                                  child: const Text('Cancel', style: TextStyle(color: Colors.white))),
                                                              OutlinedButton(
                                                                  onPressed: () {},
                                                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                                                  child: const Text('Create', style: TextStyle(color: Colors.white),))
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                });
                                          },
                                          child: const Text("Create Playlist"),
                                        ),
                                        const PopupMenuItem(
                                          value: '/add_to_playlist',
                                          child: Text("Add to Playlist"),
                                        ),
                                        // PopupMenuItem(
                                        //   child: Text("Contact"),
                                        //   value: '/contact',
                                        // )
                                      ];
                                    },
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                )
              : const Expanded(
                  child: Center(
                  child: CircularProgressIndicator(),
                )),
          isAudioPlaying
              ? Container(
                  height: 100,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      StreamBuilder<PositionData>(
                          stream: _positionDataStream,
                          builder: (context, snapshot) {
                            final positionData = snapshot.data;
                            return Column(
                              children: [
                                ProgressBar(
                                  progress: positionData?.position ?? Duration.zero,
                                  buffered: positionData?.bufferPosition ?? Duration.zero,
                                  total: positionData?.duration ?? Duration.zero,
                                  onSeek: audioPlayer.seek,
                                ),
                              ],
                            );
                          }),
                      StreamBuilder<PlayerState>(
                          stream: audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState = playerState?.processingState;
                            final playing = playerState?.playing ?? false;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: playPrevious,
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    size: 30,
                                  ),
                                ),
                                if (!playing)
                                  IconButton(
                                    onPressed: audioPlayer.play,
                                    icon: const Icon(Icons.play_circle, size: 35),
                                  )
                                else if (processingState != ProcessingState.completed)
                                  IconButton(
                                    onPressed: audioPlayer.pause,
                                    icon: const Icon(Icons.pause_rounded, size: 35),
                                  ),
                                IconButton(
                                  onPressed: playNext,
                                  icon: const Icon(Icons.skip_next, size: 30),
                                ),
                              ],
                            );
                          }),
                    ],
                  ),
                )
              : const SizedBox()
        ],
      ),
    );
  }

  void addToFavoriteSongs(FavoriteSong audioModel) async {
    print('favorite called');

    // favoriteBox = await Hive.openBox('favoriteSongsBox'); // Open the Hive box if not already opened
    // Check if the song is already in the favorites list
    if (!favoriteBox.values.contains(audioModel)) {
      print('song added');
      await favoriteBox.add(audioModel); // Save the song to the 'favoriteSongsBox' Hive box
      refreshItems();
    } else {
      print('song already added');
    }

    // await favoriteBox.close(); // Close the box when done (or do it in your widget's dispose method)

    // Refresh your UI or update any other relevant logic
    // Note: You don't need to call setState here since Hive is asynchronous
  }

// Update a single item

  Future<void> saveToDb(int itemKey, CustomSongModel model) async {
    Map<String, dynamic> imageMap = {
      'key': itemKey,
      'title': model.title,
      'artistName': model.artistName,
      'isFavorite': model.isFavorite,
      'audioPath': model.audioPath,
    };
    if (!audioBox.values.contains(model)) {
      await audioBox.putAt(itemKey, imageMap); // Save the song to the 'favoriteSongsBox' Hive box
      refreshItems();
    }

    refreshItems(); // Update the UI
  }

  Future<void> refreshItems() async {
    appSongList = audioBox.keys.map((key) {
      var value = audioBox.get(key);
      print('audioValue: ${value}');
      return {
        "key": key,
        "title": value['title'],
        "artistName": value['artistName'],
        "isFavorite": value['isFavorite'],
        "audioPath": value['audioPath'],
      };
    }).toList();
    // print('audioSong: ${audioBox.length}');

    var favoriteSongs = favoriteBox.values.toList(); // Assuming 'favoriteBox' contains 'FavoriteSong' objects
    List<Map<String, dynamic>> songList = favoriteSongs.map((song) {
      print('songName: ${song.songName}');
      return {
        "songName": song.songName,
        "songDescription": song.songDescription,
        "isFavorite": song.isFavorite,
        "audioPath": song.audioPath,
      };
    }).toList();
    print('favoriteSongs: $songList');
    setState(() {});
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class PositionData {
  final Duration position;
  final Duration bufferPosition;
  final Duration duration;

  const PositionData(this.position, this.bufferPosition, this.duration);
}

class CustomSongModel {
  String? title;
  String? artistName;
  String? audioPath;
  bool? isFavorite;
  CustomSongModel({this.title, this.artistName, this.audioPath, this.isFavorite});
}
