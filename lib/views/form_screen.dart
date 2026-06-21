import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../controllers/auth_controller.dart';
import '../controllers/form_controller.dart' hide FormState;
import '../controllers/location_controller.dart';
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

  String? _selectedTown;

  final List<String> _industrialTowns = [
    'شهر سنگ تهران',
    'شهرک صنعتی چهاردانگه',
    'شهرک صنعتی سهند تهران',
    'شهرک صنعتی خرمدشت تهران',
    'شهرک صنعتی قرچک',
    'شهرک صنعتی نصیرآباد',
    'شهرک صنعتی پرند',
    'ناحیه صنعتی دهک',
    'شهرک صنعتی خوارزمی',
    'شهرک صنعتی عباس آباد',
    'شهرک صنعتی شمس آباد',
    'ناحیه صنعتی بیجین ری',
    'شهرک صنعتی پیشوا',
    'شهرک صنعتی پایتخت',
    'ناحیه صنعتی آیینه ورزان',
    'شهرک صنعتی چرمشهر',
    'شهرک صنعتی سالاریه',
    'شهرک صنعتی فیروزکوه',
  ];

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
    setState(() {
      _selectedTown = null;
    });
    ref.read(locationProvider.notifier).clearLocation();
  }

  Future<void> _submitForm(String surveyorName) async {
    final locState = ref.read(locationProvider);

    if (locState.latitude == null || locState.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفا ابتدا موقعیت جغرافیایی (GPS) را تعیین کنید.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final Jalali now = Jalali.now();
      final dateStr =
          '${now.year}/${now.month}/${now.day} ${DateTime.now().hour}:${DateTime.now().minute}';

      final success = await ref.read(formControllerProvider.notifier).saveWorkshop(
            factoryName: _factoryNameController.text,
            managerName: _managerNameController.text,
            phone1: _phone1Controller.text,
            phone2: _phone2Controller.text,
            product: _productController.text,
            industrialTown: _selectedTown ?? '',
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
            content: const Text('اطلاعات کارگاه صنعتی با موفقیت ذخیره شد.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        _clearForm();
        ref.read(locationProvider.notifier).fetchCurrentLocation();
      }
    }
  }

  Widget _buildLabel(String text, bool isRequired) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black54, fontSize: 14),
        children: isRequired
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                )
              ]
            : [],
      ),
    );
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
      appBar: AppBar(title: const Text('ثبت اطلاعات کارگاه صنعتی')),
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
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                    'مشخصات کارگاه صنعتی',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _factoryNameController,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'لطفا نام کارگاه صنعتی را وارد کنید'
                        : null,
                    decoration: InputDecoration(
                      label: _buildLabel('نام کارگاه صنعتی', true),
                      prefixIcon: const Icon(Icons.factory),
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _managerNameController,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'لطفا مسئول کارگاه صنعتی را وارد کنید'
                        : null,
                    decoration: InputDecoration(
                      label: _buildLabel('مسئول کارگاه صنعتی', true),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _phone1Controller,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'تلفن ۱ ضروری است';
                      if (val.length != 11) return 'شماره تلفن باید ۱۱ رقم باشد';
                      return null;
                    },
                    decoration: InputDecoration(
                      label: _buildLabel('تلفن کارگاه ۱', true),
                      prefixIcon: const Icon(Icons.phone),
                      counterText: '',
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _phone2Controller,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    validator: (val) {
                      if (val != null && val.isNotEmpty && val.length != 11) {
                        return 'شماره تلفن باید ۱۱ رقم باشد';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      label: _buildLabel('تلفن کارگاه ۲', false),
                      prefixIcon: const Icon(Icons.phone),
                      counterText: '',
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _productController,
                    decoration: InputDecoration(
                      label: _buildLabel('محصول تولیدی', false),
                      prefixIcon: const Icon(Icons.inventory),
                    ),
                  ),
                  Gap(12.h),

                  DropdownButtonFormField<String>(
                    value: _selectedTown,
                    onChanged: (val) {
                      setState(() {
                        _selectedTown = val;
                      });
                    },
                    validator: (val) =>
                        val == null || val.isEmpty ? 'لطفا شهرک صنعتی را انتخاب کنید' : null,
                    items: _industrialTowns.map((town) {
                      return DropdownMenuItem(
                        value: town,
                        child: Text(town),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      label: _buildLabel('شهرک صنعتی', true),
                      prefixIcon: const Icon(Icons.location_city),
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    validator: (val) => val == null || val.trim().isEmpty ? 'آدرس ضروری است' : null,
                    decoration: InputDecoration(
                      label: _buildLabel('آدرس کارگاه صنعتی', true),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      label: _buildLabel('سایت', false),
                      prefixIcon: const Icon(Icons.language),
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _socialMediaController,
                    decoration: InputDecoration(
                      label: _buildLabel('شبکه اجتماعی و پیامرسان', false),
                      prefixIcon: const Icon(Icons.chat),
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _neshanAddressController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      label: _buildLabel('آدرس', false),
                      prefixIcon: const Icon(Icons.map),
                    ),
                  ),
                  Gap(12.h),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      label: _buildLabel('توضیحات', false),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                  Gap(20.h),

                  Text(
                    'موقعیت جغرافیایی دقیق',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Gap(8.h),

                  Card(
                    color: locationState.latitude != null
                        ? Colors.green.withOpacity(0.05)
                        : theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(
                        color: locationState.latitude != null
                            ? Colors.green.withOpacity(0.5)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
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
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text('عرض جغرافیایی', style: TextStyle(fontSize: 10)),
                                      Text(
                                        locationState.latitude!.toStringAsFixed(6),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 30, color: Colors.green.withOpacity(0.3)),
                                  Column(
                                    children: [
                                      const Text('طول جغرافیایی', style: TextStyle(fontSize: 10)),
                                      Text(
                                        locationState.longitude!.toStringAsFixed(6),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            const Text(
                              'موقعیت مکانی یافت نشد.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          Gap(12.h),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: locationState.isFetching
                                      ? null
                                      : () async {
                                          final status = await Permission.location.request();
                                          if (status.isGranted && mounted) {
                                            ref.read(locationProvider.notifier).fetchCurrentLocation();
                                          } else if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'برای انتخاب موقعیت از روی نقشه به مجوز مکان نیاز است.',
                                                ),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('مکان‌یابی مجدد'),
                                ),
                              ),
                              Gap(8.w),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final status = await Permission.location.request();
                                    if (status.isGranted && mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const MapScreen()),
                                      );
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'برای انتخاب موقعیت از روی نقشه به مجوز مکان نیاز است.',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.map),
                                  label: const Text('انتخاب از روی نقشه'),
                                ),
                              ),
                            ],
                          ),
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
