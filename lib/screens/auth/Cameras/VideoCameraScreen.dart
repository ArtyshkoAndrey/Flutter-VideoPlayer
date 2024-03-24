import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';


class VideoCameraScreen extends StatefulWidget {
  final String url;

  @override
  const VideoCameraScreen({super.key, required this.url});


  @override
  VideoCameraScreenState createState() => VideoCameraScreenState();
}

class VideoCameraScreenState extends State<VideoCameraScreen> {
  late ScrollController _scrollController;
  late VideoPlayerController _videoController;
  final int countPint = 15;
  bool isUpdating = false;
  final int intervalMinutes = 10; // Интервал в минутах для рисок
  final int maxDaysBack = 2; // Максимальное количество дней для прокрутки назад
  DateTime timeState = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _setUpVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final currentTime = DateTime.now();
    final minutesSinceMidnight = (maxDaysBack * 24 * 60) - ((24 - currentTime.hour - (23 - currentTime.hour)) * 60 - (currentTime.minute % intervalMinutes) + intervalMinutes);
    final initialScroll = (minutesSinceMidnight / intervalMinutes) * _itemWidth(context);
    _scrollController.jumpTo(initialScroll);
  }

  double _itemWidth(BuildContext context) {
    return MediaQuery.of(context).size.width / countPint; // Делим ширину экрана на 15 рисок
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Видео'),
        ),
        body: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 40.0),// высота для видеоплеера
                child: _videoController.value.isInitialized ?
                AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController)
                ) :
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ),
              timeLine()
            ]
        )
    );
  }

  _setUpVideo() {
    if (kDebugMode) {
      print('Run _setUpVideo');
    }

    String baseUrl = widget.url.split('/index.m3u8')[0]; // Получаем базовый URL без /index.m3u8
    String token = widget.url.split('?token=')[1]; // Извлекаем токен
    String newUrl = widget.url;

    if (timeState.add(const Duration(minutes: 1)).isBefore(DateTime.now())) {
      // Создаем новый URL с переменными `from` и `duration`
      newUrl = '$baseUrl/index-${(timeState.microsecondsSinceEpoch /
          1000000).round()}-3600.m3u8?token=$token';
    }

    if (kDebugMode) {
      print('Camera URL: $newUrl');
    }
    try {
      _videoController.dispose().then((_) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(
            newUrl
        ))
          ..setLooping(true);
        _videoController.initialize().then((_) {
          setState(() {
            _videoController.play();
          });
        });
      });
    } catch (e) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(
          newUrl
      ))..setLooping(true);
      _videoController.initialize().then((_) {
        setState(() {
          _videoController.play();
        });
      });
    }
  }

  Widget timeLine() {
    return Container(
      color: Colors.grey[200],
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollEndNotification) {
                final scrollPosition = _scrollController.position.pixels;
                final minutes = (scrollPosition / _itemWidth(context)) * intervalMinutes;
                setState(() {
                  timeState = DateTime.now().subtract(Duration(minutes: DateTime.now().minute % intervalMinutes)).subtract(Duration(days: maxDaysBack)).add(Duration(minutes: minutes.toInt())).add(Duration(minutes: 70));
                });
                setState(() {
                  _setUpVideo();
                });
                if (timeState.isAfter(DateTime.now()) && !isUpdating) {
                  if (kDebugMode) {
                    print('Date picket is after now');
                  }
                  setState(() {
                    isUpdating = true;
                  });
                  _scrollToCurrentTime();
                  setState(() {
                    isUpdating = false;
                  });
                }
                if (kDebugMode) {
                  print('Selected time: ${timeState.toString()}');
                }
              }
              return true;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: (maxDaysBack * 24 * 60) ~/ intervalMinutes + 9,
                itemBuilder: (context, index) {
                  final time = DateTime.now().subtract(Duration(minutes: DateTime.now().minute % intervalMinutes)).subtract(Duration(days: maxDaysBack)).add(Duration(minutes: intervalMinutes * index));
                  return SizedBox(
                    width: _itemWidth(context),
                    child: CustomPaint(
                      painter: TimeScalePainter(time: time, interval: intervalMinutes),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            child: Container(
              height: 90,
              width: 2,
              color: Colors.red,
            ),
          )
        ],
      ),
    );
  }
}

class TimeScalePainter extends CustomPainter {
  final DateTime time;
  final int interval;
  final dateFormat = DateFormat('HH:mm');
  final dayFormat = DateFormat('dd MMM');

  TimeScalePainter({required this.time, required this.interval});

  @override
  void paint(Canvas canvas, Size size) {
    final isFullHour = time.minute % 60 == 0;
    final isMidnight = time.hour == 0 && time.minute == 0;

    final textSpan = TextSpan(
      text: isMidnight ? dayFormat.format(time) : dateFormat.format(time),
      style: const TextStyle(color: Colors.black, fontSize: 8),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);
    final yOffset = isMidnight ? size.height / 2 : size.height - 20;
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, yOffset));

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    final lineHeight = isMidnight ? size.height : isFullHour ? size.height / 2 : 10;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, lineHeight.toDouble()), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}