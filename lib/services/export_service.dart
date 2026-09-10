import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';

import '../core/constants.dart';
import '../core/utils/app_date_utils.dart';
import '../core/utils/math_engine.dart';
import '../localization/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/daily_record.dart';
import '../models/student.dart';
import '../widgets/pdf_report_widgets.dart';
import 'widget_pdf_capture.dart';

/// Localized label set used while building reports.
typedef ReportStrings = String Function(String key, {List<String>? args});

/// Builds and shares text / PDF reports.
class ExportService {
  ExportService._();

  static final ExportService instance = ExportService._();

  static final ArabicReshaper _reshaper = ArabicReshaper(
    configuration: ArabicReshaperConfig(
      deleteHarakat: true,
      supportLigatures: true,
    ),
  );

  static bool _isRtl(String text) {
    final rtlRegex = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    return rtlRegex.hasMatch(text);
  }

  static String _shape(String text) {
    if (text.isEmpty) return text;
    try {
      // Only reshape text that contains actual Arabic/Urdu characters.
      // Pure Latin/number strings must not go through the reshaper.
      if (!_isRtl(text)) return text;
      // Reshape Arabic/Urdu into connected presentation forms, keeping the
      // string in LOGICAL order. The dart `pdf` package reorders RTL text to
      // visual order itself whenever `textDirection: rtl` is set (its bidi
      // pass runs `logicalToVisual` internally), so we must NOT reverse the
      // string here — doing so would double-reverse and render Urdu as
      // left-to-right / broken.
      return _reshaper.reshape(text);
    } catch (_) {
      // If reshaping fails (e.g. unsupported glyph), return original text
      // to prevent RangeError during PDF glyph lookup.
      return text;
    }
  }

  static pw.Widget _pdfText(String text, {pw.TextStyle? style, pw.TextAlign? textAlign}) {
    final shaped = _shape(text);
    final isRtl = _isRtl(text);
    return pw.Text(
      shaped,
      style: style,
      textAlign: textAlign,
      textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    );
  }

  static List<String> _processRow(List<String> row) {
    return row.map((cell) => _shape(cell)).toList();
  }  // ── Helper to build theme with Amiri font for Arabic/Urdu ────────────────
  // NOTE: JameelNooriNastaleeq (Nastaleeq) CANNOT be used in the Dart pdf
  // package because it requires OpenType GSUB/GPOS features that the package
  // doesn't support. Nastaleeq characters appear disconnected/garbled in PDF.
  // Amiri is a proper Naskh font that fully supports Arabic presentation forms.
  static Future<pw.ThemeData> _buildTheme() async {
    final outfitData = await rootBundle.load('assets/fonts/Outfit.ttf');
    final outfitFont = pw.Font.ttf(outfitData);

    final amiriData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final amiriFont = pw.Font.ttf(amiriData);

    return pw.ThemeData.withFont(
      base: amiriFont,
      bold: amiriFont,
      italic: amiriFont,
      boldItalic: amiriFont,
      fontFallback: [outfitFont],
    );
  }

  // ── Text reports ──────────────────────────────────────────────────────────

  String buildDailyTextReport({
    required DateTime date,
    required String section,
    required List<Student> students,
    required List<DailyRecord> records,
    required ReportStrings t,
    required String locale,
  }) {
    final dateKey = AppDateUtils.key(date);
    final dayRecords = records.where((r) => r.date == dateKey).toList();
    // Only this section's students count; no record = absent by default.
    final present = students
        .where((s) => dayRecords.any((r) => r.studentId == s.id && r.present))
        .length;
    final absent = students.length - present;
    final sabaqCount = dayRecords.where((r) => r.sabaq != null).length;
    final sabqiCount = dayRecords.where((r) => r.sabqi != null).length;
    final manzilCount = dayRecords.where((r) => r.manzil != null).length;

    final buffer = StringBuffer()
      ..writeln('[${t('appName')}]')
      ..writeln(
        t('dailyReport', args: [AppDateUtils.format(date, locale), section]),
      )
      ..writeln('--------------------')
      ..writeln('=> ${t('totalPresent')}: $present')
      ..writeln('=> ${t('totalAbsent')}: $absent')
      ..writeln(
        '${t('sabaq')}: $sabaqCount | ${t('sabqi')}: $sabqiCount | ${t('manzil')}: $manzilCount',
      )
      ..writeln('--------------------');

    final absentStudents = <String>[];
    final flagged = <String>[];
    for (final s in students) {
      final rec = dayRecords.where((r) => r.studentId == s.id).firstOrNull;
      if (rec == null || !rec.present) {
        absentStudents.add(s.name);
        continue;
      }
      if (!rec.hasAnyLesson) flagged.add(s.name);
      final parts = <String>[];
      if (rec.sabaq != null) {
        final s = rec.sabaq!;
        final pages = s.pages > 0 ? ' - ${s.startPage}-${s.endPage}' : '';
        parts.add(
          '${t('sabaq')}: ${t('juz')} ${s.juz} ${s.pageLabel} (${s.lines})$pages',
        );
      }
      if (rec.sabqi != null) {
        final s2 = rec.sabqi!;
        parts.add(
          '${t('sabqi')}: ${t('juz')} ${s2.juz} ${s2.startPage}–${s2.endPage}',
        );
      }
      if (rec.manzil != null) {
        parts.add(
          '${t('manzil')}: ${t('juz')} ${rec.manzil!.juz} ${t('ruba')} ${rec.manzil!.ruba}',
        );
      }
      buffer
        ..writeln('> ${s.name}${s.isStarred ? ' *' : ''}')
        ..writeln('   ${parts.isEmpty ? t('noLesson') : parts.join(' | ')}');
    }

    if (absentStudents.isNotEmpty) {
      buffer
        ..writeln('--------------------')
        ..writeln('=> ${t('absentList')}: ${absentStudents.join(', ')}');
    }
    if (flagged.isNotEmpty) {
      buffer.writeln('! ${t('attentionList')}: ${flagged.join(', ')}');
    }
    return buffer.toString();
  }

  String buildMonthlyTextReport({
    required DateTime month,
    required String section,
    required List<Student> students,
    required List<DailyRecord> records,
    required ReportStrings t,
    required String locale,
  }) {
    final monthKey = AppDateUtils.monthKey(month);
    final monthRecords = records
        .where((r) => r.date.startsWith(monthKey))
        .toList();
    final buffer = StringBuffer()
      ..writeln('[${t('appName')}] - ${t('monthlyReport')}')
      ..writeln(
        '${AppDateUtils.formatMonthYear(month, locale)} - ${t('section')} $section',
      )
      ..writeln('--------------------');

    for (final s in students) {
      final sRecords = monthRecords.where((r) => r.studentId == s.id).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final presentDays = sRecords.where((r) => r.present).length;
      final absentDays = sRecords.where((r) => !r.present).length;
      final lessons = sRecords.where((r) => r.hasAnyLesson).length;
      buffer
        ..writeln('> ${s.name}${s.isStarred ? ' *' : ''}')
        ..writeln(
          '   ${t('presentShort')}: $presentDays | ${t('absentShort')}: $absentDays | ${t('lessons')}: $lessons',
        );
    }
    return buffer.toString();
  }

  // ── PDF reports ───────────────────────────────────────────────────────────

  Future<Uint8List> buildDailyPdfReport({
    required DateTime date,
    required String section,
    required List<Student> students,
    required List<DailyRecord> records,
    required ReportStrings t,
    required String locale,
  }) async {
    final dateKey = AppDateUtils.key(date);
    final dayRecords = records.where((r) => r.date == dateKey).toList();
    // Only this section's students count; no record = absent by default.
    final present = students
        .where((s) => dayRecords.any((r) => r.studentId == s.id && r.present))
        .length;
    final absent = students.length - present;

    final theme = await _buildTheme();
    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          theme: theme,
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green800,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfText(
                            t('appName'),
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          _pdfText(
                            t(
                              'dailyReport',
                              args: [AppDateUtils.format(date, locale), section],
                            ),
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.green100,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green900,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: _pdfText(
                          '${t('totalPresent')}: $present    ${t('totalAbsent')}: $absent',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.TableHelper.fromTextArray(
                  headers: _processRow(
                    [
                      '#',
                      t('student'),
                      t('sabaq'),
                      t('sabqi'),
                      t('manzil'),
                      t('attendance'),
                    ],
                  ),
                  data: [
                    for (var i = 0; i < students.length; i++)
                      _processRow(
                        _pdfRow(
                          students[i],
                          dayRecords
                              .where((r) => r.studentId == students[i].id)
                              .firstOrNull,
                          t,
                          i + 1,
                        ),
                      ),
                  ],
                  headerStyle: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                  headerDirection: pw.TextDirection.rtl,
                  tableDirection: pw.TextDirection.rtl,
                  cellStyle: const pw.TextStyle(fontSize: 9.5),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
                  cellAlignments: {0: pw.Alignment.center, 5: pw.Alignment.center},
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
                  oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                ),
                pw.SizedBox(height: 12),
                _pdfText(
                  t('generatedOn'),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),                ),
              ],
            ),
        ],
      ),
    );
    return doc.save();
  }


  List<String> _pdfRow(Student s, DailyRecord? r, ReportStrings t, int index) {
    if (r == null) {
      return [index.toString(), s.name, '—', '—', '—', t('absent')];
    }
    final sabaq = r.sabaq == null
        ? '—'
        : '${t('juz')} ${r.sabaq!.juz} - ${r.sabaq!.pageLabel} - ${r.sabaq!.lines}';
    final sabqi = r.sabqi == null
        ? '—'
        : '${t('juz')} ${r.sabqi!.juz} - ${r.sabqi!.startPage}-${r.sabqi!.endPage}';
    final String manzil;
    if (r.manzil == null) {
      manzil = '—';
    } else if (r.manzil!.customText != null && r.manzil!.customText!.trim().isNotEmpty) {
      manzil = r.manzil!.customText!.trim();
    } else {
      final isFullPara = (r.manzil!.startJuz == null || r.manzil!.startJuz == r.manzil!.juz) &&
          (r.manzil!.startRuba == null || r.manzil!.startRuba == 1) &&
          r.manzil!.ruba == 4;
      final String rubaStr;
      if (isFullPara) {
        rubaStr = t('pooraPara');
      } else if (r.manzil!.startRuba == 1 && r.manzil!.ruba == 2) {
        rubaStr = t('nisafAwal');
      } else if (r.manzil!.startRuba == 3 && r.manzil!.ruba == 4) {
        rubaStr = t('nisafAkhir');
      } else {
        rubaStr = '${t('ruba')} ${r.manzil!.ruba}';
      }
      manzil = '${t('juz')} ${r.manzil!.juz} - $rubaStr';
    }
    return [
      index.toString(),
      s.name,
      sabaq,
      sabqi,
      manzil,
      r.present ? t('present') : t('absent'),
    ];
  }

  // ── Monthly student report (khulasa) ─────────────────────────────────────

  String buildStudentMonthlyTextReport({
    required Student student,
    required DateTime month,
    required List<DailyRecord> records,
    required ReportStrings t,
    required String locale,
  }) {
    final monthKey = AppDateUtils.monthKey(month);
    final monthRecords =
        records
            .where(
              (r) => r.studentId == student.id && r.date.startsWith(monthKey),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final stats = StudentMonthlyStats.compute(
      records: monthRecords,
      linesPerPage: student.mushafLines,
    );
    final buffer = StringBuffer()
      ..writeln(
        '[${t('appName')}] - ${t('studentMonthlyReport', args: [student.name])}',
      )
      ..writeln(
        '${AppDateUtils.formatMonthYear(month, locale)} - ${t('section')} ${student.section}',
      )
      ..writeln('--------------------')
      ..writeln(
        '${t('presentDays')}: ${stats.presentDays} | ${t('absentDays')}: ${stats.absentDays}',
      )
      ..writeln('${t('sabaqTotal')}: ${stats.sabaqLessons} ${t('lessonsCount')}'
        '${stats.sabaqPages > 0 ? ' - ${stats.sabaqPages} ${t('pagesCount')}' : ''}'
        ' - ${t('grade')}: ${stats.sabaqGrade(t)}',
      )
      ..writeln('   ${t('missedSabaq')}: ${stats.missedSabaq}')
      ..writeln(
        '${t('sabqiTotal')}: ${stats.sabqiLessons} ${t('lessonsCount')} - ${stats.sabqiCompletedPages}/${stats.sabqiTotalPages} ${t('pagesCount')} - ${t('grade')}: ${stats.sabqiGrade(t)}',
      )
      ..writeln('   ${t('missedSabqi')}: ${stats.missedSabqi}')
      ..writeln('${t('manzilTotal')}: ${stats.manzilLessons} ${t('lessonsCount')} - ${stats.manzilRubas} ${t('rubasCount')} - ${t('grade')}: ${stats.manzilGrade(t)}',
      )
      ..writeln('   ${t('missedManzil')}: ${stats.missedManzil}')
      ..writeln('--------------------');

    if (monthRecords.isEmpty) {
      buffer.writeln(t('noRecords'));
    } else {
      buffer.writeln(t('dailyRecords'));
      for (final r in monthRecords) {
        final parts = <String>[];
        if (r.sabaq != null) {
          final s = r.sabaq!;
          final pages = s.pages > 0 ? ' - ${s.startPage}-${s.endPage}' : '';
          parts.add(
            '${t('sabaq')}: ${t('juz')} ${s.juz} ${s.pageLabel} (${s.lines})$pages',
          );
        }
        if (r.sabqi != null) {
          final s = r.sabqi!;
          final calc = MathEngine.computeSabqi(
            startPage: s.startPage,
            endPage: s.endPage,
            heardPage: s.heardPage,
          );
          parts.add(
            '${t('sabqi')}: ${t('juz')} ${s.juz} ${s.startPage}–${s.endPage} (${calc.completedPages}/${calc.totalPages})',
          );
        }
        if (r.manzil != null) {
          parts.add(
            '${t('manzil')}: ${t('juz')} ${r.manzil!.juz} ${t('ruba')} ${r.manzil!.ruba}',
          );
        }
        buffer
          ..writeln(
            '- ${AppDateUtils.format(AppDateUtils.fromKey(r.date), locale)} - ${r.present ? t('present') : t('absent')}',
          )
          ..writeln('   ${parts.isEmpty ? t('noLesson') : parts.join(' | ')}');
      }
    }
    return buffer.toString();
  }

  String buildCollectiveTextReport({
    required DateTime month,
    required List<Student> students,
    required List<DailyRecord> records,
    required ReportStrings t,
    required String locale,
  }) {
    final monthKey = AppDateUtils.monthKey(month);
    final buffer = StringBuffer()
      ..writeln('[${t('appName')}] - ${t('collectiveReport')}')
      ..writeln(AppDateUtils.formatMonthYear(month, locale))
      ..writeln('--------------------');

    if (students.isEmpty) {
      buffer.writeln(t('noStudents'));
      return buffer.toString();
    }

    for (final s in students) {
      final monthRecords =
          records
              .where((r) => r.studentId == s.id && r.date.startsWith(monthKey))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      final stats = StudentMonthlyStats.compute(
        records: monthRecords,
        linesPerPage: s.mushafLines,
      );
      buffer
        ..writeln('> ${s.name}${s.isStarred ? ' *' : ''}')
        ..writeln(
          '   ${t('attendanceRate')}: ${stats.presentDays}/${stats.presentDays + stats.absentDays} | ${t('sabaq')}: ${stats.sabaqLessons} | ${t('sabqi')}: ${stats.sabqiLessons} | ${t('manzil')}: ${stats.manzilLessons}',
        );
      final last = monthRecords.reversed
          .where((r) => r.hasAnyLesson)
          .firstOrNull;
      if (last != null) {
        final parts = <String>[];
        if (last.sabaq != null) {
          parts.add('${t('sabaq')}: ${last.sabaq!.pageLabel}');
        }
        if (last.sabqi != null) {
          parts.add(
            '${t('sabqi')}: ${last.sabqi!.startPage}–${last.sabqi!.endPage}',
          );
        }
        if (last.manzil != null) {
          parts.add(
            '${t('manzil')}: ${t('juz')} ${last.manzil!.juz} R${last.manzil!.ruba}',
          );
        }
        buffer.writeln('   ${t('lastRecords')}: ${parts.join(' | ')}');
      }
    }
    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Monthly student PDF — Screenshot-style layout
  // ═══════════════════════════════════════════════════════════════════════

  Future<Uint8List> buildStudentMonthlyPdfReport({
    required Student student,
    required DateTime month,
    required List<DailyRecord> records,
    required AppSettings settings,
    required ReportStrings t,
    required String locale,
  }) async {
    final monthKey = AppDateUtils.monthKey(month);
    final monthRecords = records
        .where((r) => r.studentId == student.id && r.date.startsWith(monthKey))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final stats = StudentMonthlyStats.compute(
      records: monthRecords,
      linesPerPage: student.mushafLines,
    );

    // ── Compute Sabaq summary ──────────────────────────
    int sabaqTimesRecited = 0;
    for (final r in monthRecords) {
      if (r.present && r.sabaq != null) {
        sabaqTimesRecited++;
      }
    }

    // ── Compute Sabqi summary ──────────────────────────
    int sabqiTimesRecited = 0;
    for (final r in monthRecords) {
      if (r.present && r.sabqi != null) {
        sabqiTimesRecited++;
      }
    }

    // ── Compute Manzil summary ─────────────────────────
    int manzilTimesRecited = 0;
    int? latestManzilPara;
    int? latestManzilRuba;
    for (final r in monthRecords) {
      if (r.present && r.manzil != null) {
        manzilTimesRecited++;
        latestManzilPara = r.manzil!.juz;
        latestManzilRuba = r.manzil!.ruba;
      }
    }

    // ── Load fonts ──────────────────────────────────────
    final outfitData = await rootBundle.load('assets/fonts/Outfit.ttf');
    final outfitFont = pw.Font.ttf(outfitData);
    final amiriData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final amiriFont = pw.Font.ttf(amiriData);

    pw.Widget txt(
      String raw, {
      double size = 10,
      pw.FontWeight fw = pw.FontWeight.normal,
      PdfColor col = PdfColors.black,
      pw.TextAlign? align,
    }) {
      final shaped = _shape(raw);
      final isRtl = _isRtl(raw);
      return pw.Text(
        shaped,
        textAlign: align,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        style: pw.TextStyle(
          font: isRtl ? amiriFont : outfitFont,
          fontFallback: [outfitFont],
          fontSize: size,
          fontWeight: fw,
          color: col,
        ),
      );
    }

    pw.Widget txtCenter(
      String raw, {
      double size = 10,
      pw.FontWeight fw = pw.FontWeight.normal,
      PdfColor col = PdfColors.black,
    }) => txt(raw, size: size, fw: fw, col: col, align: pw.TextAlign.center);

    final monthName = AppDateUtils.formatMonthYear(month, locale);
    final schoolName = settings.madrasaName.isNotEmpty ? settings.madrasaName : t('appName');
    final parentName = student.phone.isNotEmpty ? student.phone : '';

    // ── Summary card builder ─────────────────────────────
    pw.Widget _buildSummaryCard({
      required String title,
      required PdfColor titleColor,
      required PdfColor bgColor,
      required PdfColor borderColor,
      required List<pw.Widget> items,
    }) {
      return pw.Container(
        width: 175,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: borderColor, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            txt(title, size: 11, fw: pw.FontWeight.bold, col: titleColor),
            pw.SizedBox(height: 5),
            ...items,
          ],
        ),
      );
    }

    pw.Widget _buildSummaryItem(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            txt(label, size: 9.5, col: PdfColors.grey700),
            txt(value, size: 9.5, fw: pw.FontWeight.bold),
          ],
        ),
      );
    }

    // ── Build PDF ───────────────────────────────────────
    final theme = await _buildTheme();
    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          theme: theme,
        ),
        build: (context) => [
          // ═══ 1. HEADER BANNER ═══════════════════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.green800,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    txt(schoolName, size: 18, fw: pw.FontWeight.bold, col: PdfColors.white),
                    pw.SizedBox(height: 3),
                    txt(t('monthlyHifzReport'), size: 11.5, col: PdfColors.green100),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green900,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: txt(monthName, size: 11.5, fw: pw.FontWeight.bold, col: PdfColors.white),
                ),
              ],
            ),
          ),

          // ═══ 2. STUDENT INFO BAR ═══════════════════════════════
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    txt('${t('studentLabel')}: ${student.name}', size: 13, fw: pw.FontWeight.bold),
                    pw.SizedBox(width: 10),
                    txt('(${t('section')} ${student.section})', size: 10.5, col: PdfColors.grey600),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    if (parentName.isNotEmpty)
                      txt('${t('parentNameLabel')}: $parentName', size: 10.5, col: PdfColors.grey700),
                    pw.SizedBox(width: 16),
                    if (settings.teacherName.isNotEmpty)
                      txt('${t('teacherLabel')}: ${settings.teacherName}', size: 10.5, col: PdfColors.grey700),
                  ],
                ),
              ],
            ),
          ),

          // ═══ 3. THREE SUMMARY CARDS ═══════════════════════════
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // حاضری Card
              _buildSummaryCard(
                title: 'ڈیلی حاضری',
                titleColor: PdfColors.green900,
                bgColor: PdfColors.green50,
                borderColor: PdfColors.green200,
                items: [
                  _buildSummaryItem(t('totalPresent'), '${stats.presentDays}'),
                  _buildSummaryItem(t('totalAbsent'), '${stats.absentDays}'),
                  _buildSummaryItem(t('sabaq'), '$sabaqTimesRecited ${t('lessonsCount')}'),
                ],
              ),

              // سبقی Card
              _buildSummaryCard(
                title: 'ڈیلی سبقی',
                titleColor: PdfColors.purple900,
                bgColor: PdfColors.purple50,
                borderColor: PdfColors.purple200,
                items: [
                  _buildSummaryItem(t('sabqi'), '$sabqiTimesRecited ${t('lessonsCount')}'),
                ],
              ),

              // منزل Card
              _buildSummaryCard(
                title: 'ڈیلی منزل',
                titleColor: PdfColors.teal900,
                bgColor: PdfColors.teal50,
                borderColor: PdfColors.teal200,
                items: [
                  _buildSummaryItem(t('manzil'), '$manzilTimesRecited ${t('lessonsCount')}'),
                  if (latestManzilPara != null)
                    _buildSummaryItem(t('lastPositionLabel'), '${t('juz')} $latestManzilPara ${t('ruba')} ${latestManzilRuba ?? 1}'),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          // ═══ 4. DAILY RECORDS TABLE ═══════════════════════════
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green800,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: txt(
                    '${t('pdfDailyRecordUrdu')} (${monthRecords.length})',
                    size: 12,
                    fw: pw.FontWeight.bold,
                    col: PdfColors.white,
                  ),
                ),
                if (monthRecords.isEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(14),
                    child: txt(t('noRecords'), size: 11, col: PdfColors.grey500),
                  )
                else
                  pw.TableHelper.fromTextArray(
                    headers: _processRow([
                      t('dateUrdu'),
                      t('attendanceUrdu'),
                      t('sabaqUrdu'),
                      t('sabqiUrdu'),
                      t('manzilUrdu'),
                    ]),
                    data: [
                      for (final r in monthRecords)
                        _processRow([
                          AppDateUtils.format(AppDateUtils.fromKey(r.date), locale),
                          r.present ? t('present') : t('pdfAbsentLabel'),
                          r.sabaq == null
                              ? '—'
                              : '${t('juz')} ${r.sabaq!.juz}, ${r.sabaq!.startPage}–${r.sabaq!.endPage}, ${r.sabaq!.lines} ${t('lines')}',
                          r.sabqi == null
                              ? '—'
                              : '${t('juz')} ${r.sabqi!.juz}, ${r.sabqi!.startPage}–${r.sabqi!.endPage}, ${r.sabqi!.revisionCount} ${t('sabaqi')}',
                          r.manzil == null
                              ? '—'
                              : (r.manzil!.customText != null && r.manzil!.customText!.trim().isNotEmpty
                                  ? r.manzil!.customText!.trim()
                                  : ((r.manzil!.startJuz == null || r.manzil!.startJuz == r.manzil!.juz) && (r.manzil!.startRuba == null || r.manzil!.startRuba == 1) && r.manzil!.ruba == 4
                                      ? '${t('juz')} ${r.manzil!.juz}, ${t('pooraPara')}'
                                      : (r.manzil!.startRuba == 1 && r.manzil!.ruba == 2
                                          ? '${t('juz')} ${r.manzil!.juz}, ${t('nisafAwal')}'
                                          : (r.manzil!.startRuba == 3 && r.manzil!.ruba == 4
                                              ? '${t('juz')} ${r.manzil!.juz}, ${t('nisafAkhir')}'
                                              : '${t('juz')} ${r.manzil!.juz}, ${t('ruba')} ${r.manzil!.ruba}')))),
                        ]),
                    ],
                    headerStyle: pw.TextStyle(
                      font: amiriFont,
                      fontFallback: [outfitFont],
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                    headerDirection: pw.TextDirection.rtl,
                    tableDirection: pw.TextDirection.rtl,
                    cellStyle: pw.TextStyle(
                      font: amiriFont,
                      fontFallback: [outfitFont],
                      fontSize: 9,
                    ),
                    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
                    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.2),
                      1: pw.FlexColumnWidth(0.8),
                      2: pw.FlexColumnWidth(2.2),
                      3: pw.FlexColumnWidth(2.2),
                      4: pw.FlexColumnWidth(1.2),
                    },
                  ),
              ],
            ),
          ),

          // ═══ 5. والدین کے لیے پیغام ═══════════════════════════
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.red300, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.red700,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: txtCenter(
                    t('parentsMessageTitle'),
                    size: 12,
                    fw: pw.FontWeight.bold,
                    col: PdfColors.white,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: txt(
                    t('parentsMessage'),
                    size: 8.5,
                    col: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),

          // ═══ 6. FOOTER ═══════════════════════════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: txtCenter(
              '${t('generatedByHifzTracker')}',
              size: 8,
              col: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  // ── Collective monthly PDF ────────────────────────────────────────────────

  Future<Uint8List> buildCollectivePdfReport({
    required DateTime month,
    required List<Student> students,
    required List<DailyRecord> records,
    required ReportStrings t,
    required String locale,
  }) async {
    final monthKey = AppDateUtils.monthKey(month);
    final theme = await _buildTheme();
    final doc = pw.Document(theme: theme);

    // NOTE: Only Amiri (Naskh) for Arabic/Urdu — JameelNooriNastaleeq can't
    // render in the Dart pdf package.
    final outfitData = await rootBundle.load('assets/fonts/Outfit.ttf');
    final outfitFont = pw.Font.ttf(outfitData);
    final amiriData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final amiriFont = pw.Font.ttf(amiriData);

    pw.Widget cText(
      String raw, {
      double fontSize = 10,
      pw.FontWeight fontWeight = pw.FontWeight.normal,
      PdfColor color = PdfColors.black,
    }) {
      final shaped = _shape(raw);
      final isRtl = _isRtl(raw);
      return pw.Text(
        shaped,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        style: pw.TextStyle(
          font: isRtl ? amiriFont : outfitFont,
          fontFallback: [outfitFont],
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      );
    }

    final cleanRows = <List<String>>[
      for (var i = 0; i < students.length; i++)
        _processRow([
          '${i + 1}',
          students[i].name,
          '${StudentMonthlyStats.compute(
            records: records
                .where((r) => r.studentId == students[i].id && r.date.startsWith(monthKey))
                .toList(),
            linesPerPage: students[i].mushafLines,
          ).presentDays}',
          '${StudentMonthlyStats.compute(
            records: records
                .where((r) => r.studentId == students[i].id && r.date.startsWith(monthKey))
                .toList(),
            linesPerPage: students[i].mushafLines,
          ).sabaqLessons}',
          '${StudentMonthlyStats.compute(
            records: records
                .where((r) => r.studentId == students[i].id && r.date.startsWith(monthKey))
                .toList(),
            linesPerPage: students[i].mushafLines,
          ).sabqiLessons}',
          '${StudentMonthlyStats.compute(
            records: records
                .where((r) => r.studentId == students[i].id && r.date.startsWith(monthKey))
                .toList(),
            linesPerPage: students[i].mushafLines,
          ).manzilLessons}',
        ]),
    ];

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          theme: theme,
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              cText(t('collectiveReport'), fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
              cText(AppDateUtils.formatMonthYear(month, 'en'), fontSize: 13, color: PdfColors.grey700),
            ],
          ),
          pw.SizedBox(height: 16),
          if (cleanRows.isEmpty)
            cText('No students found.', fontSize: 11, color: PdfColors.grey600)
          else
            pw.TableHelper.fromTextArray(
              headers: _processRow(['#', 'Name', 'Att', 'Sabaq', 'Sabqi', 'Manzil']),
              data: cleanRows,
              headerStyle: pw.TextStyle(
                font: amiriFont,
                fontFallback: [outfitFont],
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
              headerDirection: pw.TextDirection.rtl,
              tableDirection: pw.TextDirection.rtl,
              cellStyle: pw.TextStyle(
                font: amiriFont,
                fontFallback: [outfitFont],
                fontSize: 10,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
              cellAlignments: {
                0: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            ),
          pw.SizedBox(height: 12),
          cText(t('generatedOn'), fontSize: 9, color: PdfColors.grey600),
        ],
      ),
    );
    return doc.save();
  }

  // ── Direct sharing (WhatsApp / SMS) ──────────────────────────────────────

  Future<bool> canOpenWhatsApp(String phone) async {
    final clean = _cleanPhone(phone);
    if (clean.isEmpty) return false;
    try {
      return await canLaunchUrl(Uri.parse('https://wa.me/$clean'));
    } catch (_) {
      return false;
    }
  }

  Future<void> sendViaWhatsApp(String phone, String text) async {
    final clean = _cleanPhone(phone);
    final uri = Uri.parse(
      'https://wa.me/$clean?text=${Uri.encodeComponent(text)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> sendViaSms(String phone, String text) async {
    final clean = _cleanPhone(phone);
    final encoded = Uri.encodeComponent(text);
    final uris = [
      Uri.parse('sms:$clean?body=$encoded'),
      Uri.parse('sms:$clean&body=$encoded'),
      Uri.parse('smsto:$clean?body=$encoded'),
    ];
    for (final uri in uris) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        continue;
      }
    }
    throw Exception('No SMS handler available');
  }

  static String _cleanPhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d]'), '');

  // ── Sharing ───────────────────────────────────────────────────────────────

  Future<void> shareText(String text, {String subject = ''}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  Future<void> sharePdf(Uint8List bytes, {required String filename}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }
}

/// Aggregated monthly stats for one student (khulasa) — shared by the report
/// screens, the text report and the PDF export.
class StudentMonthlyStats {
  final int presentDays;
  final int absentDays;
  final int sabaqLessons;
  final int sabaqPages;
  final int sabqiLessons;
  final int sabqiCompletedPages;
  final int sabqiTotalPages;
  final int manzilLessons;
  final int manzilRubas;
  final int missedSabaq;
  final int missedSabqi;
  final int missedManzil;

  const StudentMonthlyStats({
    required this.presentDays,
    required this.absentDays,
    required this.sabaqLessons,
    required this.sabaqPages,
    required this.sabqiLessons,
    required this.sabqiCompletedPages,
    required this.sabqiTotalPages,
    required this.manzilLessons,
    required this.manzilRubas,
    required this.missedSabaq,
    required this.missedSabqi,
    required this.missedManzil,
  });

  factory StudentMonthlyStats.compute({
    required List<DailyRecord> records,
    int linesPerPage = AppConstants.defaultMushafLines,
  }) {
    var presentDays = 0;
    var absentDays = 0;
    var sabaqLessons = 0;
    var sabaqPages = 0;
    var sabqiLessons = 0;
    var manzilLessons = 0;
    var manzilRubas = 0;
    var missedSabaq = 0;
    var missedSabqi = 0;
    var missedManzil = 0;

    SabqiEntry? latestSabqi;
    for (final r in records) {
      if (r.present) {
        presentDays++;
      } else {
        absentDays++;
      }
      if (r.present && r.sabaq != null) {
        sabaqLessons++;
        sabaqPages += r.sabaq!.pages;
      } else {
        missedSabaq++;
      }
      if (r.present && r.sabqi != null) {
        sabqiLessons++;
        latestSabqi = r.sabqi;
      } else {
        missedSabqi++;
      }
      if (r.present && r.manzil != null) {
        manzilLessons++;
        manzilRubas++;
      } else {
        missedManzil++;
      }
    }

    var sabqiCompleted = 0;
    var sabqiTotal = 0;
    if (latestSabqi != null) {
      final calc = MathEngine.computeParaSabqi(
        juz: latestSabqi.juz,
        startPage: latestSabqi.startPage,
        endPage: latestSabqi.endPage,
        heardPage: latestSabqi.heardPage,
        linesPerPage: linesPerPage,
      );
      sabqiCompleted = calc.completedPages;
      sabqiTotal = calc.totalPages;
    }

    return StudentMonthlyStats(
      presentDays: presentDays,
      absentDays: absentDays,
      sabaqLessons: sabaqLessons,
      sabaqPages: sabaqPages,
      sabqiLessons: sabqiLessons,
      sabqiCompletedPages: sabqiCompleted,
      sabqiTotalPages: sabqiTotal,
      manzilLessons: manzilLessons,
      manzilRubas: manzilRubas,
      missedSabaq: missedSabaq,
      missedSabqi: missedSabqi,
      missedManzil: missedManzil,
    );
  }

  String sabaqGrade(
    ReportStrings t, {
    int behtareen = 26,
    int behtar = 20,
    int acha = 15,
  }) => _grade(t, sabaqLessons, behtareen: behtareen, behtar: behtar, acha: acha);

  String sabqiGrade(
    ReportStrings t, {
    int behtareen = 26,
    int behtar = 20,
    int acha = 15,
  }) => _grade(t, sabqiLessons, behtareen: behtareen, behtar: behtar, acha: acha);

  String manzilGrade(
    ReportStrings t, {
    int behtareen = 26,
    int behtar = 20,
    int acha = 15,
  }) => _grade(t, manzilLessons, behtareen: behtareen, behtar: behtar, acha: acha);

  int _bestScore(int behtareen, int behtar, int acha) {
    if (sabaqLessons >= behtareen &&
        sabqiLessons >= behtareen &&
        manzilLessons >= behtareen) return 3;
    if (sabaqLessons >= behtar &&
        sabqiLessons >= behtar &&
        manzilLessons >= behtar) return 2;
    if (sabaqLessons >= acha &&
        sabqiLessons >= acha &&
        manzilLessons >= acha) return 1;
    return 0;
  }

  String overallGrade(
    ReportStrings t, {
    int behtareen = 26,
    int behtar = 20,
    int acha = 15,
  }) {
    final best = _bestScore(behtareen, behtar, acha);
    if (best == 3) return t('gradeExcellent');
    if (best == 2) return t('gradeGood');
    if (best == 1) return t('gradePassable');
    return t('gradeWeak');
  }

  static String _grade(
    ReportStrings t,
    int days, {
    int behtareen = 26,
    int behtar = 20,
    int acha = 15,
  }) {
    if (days >= behtareen) return t('gradeExcellent');
    if (days >= behtar) return t('gradeGood');
    if (days >= acha) return t('gradePassable');
    return t('gradeWeak');
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Screenshot-based PDF generation methods
// These capture Flutter widgets as images and embed them into PDFs.
// This solves Arabic/Urdu text rendering because Flutter's own rendering
// engine handles Nastaleeq fonts perfectly.
// ═════════════════════════════════════════════════════════════════════════════

class ScreenshotPdfExport {
  ScreenshotPdfExport._();

  static final ScreenshotPdfExport instance = ScreenshotPdfExport._();

  /// Build daily report PDF — renders the polished A4 report widget with the
  /// app's real fonts (Nastaleeq/RTL) and slices it into A4 pages.
  Future<Uint8List> buildDailyPdfReport({
    required BuildContext context,
    required DateTime date,
    required String section,
    required List<Student> students,
    required List<DailyRecord> records,
  }) async {
    final l10n = AppLocalizations.of(context);
    return WidgetPdfCapture.widgetToA4Pdf(
      DailyReportPdfWidget(
        date: date,
        section: section,
        students: students,
        records: records,
        l10n: l10n,
      ),
      context: context,
    );
  }

  /// Build student monthly report PDF — renders the polished A4 report widget
  /// with the app's real fonts (Nastaleeq/RTL) and slices it into A4 pages.
  Future<Uint8List> buildStudentMonthlyPdfReport({
    required BuildContext context,
    required Student student,
    required DateTime month,
    required List<DailyRecord> records,
    required AppSettings settings,
  }) async {
    final l10n = AppLocalizations.of(context);
    return WidgetPdfCapture.widgetToA4Pdf(
      StudentMonthlyReportPdfWidget(
        student: student,
        month: month,
        records: records,
        settings: settings,
        l10n: l10n,
      ),
      context: context,
    );
  }

  /// Build collective report PDF — renders the polished A4 report widget with
  /// the app's real fonts (Nastaleeq/RTL) and slices it into A4 pages.
  Future<Uint8List> buildCollectivePdfReport({
    required BuildContext context,
    required DateTime month,
    required List<Student> students,
    required List<DailyRecord> records,
  }) async {
    final l10n = AppLocalizations.of(context);
    return WidgetPdfCapture.widgetToA4Pdf(
      CollectiveReportPdfWidget(
        month: month,
        students: students,
        records: records,
        l10n: l10n,
      ),
      context: context,
    );
  }
}
