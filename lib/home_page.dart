import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanbot_integration/page_repository.dart';
import 'package:scanbot_sdk/document_scan_data.dart';
import 'package:scanbot_sdk/json/common_data.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';
import 'package:scanbot_sdk/scanbot_sdk_models.dart';
import 'package:scanbot_sdk/scanbot_sdk_ui.dart';

import 'document_preview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageRepository _pageRepository = PageRepository();

  @override
  void initState() {
    super.initState();
    String licenseKey = "IJCLXcHJOv9CupPoqwV5oBeM0qKQa6" +
        "lFVQNyOqPJbD2mFJeGPvKP9tPcCtGa" +
        "ud8nMkJa0vr2ZG+WERuUt1WJw14XOM" +
        "qn0WeJT0eGt9vIL9X0IHoFr4jrLTMe" +
        "goyYdulAZSN7ANCfSVl2h21dD3ywVf" +
        "YdEL9r1vhbG0kcFXDLhEberKLJi7yM" +
        "LdbfaRLmuOq+P62GtyVRFEaBxEn8fe" +
        "I8eDJ65mE4t0A0zlyfg8bh07hG28EK" +
        "/jQ8esSA5ZRen6EUQ1F43FmFBlELez" +
        "miab6SKuNdFC8a/ZeMpdASiPxu9So8" +
        "PNpKKSzFX2DO8gcRwA7c34wci37JUs" +
        "KFxQUMPNacaw==\nU2NhbmJvdFNESw" +
        "pjb20uaHV0b21vLnNjYW5ib3QKMTY3" +
        "ODQwNjM5OQo4Mzg4NjA3CjE5\n";
    var config = ScanbotSdkConfig(
      licenseKey: licenseKey,
      imageFormat: ImageFormat.JPG,
      imageQuality: 80,
      loggingEnabled: true,
      encryptionParameters: EncryptionParameters(
        password: "password",
        mode: FileEncryptionMode.AES256,
      ),
    );
    ScanbotSdk.initScanbotSdk(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _startDocumentScanning,
          child: const Text('Scan'),
        ),
      ),
    );
  }

  Future<bool> checkLicenseStatus() async {
    final result = await ScanbotSdk.getLicenseStatus();
    if (result.isLicenseValid) {
      return true;
    }
    await showAlertDialog(
      'Scanbot SDK (trial) period or license has expired.',
      title: 'Info',
    );
    return false;
  }

  Future<void> _startDocumentScanning() async {
    if (!await checkLicenseStatus()) {
      return;
    }

    DocumentScanningResult? result;
    try {
      var config = DocumentScannerConfiguration(
        bottomBarBackgroundColor: Colors.red,
        ignoreBadAspectRatio: true,
        multiPageEnabled: true,
        //maxNumberOfPages: 3,
        //flashEnabled: true,
        //autoSnappingSensitivity: 0.7,
        cameraPreviewMode: CameraPreviewMode.FIT_IN,
        orientationLockMode: OrientationLockMode.PORTRAIT,
        //documentImageSizeLimit: Size(2000, 3000),
        cancelButtonTitle: 'Cancel',
        pageCounterButtonTitle: '%d Page(s)',
        textHintOK: "Perfect, don't move...",
        //textHintNothingDetected: "Nothing",
        // ...
      );
      result = await ScanbotSdkUi.startDocumentScanner(config);
    } catch (e) {
      Logger.root.severe(e);
    }
    if (result != null) {
      if (isOperationSuccessful(result)) {
        await _pageRepository.addPages(result.pages);
        await _gotoImagesView();
      }
    }
  }

  bool isOperationSuccessful(Result result) {
    return result.operationResult == OperationResult.SUCCESS;
  }

  Future<dynamic> _gotoImagesView() async {
    return await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DocumentPreview()),
    );
  }

  Future<void> showAlertDialog(
    String textToShow, {
    String? title,
  }) async {
    Widget text = SimpleDialogOption(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(textToShow),
      ),
    );

    // set up the SimpleDialog
    final dialog = AlertDialog(
      title: title != null ? Text(title) : null,
      content: text,
      contentPadding: const EdgeInsets.all(0),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );

    // show the dialog
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }
}
