import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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

    try {
      // Create Excel document
      final excel = Excel.createExcel();
      final sheetName = 'گزارش کارگاه‌های صنعتی';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];
      sheet.isRTL = true; // Persian layout is Right-to-Left

      // Define standard styling options using correct excel package properties
      final CellStyle titleStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#4F81BD'), // Soft Blue
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final CellStyle headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#DCE6F1'), // Light gray/blue
        fontColorHex: ExcelColor.fromHexString('#1F4E78'), // Dark blue
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#A6A6A6'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#A6A6A6'),
        ),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#A6A6A6'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#A6A6A6'),
        ),
      );

      final CellStyle cellStyleEven = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F2F2F2'), // Soft gray
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#D9D9D9'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#D9D9D9'),
        ),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#D9D9D9'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#D9D9D9'),
        ),
      );

      final CellStyle cellStyleOdd = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'), // White
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#D9D9D9'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#D9D9D9'),
        ),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#D9D9D9'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#D9D9D9'),
        ),
      );

      final headers = WorkshopFormModel.getExcelHeaders();
      final totalColumns = headers.length;

      // Row 0: Report Title (Merged)
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: 0),
        customValue: TextCellValue('گزارش روزانه کارگاه‌های صنعتی ثبت شده - تاریخ: $dateLabel'),
      );

      // Style Title Cell
      for (int i = 0; i < totalColumns; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = titleStyle;
      }
      sheet.setRowHeight(0, 45);

      // Row 1: Empty Spacer
      sheet.setRowHeight(1, 15);

      // Row 2: Headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      sheet.setRowHeight(2, 30);

      // Row 3 onwards: Data Rows
      for (int rowIndex = 0; rowIndex < workshops.length; rowIndex++) {
        final item = workshops[rowIndex];
        final rowData = item.toExcelRow(rowIndex + 1);
        final currentRowIdx = 3 + rowIndex;
        final currentStyle = rowIndex % 2 == 0 ? cellStyleOdd : cellStyleEven;

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: currentRowIdx),
          );

          final val = rowData[colIndex];
          if (val == null) {
            cell.value = null;
          } else if (val is num) {
            cell.value = DoubleCellValue(val.toDouble());
          } else {
            cell.value = TextCellValue(val.toString());
          }
          cell.cellStyle = currentStyle;
        }
        sheet.setRowHeight(currentRowIdx, 25);
      }

      // Auto-fit column widths (with padding)
      for (int i = 0; i < totalColumns; i++) {
        sheet.setColumnWidth(i, 20.0); // standard clean width
      }

      // Encode the Excel file
      final excelBytes = excel.encode();
      if (excelBytes == null) {
        throw Exception('خطا در فشرده‌سازی فایل اکسل');
      }

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
            // Direct write failed (e.g. Android 13+ restrictions), fallback to FilePicker
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
          // If we got bytes and wrote it, or need to write manually
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
