import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../models/user_profile.dart';

class AvatarWidget extends StatelessWidget {
  final UserProfile userProfile;
  final double size;
  final EdgeInsetsGeometry? margin;

  const AvatarWidget({
    super.key,
    required this.userProfile,
    this.size = 32,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;

    if (userProfile.avatarPath != null &&
        userProfile.avatarPath!.isNotEmpty &&
        File(userProfile.avatarPath!).existsSync()) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.file(
          File(userProfile.avatarPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (userProfile.avatarEmoji != null &&
        userProfile.avatarEmoji!.isNotEmpty) {
      avatarChild = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Center(
          child: Text(
            userProfile.avatarEmoji!,
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      );
    } else {
      avatarChild = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey4,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(
          CupertinoIcons.person_fill,
          color: CupertinoColors.white,
          size: size * 0.5,
        ),
      );
    }

    return Container(
      margin: margin,
      child: avatarChild,
    );
  }
}