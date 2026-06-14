import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/database_helper.dart';
import '../models/workshop_form.dart';

class FormState {
  final bool isSaving;
  final List<WorkshopFormModel> workshopsList;
  final bool isSuccess;
  final String? errorMessage;

  FormState({
    this.isSaving = false,
    this.workshopsList = const [],
    this.isSuccess = false,
    this.errorMessage,
  });

  FormState copyWith({
    bool? isSaving,
    List<WorkshopFormModel>? workshopsList,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return FormState(
      isSaving: isSaving ?? this.isSaving,
      workshopsList: workshopsList ?? this.workshopsList,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FormController extends StateNotifier<FormState> {
  FormController() : super(FormState()) {
    loadAllWorkshops();
  }

  Future<void> loadAllWorkshops() async {
    try {
      final list = await DatabaseHelper.instance.fetchAllWorkshops();
      state = state.copyWith(workshopsList: list, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطا در بارگذاری لیست: $e');
    }
  }

  Future<void> loadWorkshopsByDate(String date) async {
    try {
      final list = await DatabaseHelper.instance.fetchWorkshopsByDate(date);
      state = state.copyWith(workshopsList: list, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطا در بارگذاری لیست: $e');
    }
  }

  Future<bool> saveWorkshop({
    required String factoryName,
    required String managerName,
    required String phone1,
    required String phone2,
    required String product,
    required String address,
    required String website,
    required String socialMedia,
    required String description,
    required double? latitude,
    required double? longitude,
    required String neshanAddress,
    required String registeredBy,
    required String dateStr,
  }) async {
    state = state.copyWith(isSaving: true, isSuccess: false, errorMessage: null);

    if (factoryName.trim().isEmpty ||
        managerName.trim().isEmpty ||
        phone1.trim().isEmpty ||
        address.trim().isEmpty) {
      state = state.copyWith(isSaving: false, errorMessage: 'لطفا فیلدهای ضروری را پر کنید.');
      return false;
    }

    try {
      final model = WorkshopFormModel(
        factoryName: factoryName,
        managerName: managerName,
        phone1: phone1,
        phone2: phone2,
        product: product,
        address: address,
        website: website,
        socialMedia: socialMedia,
        description: description,
        latitude: latitude,
        longitude: longitude,
        neshanAddress: neshanAddress,
        registeredBy: registeredBy,
        createdAt: dateStr,
      );

      await DatabaseHelper.instance.insertWorkshop(model);
      await loadAllWorkshops();
      state = state.copyWith(isSaving: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'خطا در ذخیره‌سازی داده‌ها: $e');
      return false;
    }
  }

  Future<void> deleteWorkshopEntry(int id) async {
    try {
      await DatabaseHelper.instance.deleteWorkshop(id);
      await loadAllWorkshops();
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطا در حذف رکورد: $e');
    }
  }
}

final formControllerProvider = StateNotifierProvider<FormController, FormState>((ref) {
  return FormController();
});
