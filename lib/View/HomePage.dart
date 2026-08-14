import 'package:certificate_maker/View/browseTemplets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HomePage")),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all()),
                  child: Text("AI generated"),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: (){
                  Get.to(() => const Browsetemplets());
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all()),
                  child: Text("Browse Templets"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
