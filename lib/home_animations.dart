import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void initializeLeavesControllers(TickerProvider vsync, List<AnimationController> controllers, List<Animation<Offset>> animations, List<bool> flipHorizontally, List<double> rotationAngles, List<double> scaleFactors, Random random) {
  for (int i = 0; i < 3; i++) {
    final controller = AnimationController(
      vsync: vsync,
      duration: Duration(seconds: 7),
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _setRandomTransformations(i, flipHorizontally, rotationAngles, scaleFactors, random);
        Future.delayed(Duration(seconds: random.nextInt(2)), () {
          controller.forward(from: 0);
        });
      }
    });

    controllers.add(controller);
    animations.add(Tween<Offset>(
      begin: Offset(1, 0),
      end: Offset(-1, 0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    )));

    _setRandomTransformations(i, flipHorizontally, rotationAngles, scaleFactors, random);
  }
}

void _setRandomTransformations(int index, List<bool> flipHorizontally, List<double> rotationAngles, List<double> scaleFactors, Random random) {
  if (flipHorizontally.length <= index) {
    flipHorizontally.add(random.nextBool());
    rotationAngles.add((random.nextDouble() - 0.5) * pi / 3); // Rotate between -60 to 60 degrees
    scaleFactors.add(0.8 + random.nextDouble() * 0.4); // Scale between 0.8 and 1.2
  } else {
    flipHorizontally[index] = random.nextBool();
    rotationAngles[index] = (random.nextDouble() - 0.5) * pi / 3;
    scaleFactors[index] = 0.9 + random.nextDouble() * 0.5;
  }
}

void startLeavesAnimations(List<AnimationController> controllers, Random random) {
  for (int i = 0; i < controllers.length; i++) {
    Future.delayed(Duration(milliseconds: random.nextInt(1000)), () {
      controllers[i].forward();
    });
  }
}
