import 'package:flutter/material.dart';
import 'package:orbit/l10n/app_localizations.dart';

const List<String> kAllInterests = [
  'Sport & Fitness', 'Musik', 'Gaming', 'Lesen', 'Kochen', 'Reisen',
  'Fotografie', 'Kunst', 'Film & Serien', 'Technologie', 'Natur', 'Mode',
  'Yoga', 'Tanzen', 'Wissenschaft', 'Geschichte', 'Sprachen', 'Tiere',
  'DIY', 'Finanzen', 'Politik', 'Philosophie', 'Familie', 'Ehrenamt',
  'Ernährung',
];

const Map<String, List<String>> kInterestCategories = {
  'Bewegung': ['Sport & Fitness', 'Yoga', 'Tanzen'],
  'Kreativität': ['Musik', 'Fotografie', 'Kunst', 'DIY', 'Mode'],
  'Unterhaltung': ['Gaming', 'Film & Serien', 'Lesen'],
  'Lifestyle': ['Kochen', 'Ernährung', 'Reisen', 'Natur', 'Tiere', 'Familie'],
  'Wissen': ['Technologie', 'Wissenschaft', 'Geschichte', 'Sprachen', 'Philosophie'],
  'Gesellschaft': ['Politik', 'Finanzen', 'Ehrenamt'],
};

const Map<String, IconData> kCategoryIcons = {
  'Bewegung': Icons.directions_run,
  'Kreativität': Icons.palette,
  'Unterhaltung': Icons.tv,
  'Lifestyle': Icons.spa,
  'Wissen': Icons.school,
  'Gesellschaft': Icons.people,
};

const Map<String, Color> kCategoryColors = {
  'Bewegung': Color(0xFFFFE0B2),
  'Kreativität': Color(0xFFF3E5F5),
  'Unterhaltung': Color(0xFFE8EAF6),
  'Lifestyle': Color(0xFFE8F5E9),
  'Wissen': Color(0xFFE1F5FE),
  'Gesellschaft': Color(0xFFE3F2FD),
};

const Map<String, IconData> kTagIcons = {
  'Sport & Fitness': Icons.directions_run,
  'Musik': Icons.music_note,
  'Gaming': Icons.sports_esports,
  'Lesen': Icons.menu_book,
  'Kochen': Icons.restaurant,
  'Reisen': Icons.flight,
  'Fotografie': Icons.camera_alt,
  'Kunst': Icons.brush,
  'Film & Serien': Icons.movie,
  'Technologie': Icons.computer,
  'Natur': Icons.park,
  'Mode': Icons.checkroom,
  'Yoga': Icons.self_improvement,
  'Tanzen': Icons.accessibility_new,
  'Wissenschaft': Icons.science,
  'Geschichte': Icons.history_edu,
  'Sprachen': Icons.translate,
  'Tiere': Icons.pets,
  'DIY': Icons.construction,
  'Finanzen': Icons.attach_money,
  'Politik': Icons.account_balance,
  'Philosophie': Icons.psychology,
  'Familie': Icons.family_restroom,
  'Ehrenamt': Icons.volunteer_activism,
  'Ernährung': Icons.restaurant_menu,
};

const Map<String, Color> kTagColors = {
  'Sport & Fitness': Color(0xFFFFE0B2),
  'Musik': Color(0xFFE8F5E9),
  'Gaming': Color(0xFFE3F2FD),
  'Lesen': Color(0xFFFCE4EC),
  'Kochen': Color(0xFFFFF8E1),
  'Reisen': Color(0xFFBBDEFB),
  'Fotografie': Color(0xFFF3E5F5),
  'Kunst': Color(0xFFFFEBEE),
  'Film & Serien': Color(0xFFE8EAF6),
  'Technologie': Color(0xFFE0F2F1),
  'Natur': Color(0xFFDCEDC8),
  'Mode': Color(0xFFFCE4EC),
  'Yoga': Color(0xFFEDE7F6),
  'Tanzen': Color(0xFFE0F2F1),
  'Wissenschaft': Color(0xFFE1F5FE),
  'Geschichte': Color(0xFFFFF3E0),
  'Sprachen': Color(0xFFE0F7FA),
  'Tiere': Color(0xFFFFF8E1),
  'DIY': Color(0xFFFBE9E7),
  'Finanzen': Color(0xFFE8F5E9),
  'Politik': Color(0xFFE3F2FD),
  'Philosophie': Color(0xFFEDE7F6),
  'Familie': Color(0xFFFCE4EC),
  'Ehrenamt': Color(0xFFD7F5D7),
  'Ernährung': Color(0xFFFFF9C4),
};

// Returns the localized display name for a German interest key.
// The key stays German (Firestore storage), only the display changes.
String getCategoryName(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Bewegung':     return l10n.categoryBewegung;
    case 'Kreativität':  return l10n.categoryKreativitaet;
    case 'Unterhaltung': return l10n.categoryUnterhaltung;
    case 'Lifestyle':    return l10n.categoryLifestyle;
    case 'Wissen':       return l10n.categoryWissen;
    case 'Gesellschaft': return l10n.categoryGesellschaft;
    default:             return key;
  }
}

String getInterestName(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Sport & Fitness': return l10n.interestSportFitness;
    case 'Musik':           return l10n.interestMusik;
    case 'Gaming':          return l10n.interestGaming;
    case 'Lesen':           return l10n.interestLesen;
    case 'Kochen':          return l10n.interestKochen;
    case 'Reisen':          return l10n.interestReisen;
    case 'Fotografie':      return l10n.interestFotografie;
    case 'Kunst':           return l10n.interestKunst;
    case 'Film & Serien':   return l10n.interestFilmSerien;
    case 'Technologie':     return l10n.interestTechnologie;
    case 'Natur':           return l10n.interestNatur;
    case 'Mode':            return l10n.interestMode;
    case 'Yoga':            return l10n.interestYoga;
    case 'Tanzen':          return l10n.interestTanzen;
    case 'Wissenschaft':    return l10n.interestWissenschaft;
    case 'Geschichte':      return l10n.interestGeschichte;
    case 'Sprachen':        return l10n.interestSprachen;
    case 'Tiere':           return l10n.interestTiere;
    case 'DIY':             return l10n.interestDIY;
    case 'Finanzen':        return l10n.interestFinanzen;
    case 'Politik':         return l10n.interestPolitik;
    case 'Philosophie':     return l10n.interestPhilosophie;
    case 'Familie':         return l10n.interestFamilie;
    case 'Ehrenamt':        return l10n.interestEhrenamt;
    case 'Ernährung':       return l10n.interestErnaehrung;
    default:                return key;
  }
}
