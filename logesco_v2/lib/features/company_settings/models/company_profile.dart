import 'package:json_annotation/json_annotation.dart';

part 'company_profile.g.dart';

/// Modèle pour les informations de profil d'entreprise
@JsonSerializable()
class CompanyProfile {
  final int? id;
  @JsonKey(name: 'nomEntreprise')
  final String name;
  @JsonKey(name: 'adresse')
  final String address;
  @JsonKey(name: 'localisation')
  final String? location;
  @JsonKey(name: 'telephone')
  final String? phone;
  final String? email;
  @JsonKey(name: 'nuiRccm')
  final String? nuiRccm;
  final String? logo; // Chemin vers le fichier logo (optionnel)
  final String? slogan; // Slogan de l'entreprise (optionnel)
  @JsonKey(name: 'langueFacture')
  final String? receiptLanguage; // Langue des factures: 'fr', 'en' ou 'es'
  @JsonKey(name: 'dateCreation')
  final DateTime? createdAt;
  @JsonKey(name: 'dateModification')
  final DateTime? updatedAt;

  CompanyProfile({
    this.id,
    required this.name,
    required this.address,
    this.location,
    this.phone,
    this.email,
    this.nuiRccm,
    this.logo,
    this.slogan,
    this.receiptLanguage = 'fr', // Par défaut en français
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => _$CompanyProfileFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyProfileToJson(this);

  /// Crée une copie avec des modifications
  CompanyProfile copyWith({
    int? id,
    String? name,
    String? address,
    String? location,
    String? phone,
    String? email,
    String? nuiRccm,
    String? logo,
    String? slogan,
    String? receiptLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nuiRccm: nuiRccm ?? this.nuiRccm,
      logo: logo ?? this.logo,
      slogan: slogan ?? this.slogan,
      receiptLanguage: receiptLanguage ?? this.receiptLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validation des champs requis
  Map<String, String> validate() {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Le nom de l\'entreprise est requis';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Le nom de l\'entreprise doit contenir au moins 2 caractères';
    }

    if (address.trim().isEmpty) {
      errors['address'] = 'L\'adresse est requise';
    } else if (address.trim().length < 5) {
      errors['address'] = 'L\'adresse doit contenir au moins 5 caractères';
    }

    if (location?.trim().isEmpty ?? true) {
      errors['location'] = 'La localisation est requise';
    }

    if (phone?.trim().isEmpty ?? true) {
      errors['phone'] = 'Le numéro de téléphone est requis';
    }
    // Validation du format supprimée - l'utilisateur peut entrer le numéro comme du texte

    if (email != null && email!.trim().isNotEmpty && !_isValidEmail(email!)) {
      errors['email'] = 'L\'adresse email n\'est pas valide';
    }

    if (nuiRccm?.trim().isEmpty ?? true) {
      errors['nuiRccm'] = 'Le NUI RCCM est requis';
    } else if (nuiRccm != null && nuiRccm!.trim().length < 5) {
      errors['nuiRccm'] = 'Le NUI RCCM doit contenir au moins 5 caractères';
    }

    return errors;
  }

  /// Vérifie si le profil est valide
  bool get isValid => validate().isEmpty;

  /// Validation du format email
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Validation du format téléphone (format international ou local)
  bool _isValidPhone(String phone) {
    // Supprime les espaces et caractères spéciaux
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Vérifie que c'est uniquement des chiffres et au moins 8 caractères
    return RegExp(r'^\d{8,15}$').hasMatch(cleanPhone);
  }

  /// Crée un profil vide pour les formulaires
  factory CompanyProfile.empty() {
    return CompanyProfile(
      name: '',
      address: '',
      location: '',
      phone: '',
      email: '',
      nuiRccm: '',
      logo: null,
      slogan: null,
      receiptLanguage: 'fr',
    );
  }

  /// Vérifie si le profil est vide
  bool get isEmpty {
    return name.trim().isEmpty &&
        address.trim().isEmpty &&
        (location?.trim().isEmpty ?? true) &&
        (phone?.trim().isEmpty ?? true) &&
        (email?.trim().isEmpty ?? true) &&
        (nuiRccm?.trim().isEmpty ?? true) &&
        (logo?.trim().isEmpty ?? true) &&
        (slogan?.trim().isEmpty ?? true);
  }

  @override
  String toString() {
    return 'CompanyProfile(id: $id, name: $name, address: $address, location: $location, phone: $phone, email: $email, nuiRccm: $nuiRccm, logo: $logo, slogan: $slogan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompanyProfile &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.location == location &&
        other.phone == phone &&
        other.email == email &&
        other.nuiRccm == nuiRccm &&
        other.logo == logo &&
        other.slogan == slogan;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, address, location, phone, email, nuiRccm, logo, slogan);
  }
}

/// Requête pour créer ou mettre à jour un profil d'entreprise
@JsonSerializable()
class CompanyProfileRequest {
  @JsonKey(name: 'nomEntreprise')
  final String name;
  @JsonKey(name: 'adresse')
  final String address;
  @JsonKey(name: 'localisation')
  final String? location;
  @JsonKey(name: 'telephone')
  final String? phone;
  final String? email;
  final String? nuiRccm;
  final String? logo; // Chemin vers le fichier logo (optionnel)
  final String? slogan; // Slogan de l'entreprise (optionnel)
  @JsonKey(name: 'langueFacture')
  final String? receiptLanguage; // Langue des factures

  CompanyProfileRequest({
    required this.name,
    required this.address,
    this.location,
    this.phone,
    this.email,
    this.nuiRccm,
    this.logo,
    this.slogan,
    this.receiptLanguage = 'fr',
  });

  factory CompanyProfileRequest.fromJson(Map<String, dynamic> json) => _$CompanyProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyProfileRequestToJson(this);

  /// Crée une requête à partir d'un profil d'entreprise
  factory CompanyProfileRequest.fromProfile(CompanyProfile profile) {
    return CompanyProfileRequest(
      name: profile.name,
      address: profile.address,
      location: profile.location,
      phone: profile.phone,
      email: profile.email,
      nuiRccm: profile.nuiRccm,
      logo: profile.logo,
      slogan: profile.slogan,
      receiptLanguage: profile.receiptLanguage,
    );
  }
}
