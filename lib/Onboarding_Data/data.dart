import 'package:flutter/material.dart';
import 'package:humming_bird/res/colors.dart';

class UnbordingContent {
  String image;
  String title;
  String subtitle;
  Color backgroundColor;
  UnbordingContent({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
  });
}

List<UnbordingContent> contentsList = [
  UnbordingContent(
      image: 'assets/images/img_sch1.svg',
      title: 'Welcome to Humming Bird Message Scheduling Made Easy',
      subtitle:
          'Provide a friendly welcome message and a brief overview of your message scheduling app',
      backgroundColor: CustomColor.kPrimaryColor),
  UnbordingContent(
      image: 'assets/images/img_sch2.svg',
      title: 'Discover Our Features',
      subtitle: 'Schedule messages for any time and date.',
      backgroundColor: CustomColor.kPrimaryColor),
  UnbordingContent(
      image: 'assets/images/img_sch3.svg',
      title: 'Let\'s Get Started',
      subtitle:
          'Provide a step-by-step guide on how to start using your message scheduling app. Include instructions on how to create and schedule messages.',
      backgroundColor: CustomColor.kPrimaryColor),
  UnbordingContent(
      image: 'assets/images/img_sch4.svg',
      title: 'We\'re Here to Help',
      subtitle: 'Contact our 24/7 customer support team.',
      backgroundColor: CustomColor.kPrimaryColor),
];
