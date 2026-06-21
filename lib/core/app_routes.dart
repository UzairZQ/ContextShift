import 'package:flutter/material.dart';

import 'app_spacing.dart';

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.transitionDuration = Motion.smoothScreen,
    super.reverseTransitionDuration = Motion.smoothScreenReverse,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final entrance = CurvedAnimation(
             parent: animation,
             curve: Motion.smoothEnter,
             reverseCurve: Motion.smoothExit,
           );
           final outgoing = CurvedAnimation(
             parent: secondaryAnimation,
             curve: Motion.smoothEnter,
             reverseCurve: Motion.smoothExit,
           );

           return FadeTransition(
             opacity: entrance,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0, 0.045),
                 end: Offset.zero,
               ).animate(entrance),
               child: ScaleTransition(
                 scale: Tween<double>(begin: 0.985, end: 1).animate(entrance),
                 child: SlideTransition(
                   position: Tween<Offset>(
                     begin: Offset.zero,
                     end: const Offset(0, -0.018),
                   ).animate(outgoing),
                   child: child,
                 ),
               ),
             ),
           );
         },
       );
}
