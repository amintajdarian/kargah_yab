import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:kargah_yab/controllers/form_controller.dart';
import 'package:kargah_yab/controllers/report_controller.dart';
import 'package:kargah_yab/models/workshop_form.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen> {
  String? _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(formControllerProvider.notifier).loadAllWorkshops();
    });
  }

  Future<void> _pickDate() async {
    final Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.now(),
      firstDate: Jalali(1399, 1),
      lastDate: Jalali(1410, 12),
    );

    if (picked != null) {
      setState(() {
        _selectedDateFilter = '${picked.year}/${picked.month}/${picked.day}';
      });
      ref.read(formControllerProvider.notifier).loadWorkshopsByDate(_selectedDateFilter!);
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedDateFilter = null;
    });
    ref.read(formControllerProvider.notifier).loadAllWorkshops();
  }

  Future<void> _exportReport(List<WorkshopFormModel> list) async {
    final String dateLabel = _selectedDateFilter ?? 'همه_تاریخ_ها';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('خروجی اکسل'),
          content: const Text('آیا می‌خواهید فایل در پوشه Download ذخیره شود؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('خیر، انتخاب مسیر دیگر'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
              child: const Text('بله، ذخیره در پوشه Download'),
            ),
          ],
        ),
      ),
    );

    if (confirm == null) return;

    ref.read(reportControllerProvider.notifier).exportToExcel(list, dateLabel, directSave: confirm);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(formControllerProvider);
    final reportState = ref.watch(reportControllerProvider);

    ref.listen<ReportState>(reportControllerProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: theme.colorScheme.secondary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.redAccent),
        );
      }
    });

    final workshops = formState.workshopsList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌ها و خروجی اکسل'),
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month, color: Colors.white),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _selectedDateFilter == null
                                    ? 'فیلتر تاریخ'
                                    : 'تاریخ: $_selectedDateFilter',
                              ),
                            ),
                          ),
                        ),
                        if (_selectedDateFilter != null) ...[
                          Gap(8.w),
                          IconButton.filled(
                            onPressed: _clearFilter,
                            icon: const Icon(Icons.filter_alt_off),
                            style: IconButton.styleFrom(backgroundColor: Colors.redAccent),
                            tooltip: 'حذف فیلتر',
                          ),
                        ],
                        Gap(8.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: reportState.isExporting ? null : () => _exportReport(workshops),
                            icon: const Icon(Icons.file_download, color: Colors.white),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('خروجی اکسل'),
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    Gap(16.h),

                    Text(
                      _selectedDateFilter == null
                          ? 'لیست تمامی کارگاه‌های صنعتی ثبت شده (${workshops.length})'
                          : 'کارگاه‌های صنعتی ثبت شده در تاریخ $_selectedDateFilter (${workshops.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Gap(12.h),

                    Expanded(
                      child: workshops.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open, size: 64.r, color: Colors.grey),
                                  Gap(12.h),
                                  Text(
                                    _selectedDateFilter == null
                                        ? 'هیچ کارگاه صنعتی ثبت نشده است.'
                                        : 'هیچ کارگاه صنعتی در این تاریخ ثبت نشده است.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: workshops.length,
                              itemBuilder: (context, index) {
                                final item = workshops[index];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.w),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${index + 1}. ${item.factoryName}',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () =>
                                                  _confirmDelete(item.id, item.factoryName),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 16),

                                        _buildDetailRow(
                                          Icons.person,
                                          'مدیر کارگاه صنعتی',
                                          item.managerName,
                                        ),
                                        _buildDetailRow(Icons.phone, 'تلفن ۱', item.phone1),
                                        if (item.phone2.isNotEmpty)
                                          _buildDetailRow(
                                            Icons.phone_android,
                                            'تلفن ۲',
                                            item.phone2,
                                          ),
                                        _buildDetailRow(
                                          Icons.inventory,
                                          'محصول تولیدی',
                                          item.product,
                                        ),
                                        _buildDetailRow(
                                          Icons.location_city,
                                          'شهرک صنعتی',
                                          item.industrialTown,
                                        ),
                                        _buildDetailRow(Icons.location_on, 'آدرس', item.address),

                                        if (item.latitude != null) ...[
                                          Gap(4.h),
                                          _buildDetailRow(
                                            Icons.gps_fixed,
                                            'موقعیت (GPS)',
                                            '${item.latitude!.toStringAsFixed(6)}, ${item.longitude!.toStringAsFixed(6)}',
                                          ),
                                        ],
                                        _buildDetailRow(
                                          Icons.date_range,
                                          'تاریخ ثبت',
                                          item.createdAt,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            if (reportState.isExporting)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'در حال تولید و ذخیره فایل اکسل...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.r, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 13,
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int? id, String name) async {
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف کارگاه صنعتی'),
          content: Text('آیا از حذف اطلاعات کارگاه صنعتی "$name" مطمئن هستید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('حذف شود'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await ref.read(formControllerProvider.notifier).deleteWorkshopEntry(id);
    }
  }
}
