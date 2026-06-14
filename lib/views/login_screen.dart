import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final name = _nameController.text.trim();
      await ref.read(authProvider.notifier).registerUsername(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Header Icon & Logo
                  Icon(
                    Icons.storefront_rounded,
                    size: 80.h,
                    color: theme.colorScheme.primary,
                  ),
                  Gap(16.h),
                  Text(
                    'کارگاه‌یاب',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'سامانه ثبت و مدیریت اطلاعات کارگاه‌های صنعتی',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.blueGrey,
                    ),
                  ),
                  Gap(48.h),

                  // Welcome Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خوش آمدید',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Gap(8.h),
                          Text(
                            'لطفا برای شروع، نام و نام خانوادگی خود را وارد کنید.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          Gap(24.h),

                          // Text Field
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: TextFormField(
                              controller: _nameController,
                              textDirection: TextDirection.rtl,
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
                                labelText: 'نام و نام خانوادگی ثبت‌کننده',
                                hintText: 'مثال: علی محمدی',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                          ),
                          Gap(24.h),

                          // Submit Button
                          authState.maybeWhen(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            orElse: () => ElevatedButton(
                              onPressed: _submit,
                              child: const Text('ورود به برنامه'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gap(24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
