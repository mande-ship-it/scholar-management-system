import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';

class Sponsor {
  final String id;
  final String name;
  final String organization;
  final String email;
  final String phone;
  final String contactPerson;
  final String sponsorshipType;
  final double amount;
  final DateTime registrationDate;
  final String address;
  final String notes;
  final String status;

  Sponsor({
    required this.id,
    required this.name,
    required this.organization,
    required this.email,
    required this.phone,
    required this.contactPerson,
    required this.sponsorshipType,
    required this.amount,
    required this.registrationDate,
    this.address = '',
    this.notes = '',
    this.status = 'Active',
  });

  Sponsor copyWith({
    String? id,
    String? name,
    String? organization,
    String? email,
    String? phone,
    String? contactPerson,
    String? sponsorshipType,
    double? amount,
    DateTime? registrationDate,
    String? address,
    String? notes,
    String? status,
  }) {
    return Sponsor(
      id: id ?? this.id,
      name: name ?? this.name,
      organization: organization ?? this.organization,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      contactPerson: contactPerson ?? this.contactPerson,
      sponsorshipType: sponsorshipType ?? this.sponsorshipType,
      amount: amount ?? this.amount,
      registrationDate: registrationDate ?? this.registrationDate,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}

final List<Sponsor> kSponsors = [];

Color getSponsorshipTypeColor(String type) {
  return kBrandOlive;
}
