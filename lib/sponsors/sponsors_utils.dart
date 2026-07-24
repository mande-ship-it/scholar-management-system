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

final List<Sponsor> kSponsors = [
  Sponsor(
    id: '1',
    name: 'Alice Banda',
    organization: 'Sunrise Foundation',
    email: 'alice@sunrise.org',
    phone: '+265 991 234 567',
    contactPerson: 'Alice Banda',
    sponsorshipType: 'Platinum',
    amount: 15000,
    registrationDate: DateTime.now().subtract(const Duration(days: 120)),
    address: 'Area 10, Lilongwe',
    notes: 'Renews annually in July.',
    status: 'Active',
  ),
  Sponsor(
    id: '2',
    name: 'James Phiri',
    organization: 'Phiri & Sons Ltd',
    email: 'james@phirisons.com',
    phone: '+265 888 765 432',
    contactPerson: 'James Phiri',
    sponsorshipType: 'Gold',
    amount: 7500,
    registrationDate: DateTime.now().subtract(const Duration(days: 400)),
    address: 'Old Town, Lilongwe',
    notes: '',
    status: 'Active',
  ),
  Sponsor(
    id: '3',
    name: 'Grace Mwale',
    organization: 'Mwale Enterprises',
    email: 'grace@mwaleent.mw',
    phone: '+265 999 555 111',
    contactPerson: 'Grace Mwale',
    sponsorshipType: 'Bronze',
    amount: 1500,
    registrationDate: DateTime.now().subtract(const Duration(days: 900)),
    address: 'Kanengo, Lilongwe',
    notes: 'Prefers in-kind contributions going forward.',
    status: 'Inactive',
  ),
  Sponsor(
    id: '4',
    name: 'Edward Young Shaba',
    organization: 'Malawi Tech Hub',
    email: 'edward@techhub.mw',
    phone: '+265 992 111 222',
    contactPerson: 'Edward Shaba',
    sponsorshipType: 'Platinum',
    amount: 25000,
    registrationDate: DateTime.now().subtract(const Duration(days: 15)),
    status: 'Active',
  ),
  Sponsor(
    id: '5',
    name: 'Chisomo Phiri',
    organization: 'Phiri Consulting',
    email: 'chisomo@phiri.consulting',
    phone: '+265 881 333 444',
    contactPerson: 'Chisomo Phiri',
    sponsorshipType: 'Silver',
    amount: 5000,
    registrationDate: DateTime.now().subtract(const Duration(days: 200)),
    status: 'Active',
  ),
];

Color getSponsorshipTypeColor(String type) {
  switch (type) {
    case 'Platinum':
      return Colors.blueGrey.shade700;
    case 'Gold':
      return Colors.amber.shade800;
    case 'Silver':
      return Colors.grey.shade600;
    case 'Bronze':
      return Colors.brown.shade400;
    default:
      return kBrandOlive;
  }
}
