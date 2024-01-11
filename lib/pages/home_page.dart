// ignore_for_file: sort_child_properties_last, prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:ai_radio/model/radio.dart';
import 'package:ai_radio/utils/ai_utils.dart';
import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<MyRadio> radios;
  late MyRadio _selectedRadio;
  Color? _selectedColor;
  bool _isPlaying = false;
  final sugg = [
    "Play",
    "Stop",
    "Play rock music",
    "Play 107 FM",
    "Play next",
    "Play 104 FM",
    "Pause",
    "Play previous",
    "Play pop music"
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchRadios();
    setupAlan();
    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.playing) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      setState(() {});
    });
  }

  fetchRadios() async {
    final radioJson = await rootBundle.loadString("assets/radio.json");
    radios = MyRadioList.fromJson(radioJson).radios;
    _selectedRadio = radios![0];
    print(radios);
    setState(() {});
  }

  _playMusic(String url) {
    _audioPlayer.play(UrlSource(url));
    _selectedRadio = radios!.firstWhere((element) => element.url == url);
    print(_selectedRadio.name);
    setState(() {});
  }

  setupAlan() {
    AlanVoice.setLogLevel("all");
    AlanVoice.addButton(
        "b227da24f6970d5248c34720ed7f6caa2e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command) => _handleCommand(command.data));
  }

  _handleCommand(Map<String, dynamic> response) {
    switch (response["command"]) {
      case "play":
        _playMusic(_selectedRadio.url);
        break;
      case "play_channel":
        final id = response["id"];
        // _audioPlayer.pause();
        MyRadio newRadio = radios.firstWhere((element) => element.id == id);
        radios.remove(newRadio);
        radios.insert(0, newRadio);
        _playMusic(newRadio.url);
        break;

      case "stop":
        _audioPlayer.stop();
        break;
      case "next":
        final index = _selectedRadio.id;
        MyRadio newRadio;
        if (index + 1 > radios.length) {
          newRadio = radios.firstWhere((element) => element.id == 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        } else {
          newRadio = radios.firstWhere((element) => element.id == index + 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;

      case "prev":
        final index = _selectedRadio.id;
        MyRadio newRadio;
        if (index - 1 <= 0) {
          newRadio = radios.firstWhere((element) => element.id == 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        } else {
          newRadio = radios.firstWhere((element) => element.id == index - 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
      default:
        print("Command was ${response["command"]}");
        break;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: _selectedColor ?? AIColors.primaryColor2,
          child: radios != null
              ? VStack(
                  [
                    100.heightBox,
                    "All Channels".text.xl.white.semiBold.make().px16(),
                    20.heightBox,
                    ListView(
                      padding: Vx.m0,
                      shrinkWrap: true,
                      children: radios
                          .map((e) => ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(e.icon),
                                ),
                                title: "${e.name} FM".text.white.make(),
                                subtitle: e.tagline.text.white.make(),
                              ))
                          .toList(),
                    ).expand(),
                  ],
                  crossAlignment: CrossAxisAlignment.start,
                )
              : const Offstage(),
        ),
      ),
      body: Stack(
        children: [
          VxAnimatedBox()
              .size(context.screenWidth, context.screenHeight)
              .withGradient(LinearGradient(colors: [
                AIColors.primaryColor2,
                _selectedColor ?? AIColors.primaryColor1
              ], begin: Alignment.topLeft, end: Alignment.bottomRight))
              .make(),
          VStack(
            [
              AppBar(
                title: "AI Radio".text.xl4.bold.white.make().shimmer(
                      primaryColor: Vx.purple300,
                      secondaryColor: Vx.white,
                    ),
                backgroundColor: Colors.transparent,
                elevation: 0.0,
                centerTitle: true,
              ).h(100).p(10),
              30.heightBox,
              "Start with - Hey Alan".text.italic.semiBold.white.make(),
              10.heightBox,
              VxSwiper.builder(
                itemCount: sugg.length,
                height: 50.0,
                viewportFraction: 0.35,
                enableInfiniteScroll: true,
                autoPlay: true,
                autoPlayAnimationDuration: 3.seconds,
                autoPlayCurve: Curves.linear,
                itemBuilder: (context, index) {
                  final s = sugg[index];
                  return Chip(
                    label: s.text.make(),
                    backgroundColor: Vx.randomColor,
                  );
                },
              )
            ],
            crossAlignment: CrossAxisAlignment.center,
          ),
          30.heightBox,
          radios != null
              ? VxSwiper.builder(
                  onPageChanged: (index) {
                    _selectedRadio = radios![index];
                    final colorHex = radios![index].color;
                    _selectedColor =
                        Color(int.tryParse(colorHex) ?? 0xFF000000);
                    setState(() {});
                  },
                  aspectRatio: 1.0,
                  enlargeCenterPage: true,
                  itemCount: radios!.length,
                  itemBuilder: (context, index) {
                    final rad = radios![index];
                    return VxBox(
                      child: ZStack(
                        [
                          Positioned(
                            top: 0.0,
                            right: 0.0,
                            child: VxBox(
                              child: rad.category.text.uppercase.white
                                  .make()
                                  .px16(),
                            )
                                .height(40)
                                .black
                                .alignCenter
                                .withRounded(value: 10.0)
                                .make(),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: VStack(
                              [
                                rad.name.text.xl3.white.bold.make(),
                                5.heightBox,
                                rad.tagline.text.sm.white.semiBold.make(),
                              ],
                              crossAlignment: CrossAxisAlignment.center,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: VStack(
                              [
                                Icon(
                                  CupertinoIcons.play_circle,
                                  color: Colors.white,
                                ),
                                10.heightBox,
                                "Double tap to play".text.gray300.make(),
                              ],
                              crossAlignment: CrossAxisAlignment.center,
                            ),
                          ),
                        ],
                      ),
                    )
                        .clip(Clip.antiAlias)
                        .bgImage(DecorationImage(
                          image: NetworkImage(rad.image),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.3), BlendMode.darken),
                        ))
                        .border(color: Colors.black, width: 5.0)
                        .withRounded(value: 60.0)
                        .make()
                        .onInkDoubleTap(() {
                      _playMusic(rad.url);
                    }).p16();
                  },
                ).centered()
              : Center(
                  child: CircularProgressIndicator(),
                ),
          Align(
            alignment: Alignment.bottomCenter,
            child: VStack(
              [
                if (_isPlaying)
                  "Playing now - ${_selectedRadio.name} FM"
                      .text
                      .white
                      .makeCentered(),
                Icon(
                  _isPlaying
                      ? CupertinoIcons.stop_circle
                      : CupertinoIcons.play_circle,
                  color: Colors.white,
                  size: 50.0,
                ).onInkTap(() {
                  if (_isPlaying) {
                    _audioPlayer.stop();
                  } else {
                    _playMusic(_selectedRadio.url);
                  }
                }),
              ],
              crossAlignment: CrossAxisAlignment.center,
            ),
          ).pOnly(bottom: context.percentHeight * 12),
        ],
        fit: StackFit.expand,
      ),
    );
  }
}
