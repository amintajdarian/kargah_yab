import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../models/workshop_form.dart';

class ReportState {
  final bool isExporting;
  final String? successMessage;
  final String? errorMessage;

  ReportState({this.isExporting = false, this.successMessage, this.errorMessage});

  ReportState copyWith({bool? isExporting, String? successMessage, String? errorMessage}) {
    return ReportState(
      isExporting: isExporting ?? this.isExporting,
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReportController extends StateNotifier<ReportState> {
  ReportController() : super(ReportState());

  Future<void> exportToExcel(List<WorkshopFormModel> workshops, String dateLabel, {bool directSave = true}) async {
    state = ReportState(isExporting: true);

    if (workshops.isEmpty) {
      state = ReportState(
        isExporting: false,
        errorMessage: 'هیچ داده‌ای برای این تاریخ وجود ندارد.',
      );
      return;
    }

    // Create a new Excel Document.
    final xlsio.Workbook workbook = xlsio.Workbook();
    // Accessing leaf sheet through index.
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'گزارش کارگاه‌ها';
    sheet.isRightToLeft = true; // Persian layout is Right-to-Left

    try {
      final headers = WorkshopFormModel.getExcelHeaders();
      final totalColumns = headers.length;

      // --- STYLES ---

      // Title Style
      final xlsio.Style titleStyle = workbook.styles.add('TitleStyle');
      titleStyle.backColor = '#4F81BD';
      titleStyle.fontColor = '#FFFFFF';
      titleStyle.fontSize = 14;
      titleStyle.bold = true;
      titleStyle.hAlign = xlsio.HAlignType.center;
      titleStyle.vAlign = xlsio.VAlignType.center;

      // Header Style
      final xlsio.Style headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.backColor = '#DCE6F1';
      headerStyle.fontColor = '#1F4E78';
      headerStyle.fontSize = 11;
      headerStyle.bold = true;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.vAlign = xlsio.VAlignType.center;
      headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      headerStyle.borders.all.color = '#A6A6A6';

      // Cell Style Even
      final xlsio.Style cellStyleEven = workbook.styles.add('CellStyleEven');
      cellStyleEven.backColor = '#F2F2F2';
      cellStyleEven.fontSize = 10;
      cellStyleEven.hAlign = xlsio.HAlignType.center;
      cellStyleEven.vAlign = xlsio.VAlignType.center;
      cellStyleEven.borders.all.lineStyle = xlsio.LineStyle.thin;
      cellStyleEven.borders.all.color = '#D9D9D9';

      // Cell Style Odd
      final xlsio.Style cellStyleOdd = workbook.styles.add('CellStyleOdd');
      cellStyleOdd.backColor = '#FFFFFF';
      cellStyleOdd.fontSize = 10;
      cellStyleOdd.hAlign = xlsio.HAlignType.center;
      cellStyleOdd.vAlign = xlsio.VAlignType.center;
      cellStyleOdd.borders.all.lineStyle = xlsio.LineStyle.thin;
      cellStyleOdd.borders.all.color = '#D9D9D9';

      // --- CONTENT ---

      // Row 1: Report Title (Merged)
      final xlsio.Range titleRange = sheet.getRangeByIndex(1, 1, 1, totalColumns);
      titleRange.merge();
      titleRange.setText('گزارش روزانه کارگاه‌های صنعتی ثبت شده - تاریخ: $dateLabel');
      titleRange.cellStyle = titleStyle;
      sheet.setRowHeightInPixels(1, 60);

      // Row 2: Spacer (Empty)
      sheet.setRowHeightInPixels(2, 10);

      // Row 3: Headers
      for (int i = 0; i < headers.length; i++) {
        final xlsio.Range headerCell = sheet.getRangeByIndex(3, i + 1);
        headerCell.setText(headers[i]);
        headerCell.cellStyle = headerStyle;
      }
      sheet.setRowHeightInPixels(3, 35);

      // Row 4 onwards: Data Rows
      for (int rowIndex = 0; rowIndex < workshops.length; rowIndex++) {
        final item = workshops[rowIndex];
        final rowData = item.toExcelRow(rowIndex + 1);
        final currentRowIdx = 4 + rowIndex;
        final currentStyle = rowIndex % 2 == 0 ? cellStyleOdd : cellStyleEven;

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final xlsio.Range cell = sheet.getRangeByIndex(currentRowIdx, colIndex + 1);
          final val = rowData[colIndex];

          if (val == null) {
            cell.setText('');
          } else if (val is num) {
            cell.setNumber(val.toDouble());
          } else {
            cell.setText(val.toString());
          }
          cell.cellStyle = currentStyle;
        }
        sheet.setRowHeightInPixels(currentRowIdx, 30);
      }

      // Column Widths
      for (int i = 1; i <= totalColumns; i++) {
        sheet.setColumnWidthInPixels(i, 120);
      }

      // Save and dispose.
      final List<int> excelBytes = workbook.saveAsStream();
      workbook.dispose();

      final fileName = 'kargah_report_${dateLabel.replaceAll("/", "_")}.xlsx';

      // Attempt to save to downloads folder directly on Android
      bool savedSuccessfully = false;
      String? savedPath;

      if (directSave && Platform.isAndroid) {
        // Request Storage permission
        var status = await Permission.storage.status;
        if (status.isDenied) {
          await Permission.storage.request();
        }

        // Standard public Download directory
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          try {
            final uniqueFileName = 'kargah_report_${dateLabel.replaceAll("/", "_")}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
            final filePath = '${downloadDir.path}/$uniqueFileName';
            final file = File(filePath);
            await file.writeAsBytes(excelBytes);
            savedSuccessfully = true;
            savedPath = filePath;
          } catch (e) {
            // Direct write failed
          }
        }
      }

      if (savedSuccessfully) {
        state = ReportState(
          isExporting: false,
          successMessage: 'فایل گزارش با موفقیت در پوشه Download ذخیره شد:\n$savedPath',
        );
      } else {
        // Fallback to File Picker
        final selectedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'ذخیره گزارش اکسل',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: Uint8List.fromList(excelBytes),
        );

        if (selectedPath != null) {
          if (!Platform.isAndroid) {
            final file = File(selectedPath);
            await file.writeAsBytes(excelBytes);
          }
          state = ReportState(
            isExporting: false,
            successMessage: 'گزارش در مسیر زیر ذخیره شد:\n$selectedPath',
          );
        } else {
          state = ReportState(
            isExporting: false,
            successMessage: null, // User cancelled
          );
        }
      }
    } catch (e) {
      state = ReportState(isExporting: false, errorMessage: 'خطا در تولید گزارش اکسل: $e');
    }
  }
}

final reportControllerProvider = StateNotifierProvider<ReportController, ReportState>((ref) {
  return ReportController();
});
