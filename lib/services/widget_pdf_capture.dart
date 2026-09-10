import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

/// Renders a Flutter widget offscreen — using the app's real fonts and text
/// engine (Nastaleeq + RTL, exactly as on screen) — and embeds it into an A4
/// PDF, slicing it into pages at regular intervals.
///
/// This replaces native `pdf` text layout, which cannot shape Nastaleeq and
/// produces unreadable Urdu reports.
class WidgetPdfCapture {
  WidgetPdfCapture._();

  /// Logical A4 width the report widgets are designed for.
  static const double _pageWidth = 595;

  /// Logical A4 height.
  static const double _pageHeight = 842;

  /// White margin drawn on every A4 page.
  static const double _pageMargin = 24;

  /// Printable content height per page (A4 height minus both margins).
  static const double _contentPerPage = _pageHeight - _pageMargin * 2;

  /// Renders [report] offscreen at [pixelRatio]x and returns a multipage A4
  /// PDF as PNG-image pages. The widget root should be ~595 logical px wide.
  ///
  /// Pass the app [context] so the captured widget inherits the app theme
  /// (Jameel Noori Nastaleeq for Urdu, Material styles, RTL directionality).
  static Future<Uint8List> widgetToA4Pdf(
    Widget report, {
    BuildContext? context,
    double pixelRatio = 3.0,
  }) async {
    // Wrap with the inherited app theme (fonts!, MediaQuery, Localizations)
    // synchronously, before any await, while [context] is guaranteed valid.
    Widget wrapped = report;
    if (context != null) {
      wrapped = InheritedTheme.captureAll(
        context,
        MediaQuery(
          data: MediaQuery.of(context),
          child: Material(color: Colors.transparent, child: report),
        ),
      );
    }

    // 1. Measure the full report height at 1x — with the theme captured,
    //    because Nastaleeq line metrics differ hugely from the default font.
    final totalHeight = await _measureReportHeight(wrapped);
    if (totalHeight <= 0) {
      throw StateError('Report measured at zero height');
    }

    // 2. Capture page-sized windows of the tall report and lay them out as
    //    full-bleed A4 pages.
    final pageCount = (totalHeight / _contentPerPage).ceil().clamp(1, 60);
    final doc = pw.Document();
    for (var i = 0; i < pageCount; i++) {
      final png = await ScreenshotController.widgetToUiImage(
        _PageSlice(
          report: wrapped,
          offset: i * _contentPerPage,
          totalHeight: totalHeight,
        ),
        targetSize: const Size(_pageWidth, _pageHeight),
        pixelRatio: pixelRatio,
        delay: const Duration(milliseconds: 120),
      );
      final byteData = await png.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      png.dispose();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            pw.MemoryImage(bytes),
            width: PdfPageFormat.a4.width,
            height: PdfPageFormat.a4.height,
            fit: pw.BoxFit.fill,
          ),
        ),
      );
    }
    return doc.save();
  }

  /// Lays out [wrapped] offscreen at 1x and returns its full logical height.
  static Future<double> _measureReportHeight(Widget wrapped) async {
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = platformDispatcher.views.first;

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: const BoxConstraints(
          maxWidth: _pageWidth,
          maxHeight: 20000,
        ),
        devicePixelRatio: 1.0,
      ),
    );
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(textDirection: TextDirection.ltr, child: wrapped),
    ).attachToRenderTree(buildOwner);
    buildOwner.buildScope(element);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();

    final height = repaintBoundary.size.height;

    // Detach to release resources.
    element.update(
      RenderObjectToWidgetAdapter<RenderBox>(container: repaintBoundary),
    );
    buildOwner.finalizeTree();

    return height;
  }
}

/// Shows one page-sized window of the tall [report] by clipping and
/// translating it: page N captures content rows
/// [N * contentPerPage, ... + contentPerPage) with white margins around, so
/// the image aspect matches A4 exactly.
class _PageSlice extends StatelessWidget {
  final Widget report;
  final double offset;
  final double totalHeight;

  const _PageSlice({
    required this.report,
    required this.offset,
    required this.totalHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(
        width: WidgetPdfCapture._pageWidth,
        height: WidgetPdfCapture._pageHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: WidgetPdfCapture._pageMargin,
          ),
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minWidth: WidgetPdfCapture._pageWidth,
              maxWidth: WidgetPdfCapture._pageWidth,
              minHeight: 0,
              maxHeight: totalHeight,
              child: Transform.translate(
                offset: Offset(0, -offset),
                child: report,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
