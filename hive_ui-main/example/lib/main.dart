// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive_ui/boxes_view.dart';

import 'boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
  Boxes.initHive();
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Hive UI",
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container( // Wrap with Container to add background
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://img4.thuthuatphanmem.vn/uploads/2020/06/22/ba-bong-hoa-hong-trung-tren-mot-canh_090941406.jpg', // Replace with your image URL
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButton(
                child: const Text("OPEN HIVE UI"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HiveBoxesView(
                        hiveBoxes: Boxes.allBoxes,
                        onError: (String errorMessage) => {
                          print(errorMessage),
                        },
                      ),
                    ),
                  );
                },
              ),
              MaterialButton(
                child: const Text("Clear HIVE UI"),
                onPressed: () {
                  Boxes.customersBox.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


