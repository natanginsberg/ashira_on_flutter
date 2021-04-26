import 'dart:async';
import 'dart:convert';

import 'package:ashira_flutter/model/Line.dart';
import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/utils/Parser.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// List<CameraDescription> cameras;

class Sing extends StatefulWidget {
  final Song song;

  Sing(this.song);

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _SingState createState() => _SingState(song);
}

class _SingState extends State<Sing> with WidgetsBindingObserver {
  Song song;
  AudioCache audioCache = AudioCache();
  AudioPlayer audioPlayer = AudioPlayer();
  bool loading = false;

  List<Line> lines = [];

  late Future parseFuture;

  final ScrollController listViewController = new ScrollController();
  int i = 0;

  bool isPlaying = false;

  late Timer timer;

  _SingState(this.song);

  double _progressValue = 0.0;
  int songLength = 0;
  int updateCounter = 0;

  @override
  Future<void> dispose() async {
    // TODO: implement dispose
    int result = await audioPlayer.stop();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    parseFuture = _parseLines();
    _progressValue = 0.0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      //stop your audio player
      pause();
      timer.cancel();
    }
    // } else if (state == AppLifecycleState.resumed) {
    //   play();
    //   }
  }

  _parseLines() async {
    final response = await http.get(Uri.parse(song.textResourceFile));

    String lyrics = utf8.decode(response.bodyBytes);
    lines = (new Parser()).parse((lyrics).split("\r\n"));
    return lines;
    // return await http.read(Uri.parse(song.textResourceFile));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            const Color(0xFF221A4D), // blue sky
            const Color(0xFF000000), // yellow sun
          ],
        )),
        child: Column(
          children: [
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      audioPlayer.stop();
                      isPlaying = false;
                      timer.cancel();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    song.title,
                    style: TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                  gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  const Color(0xFF221A4D), // blue sky
                  const Color(0xFF000000), // yellow sun
                ],
              )),
              child: FutureBuilder(
                future: parseFuture,
                builder: (context, snapShot) {
                  if (snapShot.hasData) {
                    return buildListView((lines));
                  } else if (snapShot.hasError) {
                    return Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    );
                  } else {
                    return Image(
                      fit: BoxFit.fill,
                      image: NetworkImage(song.imageResourceFile),
                    );
                  }
                },
              ),
            ),
            LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: Color(0xFF2D9DD2),
              valueColor: new AlwaysStoppedAnimation<Color>(Color(0xFFB15EC2)),
              value: _progressValue,
            ),
            isPlaying
                ? IconButton(
                    iconSize: 25,
                    icon: Icon(
                      Icons.pause,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      pause();
                    })
                : IconButton(
                    iconSize: 25,
                    icon: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      play();
                    },
                  )
          ],
        ),
      ),
    );
  }

  void play() async {
    int result = await audioPlayer.play(song.songResourceFile, stayAwake: true);
    // Future<int> duration = audioPlayer.getDuration();
    // duration.then((value) =>
    // songLength = value);

    if (result == 1) {
      setState(() {
        isPlaying = true;
      });
      // audioPlayer.getDuration().then((value) => songLength = value);
    }

    timer = Timer.periodic(
        Duration(milliseconds: 100),
        (Timer t) =>
            audioPlayer.getCurrentPosition().then((value) => updateUI(value)));

    // audioPlayer.onAudioPositionChanged.listen((Duration p) => {updateUI(p)});
  }

  buildListView(List<Line> lines) {
    return Expanded(
      child: Column(children: [
        Expanded(
          child: ListView.builder(
              controller: this.listViewController,
              itemCount: lines.length,
              itemBuilder: (BuildContext ctx, index) {
                return Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: createTextWidget(line: lines[index]),
                );
              }),
        )
      ]),
    );
  }

  createTextWidget({required Line line}) {
    return new RichText(
        text: TextSpan(
            style: TextStyle(fontSize: 27, color: Colors.white),
            children: [
          TextSpan(text: line.past),
          TextSpan(
              text: line.future,
              style: TextStyle(color: Colors.white30, fontSize: 27))
        ]));
    // future: line.past + line.splitWordPast,
    // past: line.splitWordFuture + line.future);
  }

  updateUI(int p) {
    updateCounter++;
    for (int j = 0; j < lines.length; j++) {
      Line line = lines[j];
      double time = p / 1000.toDouble();
      if (line.isIn(time)) {
        i = j;
        if (line.needToUpdateLyrics(time)) updateCounter = 0;
        setState(() {
          // _progressValue = p / songLength;
          line.updateLyrics(time);
          isPlaying = true;
        });
        break;
      }
      listViewController.animateTo(
        i * 37.toDouble(),
        duration: new Duration(milliseconds: 400),
        curve: Curves.decelerate,
      );
      // lines.first.past = "hello";
    }
    if (updateCounter == 5) updateProgressBar(p);
  }

  void updateProgressBar(int p) {
    setState(() {
      // _progressValue = p / songLength;
      isPlaying = true;
    });
  }

  pause() {
    audioPlayer.pause();
    timer.cancel();
    setState(() {
      isPlaying = false;
    });
  }
}
