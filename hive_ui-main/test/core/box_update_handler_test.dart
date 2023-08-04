// ignore_for_file: avoid_relative_lib_imports, deprecated_member_use, avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/adapters.dart';
// import 'pa1
// ckage:hive/hive.dart';
import 'package:hive_ui/core/box_update_handler.dart';
import 'package:hive_ui/core/hive_view_state.dart';


import '../../example/lib/boxes.dart';

// import '../../example/lib/boxes.dart';

class BoxUpdateHandlerMock implements BoxUpdateHandler {
  @override
  Future<bool> addObject(Map<String, dynamic> addedObject) {
    // TODO: implement addObject
    throw UnimplementedError();
  }

  @override
  Future<bool> clearBox() {
    // TODO: implement clearBox
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteFieldOfObject() {
    // TODO: implement deleteFieldOfObject
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteRowObject(List<int> rowIndices) {
    // TODO: implement deleteRowObject
    throw UnimplementedError();
  }

  @override
  // TODO: implement objectIndex
  int? get objectIndex => throw UnimplementedError();

  @override
  Future<bool> updateObject() {
    // TODO: implement updateObject
    throw UnimplementedError();
  }
}

void main() async {
  const String macOs = 'plugins.flutter.io/path_provider_macos';
  const String windows = 'plugins.flutter.io/path_provider';

  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel(windows);
  const MethodChannel channelMac = MethodChannel(macOs);
  channelMac.setMockMethodCallHandler((MethodCall call) async {
    return ".";
  });
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    return ".";
  });
  Boxes.initHive();

  late Box currentBox;
  late HiveViewState hiveViewState;
  late BoxUpdateHandler boxUpdateHandlerMock;

  setUpAll(() async {
    currentBox = await Hive.openBox('testBox');
    hiveViewState = HiveViewState(
      boxesMap: {currentBox: (json) => json},
      currentOpenedBox: currentBox,
    );
    boxUpdateHandlerMock = BoxUpdateHandler(
      hiveViewState,
      (errorMessage) {},
    );
  });
  tearDownAll(() {
    currentBox.clear();
    currentBox.close();
    hiveViewState.clearState();
    boxUpdateHandlerMock.clearBox();
  });

  group('BoxUpdateHandler', () {
    test('addObject() should return true when object is added successfully',
        () async {
      final addedObject = {"id": 1, "name": "test"};

      final result = await boxUpdateHandlerMock.addObject(addedObject);

      expect(result, true);
      currentBox.close();
    });

    test(
        'addObject() should return false when object is not added successfully',
        () async {
      // final addedObject = {"id": 1, "name": "test"};
      final addedObject = {"name": "test"};
      final result = await boxUpdateHandlerMock.addObject(addedObject);

      expect(result, false);
      currentBox.close();
    });

    test(
        'addObject() should call errorCallback when exception is thrown while adding object',
        () async {
      final hiveViewState = HiveViewState(
        boxesMap: {currentBox: (json) => json},
        // currentOpenedBox: currentBox,
      );
      final boxUpdateHandlerMock = BoxUpdateHandler(
        hiveViewState,
        (errorMessage) {
          // the error is
          debugPrint(" errorMessage $errorMessage ");
        },
      );
      // final addedObject = {"id": 1, "name": "test"};
      final addedObject = {"name": "test"};
      final result = await boxUpdateHandlerMock.addObject(addedObject);

      expect(result, false);
      currentBox.close();
    });
  });

  group('addObject', () {
    setUpAll(() async {
      currentBox = await Hive.openBox('testBox');
      hiveViewState = HiveViewState(
        boxesMap: {currentBox: (json) => json},
        currentOpenedBox: currentBox,
      );
      boxUpdateHandlerMock = BoxUpdateHandler(
        hiveViewState,
        (errorMessage) {},
      );
    });
    test('should add object to box', () async {
      final boxHandler = BoxUpdateHandler(
          HiveViewState(
            boxesMap: {currentBox: (json) => json},
            currentOpenedBox: currentBox,
          ),
          (error) => print(error));
      final addedObject = {"id": 1, "name": "John Doe"};
      final isAdded = await boxHandler.addObject(addedObject);
      expect(isAdded, true);
      expect(currentBox.get(1), addedObject);
    });
    test('should not add object to box and show error', () async {
      await currentBox.clear();
      final boxHandler = BoxUpdateHandler(
          HiveViewState(boxesMap: {currentBox: (json) => json}),
          (error) => print(error));
      final addedObject = {"name": "John Do"};
      final isAdded = await boxHandler.addObject(addedObject);
      expect(isAdded, false);
      expect(currentBox.get(1), null);
    });

    // focus on this please
    // Can not fromJsonConverter provided
    test(
        'should not add object to box and show error if fromJsonConverter is not provided',
        () async {
      currentBox.clear();
      final boxHandler = BoxUpdateHandler(
          HiveViewState(
            boxesMap: {
              // currentBox: (json) => null,
            },
            currentOpenedBox: currentBox,
          ),
          (error) => print(error));
      final addedObject = {"id": 1, "name": "John Doe"};
      final isAdded = await boxHandler.addObject(addedObject);
      expect(isAdded, false);
      expect(currentBox.get(1), null);
    });
    test('should not add object to box if box is not opened', () async {
      final boxHandler = BoxUpdateHandler(
          HiveViewState(boxesMap: {}), (error) => print(error));
      final addedObject = {"id": 1, "name": "John Doe"};
      final isAdded = await boxHandler.addObject(addedObject);
      expect(isAdded, false);
    });
  });
}
