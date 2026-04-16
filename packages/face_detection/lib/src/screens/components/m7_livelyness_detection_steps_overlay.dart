import 'dart:async';

import 'package:m7_livelyness_detection/index.dart';

class M7LivelynessDetectionStepOverlay extends StatefulWidget {
  final List<M7LivelynessStepItem> steps;
  final VoidCallback onCompleted;
  const M7LivelynessDetectionStepOverlay({
    Key? key,
    required this.steps,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<M7LivelynessDetectionStepOverlay> createState() =>
      M7LivelynessDetectionStepOverlayState();
}

class M7LivelynessDetectionStepOverlayState
    extends State<M7LivelynessDetectionStepOverlay> {
  //* MARK: - Public Variables
  //? =========================================================
  int get currentIndex {
    return _currentIndex;
  }

  bool _isLoading = false;

  //* MARK: - Private Variables
  //? =========================================================
  int _currentIndex = 0;

  late final PageController _pageController;

  //* MARK: - Life Cycle Methods
  //? =========================================================
  @override
  void initState() {
    _pageController = PageController(
      initialPage: 0,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBody(),
          // Center(
          //   child: Padding(
          //     padding: const EdgeInsets.all(10),
          //     child: Container(
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         border: Border.all(
          //           color: Colors.green,
          //           width: 10,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          Visibility(
            visible: _isLoading,
            child: const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //* MARK: - Public Methods for Business Logic
  //? =========================================================
  // Future<void> nextPage() async {
  //   if (_isLoading) {
  //     return;
  //   }
  //   if ((_currentIndex + 1) <= (widget.steps.length - 1)) {
  //     //Move to next step
  //     _showLoader();
  //     await Future.delayed(
  //       const Duration(
  //         milliseconds: 300,
  //       ),
  //     );
  //     await _pageController.nextPage(
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeIn,
  //     );
  //     await Future.delayed(
  //       const Duration(seconds: 300),
  //     );
  //     _hideLoader();
  //     setState(() => _currentIndex++);
  //   } else {
  //     widget.onCompleted();
  //   }
  // }
  Future<void> nextPage() async {
    if (_isLoading) {
      return;
    }
    if ((_currentIndex + 1) <= (widget.steps.length - 1)) {
      //Move to next step
      _showLoader();
      await Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );
      setState(() => _currentIndex++);
      startAnimation(_currentIndex);
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      _hideLoader();
    } else {
      widget.onCompleted();
    }
  }

  void reset() {
    _pageController.jumpToPage(0);
    setState(() => _currentIndex = 0);
    startAnimation(_currentIndex);
  }

  int totalSpikes = 250;
  int delayInMillis = 10;
  ValueNotifier<int> currentlyCompletedSpikes = ValueNotifier(0);
  // void startAnimation(int newSteps) {
  //   print("Start Animation called  ||||||||||||||");
  //   int totalStepsToComplete =
  //       (totalSpikes * (newSteps / widget.steps.length)).toInt();
  //   int increment = totalStepsToComplete - currentlyCompletedSpikes;

  //   // If we need to increment
  //   if (increment > 0) {
  //     Timer.periodic(Duration(milliseconds: delayInMillis), (timer) {
  //       if (currentlyCompletedSpikes < totalStepsToComplete) {
  //         setState(() {
  //           currentlyCompletedSpikes++;
  //         });
  //       } else {
  //         timer.cancel();
  //       }
  //     });
  //   } else if (increment < 0) {
  //     // If we need to decrement
  //     Timer.periodic(Duration(milliseconds: delayInMillis), (timer) {
  //       if (currentlyCompletedSpikes > totalStepsToComplete) {
  //         setState(() {
  //           currentlyCompletedSpikes--;
  //         });
  //       } else {
  //         timer.cancel();
  //       }
  //     });
  //   }
  // }

  Timer? _animationTimer; // Store the active timer

  void startAnimation(int newSteps) {
    print("Start Animation called  ||||||||||||||");
    int totalStepsToComplete =
        (totalSpikes * (newSteps / widget.steps.length)).toInt();
    int increment = totalStepsToComplete - currentlyCompletedSpikes.value;

    // Cancel any existing timer before starting a new one
    _animationTimer?.cancel();

    if (increment > 0) {
      _animationTimer =
          Timer.periodic(Duration(milliseconds: delayInMillis), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (currentlyCompletedSpikes.value < totalStepsToComplete) {
          setState(() {
            currentlyCompletedSpikes.value++;
          });
        } else {
          timer.cancel();
        }
      });
    } else if (increment < 0) {
      _animationTimer =
          Timer.periodic(Duration(milliseconds: delayInMillis), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (currentlyCompletedSpikes.value > totalStepsToComplete) {
          setState(() {
            currentlyCompletedSpikes.value--;
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationTimer
        ?.cancel(); // Cancel the timer to prevent setState after dispose
    _pageController.dispose();
    super.dispose();
  }

  //* MARK: - Private Methods for Business Logic
  //? =========================================================
  void _showLoader() => setState(
        () => _isLoading = true,
      );

  void _hideLoader() => setState(
        () => _isLoading = false,
      );

  //* MARK: - Private Methods for UI Components
  //? =========================================================
  Widget _buildBody() {
    return Stack(
      // mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      // mainAxisSize: MainAxisSize.max,
      // alignment: Alignment.center,
      children: [
        Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ValueListenableBuilder(
                valueListenable: currentlyCompletedSpikes,
                builder: (context, v, c) {
                  return CustomPaint(
                    painter: CircleProgressPainter(
                      steps: widget.steps.length,
                      currentlyCompletedSpikes: currentlyCompletedSpikes.value,
                      totalSpikes: 250,
                    ),
                  );
                },
              ),
              // CustomPaint(
              //   painter: CircleProgressPainter(
              //     steps: widget.steps.length,
              //     completedSteps: _currentIndex,
              //   ),
              // ),
            ),
          ),
        ),
        AbsorbPointer(
          absorbing: true,
          child: SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.steps.length,
              itemBuilder: (context, index) {
                return _buildAnimatedWidget(
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        // color: Color.fromARGB(255, 28, 28, 28),
                        borderRadius: BorderRadius.circular(20),
                        // boxShadow: const [
                        //   BoxShadow(
                        //     blurRadius: 5,
                        //     spreadRadius: 2.5,
                        //     color: Colors.black12,
                        //   ),
                        // ],
                      ),
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      // padding: const EdgeInsets.all(10),
                      child: Text(
                        widget.steps[index].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  isExiting: index != _currentIndex,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedWidget(
    Widget child, {
    required bool isExiting,
  }) {
    return isExiting
        ? ZoomOut(
            animate: true,
            child: FadeOutLeft(
              animate: true,
              delay: const Duration(milliseconds: 200),
              child: child,
            ),
          )
        : ZoomIn(
            animate: true,
            delay: const Duration(milliseconds: 500),
            child: FadeInRight(
              animate: true,
              delay: const Duration(milliseconds: 700),
              child: child,
            ),
          );
  }
}

// class CircleProgressPainter extends CustomPainter {
//   final int steps;
//   final int completedSteps;

//   CircleProgressPainter({
//     required this.steps,
//     required this.completedSteps,
//   });
//   @override
//   void paint(Canvas canvas, Size size) {
//     int numberOfSpikes = 250;
//     double centerX = size.width / 2;
//     double centerY = size.height / 2;
//     double radius = size.width / 2 - 5; // Adjust the thickness

//     Paint paint = Paint()
//       ..color = Color.fromARGB(255, 68, 67, 67)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 10;

//     Paint paint2 = Paint()
//       ..color = Colors.green
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 10;

//     // double angleIncrement = 2 * pi / numberOfSpikes;
//     double angleIncrement = 2 * pi / numberOfSpikes;

//     for (int i = 0; i < numberOfSpikes; i++) {
//       double startAngle = i * angleIncrement;
//       double endAngle = (i + 0.5) * angleIncrement;

//       double startX = centerX + radius * cos(startAngle);
//       double startY = centerY + radius * sin(startAngle);

//       double endX = centerX + radius * cos(endAngle);
//       double endY = centerY + radius * sin(endAngle);

//       canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
//     }
//     if (completedSteps > 0) {
//       int drawGreenLines = (numberOfSpikes * (completedSteps / steps)).toInt();

//       for (int i = 0; i < drawGreenLines; i++) {
//         double startAngle = ((i * angleIncrement) - 1.57);
//         double endAngle = ((i + 0.5) * angleIncrement) - 1.57;

//         double startX = centerX + radius * cos(startAngle);
//         double startY = centerY + radius * sin(startAngle);

//         double endX = centerX + radius * cos(endAngle);
//         double endY = centerY + radius * sin(endAngle);

//         canvas.drawLine(Offset(endX, endY), Offset(startX, startY), paint2);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return false;
//   }
// }

class CircleProgressPainter extends CustomPainter {
  final int steps;
  final int currentlyCompletedSpikes;
  final int totalSpikes;

  CircleProgressPainter({
    required this.steps,
    required this.currentlyCompletedSpikes,
    required this.totalSpikes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double radius = size.width / 2 - 5; // Adjust the thickness

    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 68, 67, 67)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    Paint paint2 = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    double angleIncrement = 2 * pi / totalSpikes;

    // Draw the full circle with gray lines
    for (int i = 0; i < totalSpikes; i++) {
      double startAngle = i * angleIncrement;
      double endAngle = (i + 0.5) * angleIncrement;

      double startX = centerX + radius * cos(startAngle);
      double startY = centerY + radius * sin(startAngle);

      double endX = centerX + radius * cos(endAngle);
      double endY = centerY + radius * sin(endAngle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Draw the green lines corresponding to completed spikes
    for (int i = 0; i < currentlyCompletedSpikes; i++) {
      double startAngle = ((i * angleIncrement) - 1.57);
      double endAngle = ((i + 0.5) * angleIncrement) - 1.57;

      double startX = centerX + radius * cos(startAngle);
      double startY = centerY + radius * sin(startAngle);

      double endX = centerX + radius * cos(endAngle);
      double endY = centerY + radius * sin(endAngle);

      canvas.drawLine(Offset(endX, endY), Offset(startX, startY), paint2);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Repaint on animation update
  }
}
