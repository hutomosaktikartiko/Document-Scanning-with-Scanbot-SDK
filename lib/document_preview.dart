import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanbot_integration/page_repository.dart';
import 'package:scanbot_integration/page_widget.dart';
import 'package:scanbot_integration/progress_dialog.dart';
import 'package:scanbot_sdk/json/common_data.dart' as sdk;
import 'package:scanbot_sdk/create_tiff_data.dart';
import 'package:scanbot_sdk/document_scan_data.dart';
import 'package:scanbot_sdk/json/common_data.dart';
import 'package:scanbot_sdk/ocr_data.dart';
import 'package:scanbot_sdk/render_pdf_data.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';
import 'package:scanbot_sdk/scanbot_sdk_ui.dart';

import 'main.dart';

class DocumentPreview extends StatefulWidget {
  @override
  _DocumentPreviewState createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<DocumentPreview> {
  final PageRepository _pageRepository = PageRepository();
  late List<sdk.Page> _pages;

  @override
  void initState() {
    _pages = _pageRepository.pages;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.black, //change your color here
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Image results',
          style: TextStyle(
            inherit: true,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: GridView.builder(
                  scrollDirection: Axis.vertical,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200),
                  itemBuilder: (context, position) {
                    Widget pageView;
                    if (shouldInitWithEncryption) {
                      pageView = EncryptedPageWidget(
                          _pages[position].documentPreviewImageFileUri!);
                    } else {
                      pageView = PageWidget(
                          _pages[position].documentPreviewImageFileUri!);
                    }
                    return GridTile(
                      child: GestureDetector(
                          onTap: () {
                            _showOperationsPage(_pages[position]);
                          },
                          child: pageView),
                    );
                  },
                  itemCount: _pages.length),
            ),
          ),
          BottomAppBar(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    _addPageModalBottomSheet(context);
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.add_circle),
                      Container(width: 4),
                      const Text(
                        'Add',
                        style: TextStyle(
                          inherit: true,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _settingModalBottomSheet(context);
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.more_vert),
                      Container(width: 4),
                      const Text(
                        'More',
                        style: TextStyle(
                          inherit: true,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showCleanupStorageDialog();
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      Container(width: 4),
                      const Text(
                        'Delete All',
                        style: TextStyle(
                          inherit: true,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOperationsPage(sdk.Page page) async {
    // await Navigator.of(context).push(
    //   MaterialPageRoute(builder: (context) => PageOperations(page)),
    // );
    _updatePagesList();
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Perform OCR'),
                onTap: () {
                  Navigator.pop(context);
                  _performOcr();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Save as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _createPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Save as PDF with OCR'),
                onTap: () {
                  Navigator.pop(context);
                  _createOcrPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Save as TIFF'),
                onTap: () {
                  Navigator.pop(context);
                  _createTiff(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Save as TIFF 1-bit encoded'),
                onTap: () {
                  Navigator.pop(context);
                  _createTiff(true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Apply Image Filter on ALL pages'),
                onTap: () {
                  Navigator.pop(context);
                  _filterAllPages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  void _addPageModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.scanner),
                title: const Text('Scan Page'),
                onTap: () {
                  Navigator.pop(context);
                  _startDocumentScanning();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_size_select_actual),
                title: const Text('Import Page'),
                onTap: () {
                  Navigator.pop(context);
                  _importImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  Future<void> _startDocumentScanning() async {
    DocumentScanningResult? result;
    try {
      var config = DocumentScannerConfiguration(
        orientationLockMode: sdk.OrientationLockMode.PORTRAIT,
        cameraPreviewMode: sdk.CameraPreviewMode.FIT_IN,
        ignoreBadAspectRatio: true,
        multiPageEnabled: false,
        multiPageButtonHidden: true,
      );
      result = await ScanbotSdkUi.startDocumentScanner(config);
    } catch (e) {
      print(e);
    }
    if (result != null) {
      if (isOperationSuccessful(result)) {
        await _pageRepository.addPages(result.pages);
        _updatePagesList();
      }
    }
  }

  void _showCleanupStorageDialog() {
    Widget text = const SimpleDialogOption(
      child: Text('Delete all images and generated files (PDF, TIFF, etc)?'),
    );

    // set up the SimpleDialog
    final dialog = AlertDialog(
      title: const Text('Delete all'),
      content: text,
      contentPadding: const EdgeInsets.all(0),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            _cleanupStorage();
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('CANCEL'),
        ),
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }

  Future<void> _filterAllPages() async {
    if (!await _checkHasPages(context)) {
      return;
    }

    // await Navigator.of(context).push(
    //   MaterialPageRoute(
    //       builder: (context) => MultiPageFiltering(_pageRepository)),
    // );
  }

  Future<void> _cleanupStorage() async {
    try {
      await ScanbotSdk.cleanupStorage();
      await _pageRepository.clearPages();
      _updatePagesList();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _createPdf() async {
    if (!await _checkHasPages(context)) {
      return;
    }

    final dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Creating PDF ...');
    try {
      dialog.show();
      var options = PdfRenderingOptions(PdfRenderSize.FIXED_A4);
      final pdfFileUri =
          await ScanbotSdk.createPdf(_pageRepository.pages, options);
      await dialog.hide();
      await showAlertDialog( pdfFileUri.toString(),
          title: 'PDF file URI');
    } catch (e) {
      print(e);
      await dialog.hide();
    }
  }

  Future<void> _importImage() async {
    try {
      final image = await ImagePicker().getImage(source: ImageSource.gallery);
      await _createPage(Uri.file(image?.path ?? ''));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _createPage(Uri uri) async {

    var dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true);
    dialog.style(message: 'Processing ...');
    dialog.show();
    try {
      var page = await ScanbotSdk.createPage(uri, false);
      page = await ScanbotSdk.detectDocument(page);
      await dialog.hide();
      await _pageRepository.addPage(page);
      _updatePagesList();
    } catch (e) {
      print(e);
      await dialog.hide();
    }
  }

  Future<void> _createTiff(bool binarized) async {
    if (!await _checkHasPages(context)) {
      return;
    }

    final dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Creating TIFF ...');
    dialog.show();
    try {
      var options = TiffCreationOptions(
          binarized: binarized,
          dpi: 200,
          compression: (binarized
              ? TiffCompression.CCITT_T6
              : TiffCompression.ADOBE_DEFLATE));
      final tiffFileUri =
          await ScanbotSdk.createTiff(_pageRepository.pages, options);
      await dialog.hide();
      await showAlertDialog(tiffFileUri.toString(),
          title: 'TIFF file URI');
    } catch (e) {
      print(e);
      await dialog.hide();
    }
  }

  Future<void> _performOcr() async {
    if (!await _checkHasPages(context)) {
      return;
    }

    final dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Performing OCR ...');
    dialog.show();
    try {
      final result = await ScanbotSdk.performOcr(_pages,
          OcrOptions(languages: ['en', 'de'], shouldGeneratePdf: false));
      await dialog.hide();
      await showAlertDialog('Plain text:\n' + (result.plainText ?? ''));
    } catch (e) {
      print(e);
      await dialog.hide();
    }
  }

  Future<void> _createOcrPdf() async {
    if (!await _checkHasPages(context)) {
      return;
    }

    var dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Performing OCR with PDF ...');
    dialog.show();
    try {
      var result = await ScanbotSdk.performOcr(
          _pages, OcrOptions(languages: ['en', 'de'], shouldGeneratePdf: true));
      await dialog.hide();
      await showAlertDialog('PDF File URI:\n' +
          (result.pdfFileUri ?? '') +
          '\n\nPlain text:\n' +
          (result.plainText ?? ''));
    } catch (e) {
      print(e);
      await dialog.hide();
    }
  }

  Future<bool> _checkHasPages(BuildContext context) async {
    if (_pages.isNotEmpty) {
      return true;
    }
    await showAlertDialog(
        'Please scan or import some documents to perform this function.',
        title: 'Info');
    return false;
  }

  void _updatePagesList() {
    setState(() {
      _pages = _pageRepository.pages;
    });
  }

  bool isOperationSuccessful(Result result) {
    return result.operationResult == OperationResult.SUCCESS;
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
