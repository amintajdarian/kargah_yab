class WorkshopFormModel {
  final int? id;
  final String factoryName; // Still named factoryName internally, but label is Industrial Workshop
  final String managerName;
  final String phone1;
  final String phone2;
  final String product;
  final String industrialTown;
  final String address;
  final String website;
  final String socialMedia;
  final String description;
  final double? latitude;
  final double? longitude;
  final String neshanAddress;
  final String registeredBy;
  final String createdAt;

  WorkshopFormModel({
    this.id,
    required this.factoryName,
    required this.managerName,
    required this.phone1,
    required this.phone2,
    required this.product,
    required this.industrialTown,
    required this.address,
    required this.website,
    required this.socialMedia,
    required this.description,
    this.latitude,
    this.longitude,
    required this.neshanAddress,
    required this.registeredBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'factoryName': factoryName,
      'managerName': managerName,
      'phone1': phone1,
      'phone2': phone2,
      'product': product,
      'industrialTown': industrialTown,
      'address': address,
      'website': website,
      'socialMedia': socialMedia,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'neshanAddress': neshanAddress,
      'registeredBy': registeredBy,
      'createdAt': createdAt,
    };
  }

  factory WorkshopFormModel.fromMap(Map<String, dynamic> map) {
    return WorkshopFormModel(
      id: map['id'] as int?,
      factoryName: map['factoryName'] ?? '',
      managerName: map['managerName'] ?? '',
      phone1: map['phone1'] ?? '',
      phone2: map['phone2'] ?? '',
      product: map['product'] ?? '',
      industrialTown: map['industrialTown'] ?? '',
      address: map['address'] ?? '',
      website: map['website'] ?? '',
      socialMedia: map['socialMedia'] ?? '',
      description: map['description'] ?? '',
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      neshanAddress: map['neshanAddress'] ?? '',
      registeredBy: map['registeredBy'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }

  // Returns list of headers for the Excel report (in Persian)
  static List<String> getExcelHeaders() {
    return [
      'ردیف',
      'نام کارگاه صنعتی',
      'مسئول کارگاه صنعتی',
      'تلفن کارگاه 1',
      'تلفن کارگاه 2',
      'محصول تولیدی',
      'شهرک صنعتی',
      'آدرس کارگاه صنعتی',
      'سایت',
      'شبکه اجتماعی و پیامرسان',
      'توضیحات',
      'عرض جغرافیایی (Latitude)',
      'طول جغرافیایی (Longitude)',
      'آدرس',
      'ثبت توسط',
      'تاریخ و ساعت',
    ];
  }

  // Returns data as list of values corresponding to headers
  List<dynamic> toExcelRow(int rowNumber) {
    String generatedNeshanUrl = neshanAddress;
    if (latitude != null && longitude != null) {
      generatedNeshanUrl = 'https://neshan.org/maps/@$latitude,$longitude,15z,0p';
    }

    return [
      rowNumber,
      factoryName,
      managerName,
      phone1,
      phone2,
      product,
      industrialTown,
      address,
      website,
      socialMedia,
      description,
      latitude,
      longitude,
      generatedNeshanUrl,
      registeredBy,
      createdAt,
    ];
  }
}
