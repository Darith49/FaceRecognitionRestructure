import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/widgets.dart';

class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isNavBarVisible = true.obs;

  void changePage(int index) {
    currentIndex.value = index;
    //When change page it will make the bottomnavigation can see
    if (!isNavBarVisible.value) {
      isNavBarVisible.value = true;
    }
  }

  //This function to handle the Scroll Direction
  bool onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      //delta > 0 it mean scroll down
      if (delta > 2.0 && isNavBarVisible.value) {
        isNavBarVisible.value = false;
        //delta < 0 it mean scroll up
      } else if (delta < -2.0 && !isNavBarVisible.value) {
        isNavBarVisible.value = true;
      }
    }
    //this function always return false it mean always check the Direction. but if return true it will stop
    return false;
  }
}
