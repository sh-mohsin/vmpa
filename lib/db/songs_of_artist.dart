
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

import '../songs_screen.dart';

class SongsOfArtist extends StatefulWidget {
  final int artistId;
  final String artistTitle;
  const SongsOfArtist({super.key, required this.artistId, required this.artistTitle});

  @override
  State<SongsOfArtist> createState() => _SongsOfArtistState();
}

class _SongsOfArtistState extends State<SongsOfArtist> {
  final _audioQuery = OnAudioQuery();
  final audioPlayer = AudioPlayer();
  List<SongModel> artistSongs = [];
  int currentlyPlayingIndex = -1;
  late PlayerState playerState;
  bool isAudioPlaying = false;

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          audioPlayer.positionStream,
          audioPlayer.bufferedPositionStream,
          audioPlayer.durationStream, (position, bufferPosition, duration) =>
          PositionData(position, bufferPosition, duration ?? Duration.zero)
      );

  playSongs(int index) async {
    try {
      audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(artistSongs[index].uri.toString())));
      // ... rest of your method
    } on Exception catch (e) {
      // ... error handling
    }
  }

  playNext() {
    if (currentlyPlayingIndex < artistSongs.length - 1) {
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
  void initState() {
    super.initState();

    fetchArtistSongs();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text( widget.artistTitle ?? 'Artist'),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [
            Expanded(child:
            artistSongs.isNotEmpty ? ListView.builder(
              itemCount: artistSongs.length,
                itemBuilder: (context, index){
                  final isCurrentlyPlaying = index == currentlyPlayingIndex;
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
                              Text(artistSongs[index].title ?? '', overflow: TextOverflow.ellipsis,
                                maxLines: 2,),
                              Text(artistSongs[index].artist.toString()),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(onPressed: () async{
                              print('audioPath: ${artistSongs[index].uri}');
                              await Share.shareFiles([artistSongs[index].uri.toString()]);
                            }, icon: const Icon(Icons.share)),
                            GestureDetector(
                              onTap: () async {
                                if (isCurrentlyPlaying) {
                                  setState(() {
                                    currentlyPlayingIndex = -1; // Reset to -1 to indicate no audio is playing
                                  });
                                  await audioPlayer.pause();
                                } else {
                                  print('audioPath: ${artistSongs[index].uri ?? "empty"}');
                                  //playSong(artistSongs[index].uri);
                                  playSongs(index);
                                  setState(() {
                                    currentlyPlayingIndex = index; // Update the currently playing index
                                    isAudioPlaying = true;
                                  });
                                }
                              },
                              child: isCurrentlyPlaying
                                  ? Icon(Icons.pause_circle, size: 35.r, color: Colors.green,)
                                  : Icon(Icons.play_circle, size: 35.r, color: Colors.orangeAccent,),
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
                            //           // setState(() {
                            //           //   isFavorite = !isFavorite; // Toggle the favorite state
                            //           // });
                            //           // CustomSongModel customModel = CustomSongModel(
                            //           //     title: songList[index].title ?? '',
                            //           //     artistName: songList[index].artist ?? '',
                            //           //     isFavorite: true,
                            //           //     audioPath: songList[index].data ?? ''
                            //           // );
                            //           // FavoriteSong model = FavoriteSong(
                            //           //     songName: songList[index].title ?? '',
                            //           //     songDescription: songList[index].artist ?? '',
                            //           //     isFavorite: true,
                            //           //     audioPath: songList[index].data ?? ''
                            //           // );
                            //           // saveToDb(index, customModel);
                            //           // addToFavoriteSongs(model);
                            //           // refreshItems();
                            //         },
                            //         icon: Icon(artistSongs[index]['isFavorite'] ? Icons.favorite : Icons.favorite_outline_rounded, )),
                            //   ),
                            // )
                          ],
                        ),
                      )
                    ],
                  ),
                );
                })
                : const Center(child: CircularProgressIndicator(),)),
            isAudioPlaying ? Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                  color: Colors.white
              ),
              child: Column(
                children: [
                  StreamBuilder<PositionData>(
                      stream: _positionDataStream,
                      builder: (context, snapshot){
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
                      builder: (context, snapshot){
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing ?? false;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: playPrevious,
                              icon: const Icon(Icons.skip_previous, size: 30,),
                            ),

                            if(!playing)
                              IconButton(
                                onPressed: audioPlayer.play,
                                icon: const Icon(Icons.play_circle, size: 35),
                              )
                            else if(processingState != ProcessingState.completed)
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
            ) : const SizedBox()
          ],
        ),
      ),
    );
  }

  Future<void> fetchArtistSongs() async {
    _audioQuery.querySongs(
      uriType: UriType.EXTERNAL,
    ).then((value) {
      print('audioList: ${value.toList().first}');
      setState(() {
        List<SongModel> audioList = value.toList();
        for(var songs in audioList){
          if(songs.artistId == widget.artistId){
            artistSongs.add(SongModel({
              "artist_id" : songs.artistId,
              "artist" : songs.artist,
              "title" : songs.title,
              '_uri': songs.uri,
            }));
            print('artist_IDs: ${songs.artistId}');
          }
        }
        // var seenint = Set<int>();
        // List<SongModel> uniqueArtists = albumList.where((numone) => seenint.add(numone.albumId!)).toList();
        // albumList = uniqueArtists;
        print('artListLength: ${artistSongs.length}');
      });
    });
  }

  playSong(String? uri)async{
    try{
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

    }on Exception catch (e){
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

}
