import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../controllers/auth_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/form_controller.dart' hide FormState;
import 'map_screen.dart';

class FormScreen extends ConsumerStatefulWidget {
  const FormScreen({super.key});

  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _factoryNameController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _productController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _socialMediaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _neshanAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).fetchCurrentLocation();
    });
  }

  @override
  void dispose() {
    _factoryNameController.dispose();
    _managerNameController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _productController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _socialMediaController.dispose();
    _descriptionController.dispose();
    _neshanAddressController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _factoryNameController.clear();
    _managerNameController.clear();
    _phone1Controller.clear();
    _phone2Controller.clear();
    _productController.clear();
    _addressController.clear();
    _websiteController.clear();
    _socialMediaController.clear();
    _descriptionController.clear();
    _neshanAddressController.clear();
    ref.read(locationProvider.notifier).clearLocation();
  }

  Future<void> _submitForm(String surveyorName) async {
    if (_formKey.currentState!.validate()) {
      final locState = ref.read(locationProvider);

      final Jalali now = Jalali.now();
      final dateStr = '${now.year}/${now.month}/${now.day} ${DateTime.now().hour}:${DateTime.now().minute}';

      final success = await ref.read(formControllerProvider.notifier).saveWorkshop(
            factoryName: _factoryNameController.text,
            managerName: _managerNameController.text,
            phone1: _phone1Controller.text,
            phone2: _phone2Controller.text,
            product: _productController.text,
            address: _addressController.text,
            website: _websiteController.text,
            socialMedia: _socialMediaController.text,
            description: _descriptionController.text,
            latitude: locState.latitude,
            longitude: locState.longitude,
            neshanAddress: _neshanAddressController.text,
            registeredBy: surveyorName,
            dateStr: dateStr,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('اطلاعات کارخانه با موفقیت ذخیره شد.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        _clearForm();
        ref.read(locationProvider.notifier).fetchCurrentLocation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final locationState = ref.watch(locationProvider);
    final formState = ref.watch(formControllerProvider);

    final surveyorName = authState.maybeWhen(
      data: (name) => name ?? 'ثبت‌کننده ناشناس',
      orElse: () => 'در حال بارگذاری...',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت اطلاعات کارخانه'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, color: Colors.blueGrey),
                              Gap(8.w),
                              Text(
                                'ثبت‌کننده: $surveyorName',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            'تاریخ: ${Jalali.now().year}/${Jalali.now().month}/${Jalali.now().day}',
                            style: theme.textTheme.titleSmall?.copyWith(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gap(16.h),

                  Text(
                    'مشخصات کارخانه',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _factoryNameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'لطفا نام کارخانه را وارد کنید' : null,
                    decoration: const InputDecoration(labelText: 'نام کارخانه', prefixIcon: Icon(Icons.factory)),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _managerNameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'لطفا مسئول کارخانه را وارد کنید' : null,
                    decoration: const InputDecoration(labelText: 'مسئول کارخانه', prefixIcon: Icon(Icons.person)),
                  ),
                  Gap(12.h),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phone1Controller,
                          keyboardType: TextInputType.phone,
                          validator: (val) => val == null || val.trim().isEmpty ? 'تلفن ۱ ضروری است' : null,
                          decoration: const InputDecoration(labelText: 'تلفن کارخانه ۱', prefixIcon: Icon(Icons.phone)),
                        ),
                      ),
                      Gap(12.w),
                      Expanded(
                        child: TextFormField(
                          controller: _phone2Controller,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'تلفن کارخانه ۲', prefixIcon: Icon(Icons.phone)),
                        ),
                      ),
                    ],
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _productController,
                    decoration: const InputDecoration(labelText: 'محصول تولیدی', prefixIcon: Icon(Icons.inventory)),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    validator: (val) => val == null || val.trim().isEmpty ? 'آدرس ضروری است' : null,
                    decoration: const InputDecoration(labelText: 'آدرس کارخانه', prefixIcon: Icon(Icons.location_on)),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'سایت', prefixIcon: Icon(Icons.language)),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _socialMediaController,
                    decoration: const InputDecoration(labelText: 'شبکه اجتماعی و پیامرسان', prefixIcon: Icon(Icons.chat)),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _neshanAddressController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'آدرس نشان', prefixIcon: Icon(Icons.map)),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'توضیحات', prefixIcon: Icon(Icons.description)),
                  ),
                  Gap(20.h),

                  Text(
                    'موقعیت جغرافیایی دقیق',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Gap(8.h),

                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        children: [
                          if (locationState.isFetching)
                            const LinearProgressIndicator()
                          else if (locationState.errorMessage != null)
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                Gap(8.w),
                                Expanded(
                                  child: Text(
                                    locationState.errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                  ),
                                ),
                              ],
                            )
                          else if (locationState.latitude != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('عرض: ${locationState.latitude!.toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('طول: ${locationState.longitude!.toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          else
                            const Text('موقعیت مکانی یافت نشد.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Gap(12.h),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: locationState.isFetching ? null : () => ref.read(locationProvider.notifier).fetchCurrentLocation(),
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('مکان‌یابی مجدد'),
                                ),
                              ),
                              Gap(8.w),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
                                  },
                                  icon: const Icon(Icons.map),
                                  label: const Text('انتخاب از روی نقشه'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  Gap(24.h),

                  formState.isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: () => _submitForm(surveyorName),
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('ثبت و ذخیره اطلاعات'),
                        ),
                  Gap(12.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
