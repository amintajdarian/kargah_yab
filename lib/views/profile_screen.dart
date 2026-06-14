import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final currentName = ref.read(authProvider).maybeWhen(
          data: (name) => name ?? '',
          orElse: () => '',
        );
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final newName = _nameController.text.trim();
      await ref.read(authProvider.notifier).updateUsername(newName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('نام کاربری با موفقیت ویرایش شد.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    }
  }

  Future<void> _resetApp() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('خروج از حساب کاربری'),
          content: const Text('آیا مطمئن هستید که می‌خواهید نام خود را حذف کرده و از برنامه خارج شوید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).clearUsername();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    final surveyorName = authState.maybeWhen(
      data: (name) => name ?? '',
      orElse: () => '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل کاربری'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Avatar & Title
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50.r,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.account_circle,
                            size: 80.r,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Gap(12.h),
                        Text(
                          surveyorName,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ثبت‌کننده اطلاعات کارگاه‌ها',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  Gap(36.h),

                  // Edit Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ویرایش مشخصات',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Gap(16.h),
                          TextFormField(
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'لطفا نام خود را وارد کنید';
                              }
                              if (value.trim().length < 3) {
                                return 'نام باید حداقل ۳ حرف باشد';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'نام و نام خانوادگی جدید',
                              prefixIcon: Icon(Icons.edit),
                            ),
                          ),
                          Gap(20.h),
                          ElevatedButton.icon(
                            onPressed: _updateName,
                            icon: const Icon(Icons.save_outlined, color: Colors.white),
                            label: const Text('ذخیره تغییرات'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gap(24.h),

                  // Reset/Logout Button
                  OutlinedButton.icon(
                    onPressed: _resetApp,
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: const Text('خروج و تغییر کاربر'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: Size(double.infinity, 54.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
