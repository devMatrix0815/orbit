import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @camera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @unknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get unknown;

  /// No description provided for @interests.
  ///
  /// In de, this message translates to:
  /// **'Interessen'**
  String get interests;

  /// No description provided for @editInterests.
  ///
  /// In de, this message translates to:
  /// **'Interessen bearbeiten'**
  String get editInterests;

  /// No description provided for @interestsTip.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein Interesse um es hinzuzufügen oder zu entfernen.'**
  String get interestsTip;

  /// No description provided for @pleaseSelectInterest.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle mindestens ein Interesse.'**
  String get pleaseSelectInterest;

  /// No description provided for @noInterestsAdded.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Interessen hinzugefügt.'**
  String get noInterestsAdded;

  /// No description provided for @all.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get all;

  /// No description provided for @admin.
  ///
  /// In de, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @operator.
  ///
  /// In de, this message translates to:
  /// **'Operator'**
  String get operator;

  /// No description provided for @you.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get you;

  /// No description provided for @ban.
  ///
  /// In de, this message translates to:
  /// **'Bannen'**
  String get ban;

  /// No description provided for @unban.
  ///
  /// In de, this message translates to:
  /// **'Entbannen'**
  String get unban;

  /// No description provided for @leave.
  ///
  /// In de, this message translates to:
  /// **'Verlassen'**
  String get leave;

  /// No description provided for @transfer.
  ///
  /// In de, this message translates to:
  /// **'Übertragen'**
  String get transfer;

  /// No description provided for @invite.
  ///
  /// In de, this message translates to:
  /// **'Einladen'**
  String get invite;

  /// No description provided for @accepted.
  ///
  /// In de, this message translates to:
  /// **'Akzeptiert'**
  String get accepted;

  /// No description provided for @declined.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get declined;

  /// No description provided for @pending.
  ///
  /// In de, this message translates to:
  /// **'Ausstehend'**
  String get pending;

  /// No description provided for @nameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @ageLabel.
  ///
  /// In de, this message translates to:
  /// **'Alter'**
  String get ageLabel;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In de, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @yesterday.
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get yesterday;

  /// No description provided for @monday.
  ///
  /// In de, this message translates to:
  /// **'Montag'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In de, this message translates to:
  /// **'Dienstag'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In de, this message translates to:
  /// **'Mittwoch'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In de, this message translates to:
  /// **'Donnerstag'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In de, this message translates to:
  /// **'Freitag'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In de, this message translates to:
  /// **'Samstag'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In de, this message translates to:
  /// **'Sonntag'**
  String get sunday;

  /// No description provided for @memberCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Mitglieder'**
  String memberCount(int count);

  /// No description provided for @ageYears.
  ///
  /// In de, this message translates to:
  /// **'{age} Jahre'**
  String ageYears(int age);

  /// No description provided for @generalError.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {message}'**
  String generalError(String message);

  /// No description provided for @networkError.
  ///
  /// In de, this message translates to:
  /// **'Netzwerkfehler: {message}'**
  String networkError(String message);

  /// No description provided for @sendError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Senden: {error}'**
  String sendError(String error);

  /// No description provided for @selectedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String selectedCount(int count);

  /// No description provided for @membersWithCount.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder ({count})'**
  String membersWithCount(int count);

  /// No description provided for @removeCount.
  ///
  /// In de, this message translates to:
  /// **'{count} entfernen'**
  String removeCount(int count);

  /// No description provided for @signInWithGoogle.
  ///
  /// In de, this message translates to:
  /// **'Mit Google anmelden'**
  String get signInWithGoogle;

  /// No description provided for @loginFailed.
  ///
  /// In de, this message translates to:
  /// **'Login fehlgeschlagen: {error}'**
  String loginFailed(String error);

  /// No description provided for @setupProfile.
  ///
  /// In de, this message translates to:
  /// **'Erstelle dein Profil'**
  String get setupProfile;

  /// No description provided for @setupProfileSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wie sollen andere dich sehen?'**
  String get setupProfileSubtitle;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @yourInterests.
  ///
  /// In de, this message translates to:
  /// **'Deine Interessen'**
  String get yourInterests;

  /// No description provided for @selectAtLeastOneInterest.
  ///
  /// In de, this message translates to:
  /// **'Wähle mindestens ein Interesse aus.'**
  String get selectAtLeastOneInterest;

  /// No description provided for @createProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil erstellen'**
  String get createProfile;

  /// No description provided for @pleaseEnterName.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deinen Namen ein.'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterValidAge.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib ein gültiges Alter ein.'**
  String get pleaseEnterValidAge;

  /// No description provided for @myCircles.
  ///
  /// In de, this message translates to:
  /// **'Meine Kreise'**
  String get myCircles;

  /// No description provided for @searchCircles.
  ///
  /// In de, this message translates to:
  /// **'Kreise suchen...'**
  String get searchCircles;

  /// No description provided for @createNewCircle.
  ///
  /// In de, this message translates to:
  /// **'Neuen Kreis erstellen'**
  String get createNewCircle;

  /// No description provided for @selectImage.
  ///
  /// In de, this message translates to:
  /// **'Bild auswählen'**
  String get selectImage;

  /// No description provided for @circleNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Kreisname'**
  String get circleNameLabel;

  /// No description provided for @circleNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Besties, Fotografie, Running...'**
  String get circleNameHint;

  /// No description provided for @pleaseEnterCircleName.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Namen eingeben.'**
  String get pleaseEnterCircleName;

  /// No description provided for @nameTooShort.
  ///
  /// In de, this message translates to:
  /// **'Name muss mindestens 2 Zeichen haben.'**
  String get nameTooShort;

  /// No description provided for @categorySelectHint.
  ///
  /// In de, this message translates to:
  /// **'Kategorie (mind. 1 auswählen)'**
  String get categorySelectHint;

  /// No description provided for @selectAtLeastOneCategory.
  ///
  /// In de, this message translates to:
  /// **'Wähle mindestens eine Kategorie.'**
  String get selectAtLeastOneCategory;

  /// No description provided for @createCircle.
  ///
  /// In de, this message translates to:
  /// **'Kreis erstellen'**
  String get createCircle;

  /// No description provided for @errorCreatingCircle.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Erstellen des Kreises.'**
  String get errorCreatingCircle;

  /// No description provided for @errorLoadingCircles.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden der Kreise.'**
  String get errorLoadingCircles;

  /// No description provided for @removeFromTop.
  ///
  /// In de, this message translates to:
  /// **'Von Top-Kreise entfernen'**
  String get removeFromTop;

  /// No description provided for @addToTop.
  ///
  /// In de, this message translates to:
  /// **'Zu Top-Kreise hinzufügen'**
  String get addToTop;

  /// No description provided for @topCircles.
  ///
  /// In de, this message translates to:
  /// **'Top-Kreise'**
  String get topCircles;

  /// No description provided for @allCircles.
  ///
  /// In de, this message translates to:
  /// **'Alle Kreise'**
  String get allCircles;

  /// No description provided for @yourCircles.
  ///
  /// In de, this message translates to:
  /// **'Deine Kreise'**
  String get yourCircles;

  /// No description provided for @noCirclesYet.
  ///
  /// In de, this message translates to:
  /// **'Du bist noch in keinem Kreis.\nEntdecke neue Gruppen!'**
  String get noCirclesYet;

  /// No description provided for @noCirclesFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Kreise gefunden.'**
  String get noCirclesFound;

  /// No description provided for @discover.
  ///
  /// In de, this message translates to:
  /// **'Entdecken'**
  String get discover;

  /// No description provided for @searchGroups.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Gruppen...'**
  String get searchGroups;

  /// No description provided for @filterByCategory.
  ///
  /// In de, this message translates to:
  /// **'Nach Kategorie filtern'**
  String get filterByCategory;

  /// No description provided for @recommendedGroups.
  ///
  /// In de, this message translates to:
  /// **'Empfohlene Gruppen'**
  String get recommendedGroups;

  /// No description provided for @noGroupsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Gruppen gefunden.'**
  String get noGroupsFound;

  /// No description provided for @showMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr anzeigen'**
  String get showMore;

  /// No description provided for @notifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notifications;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden der Benachrichtigungen.'**
  String get errorLoadingNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In de, this message translates to:
  /// **'Keine neuen Benachrichtigungen.'**
  String get noNotifications;

  /// No description provided for @inviteToCircle.
  ///
  /// In de, this message translates to:
  /// **'Einladung zum Kreis \"{name}\"'**
  String inviteToCircle(String name);

  /// No description provided for @youWereInvited.
  ///
  /// In de, this message translates to:
  /// **'Du wurdest in diesen Kreis eingeladen.'**
  String get youWereInvited;

  /// No description provided for @decline.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get accept;

  /// No description provided for @joinedCircle.
  ///
  /// In de, this message translates to:
  /// **'Du bist jetzt in \"{name}\"!'**
  String joinedCircle(String name);

  /// No description provided for @errorAccepting.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Annehmen.'**
  String get errorAccepting;

  /// No description provided for @errorDeclining.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Ablehnen.'**
  String get errorDeclining;

  /// No description provided for @wantsToJoin.
  ///
  /// In de, this message translates to:
  /// **'{name} möchte beitreten'**
  String wantsToJoin(String name);

  /// No description provided for @joinRequestFor.
  ///
  /// In de, this message translates to:
  /// **'Beitrittsanfrage für \"{name}\"'**
  String joinRequestFor(String name);

  /// No description provided for @memberAdded.
  ///
  /// In de, this message translates to:
  /// **'{name} wurde aufgenommen!'**
  String memberAdded(String name);

  /// No description provided for @myProfile.
  ///
  /// In de, this message translates to:
  /// **'Mein Profil'**
  String get myProfile;

  /// No description provided for @errorChangingProfilePicture.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Ändern des Profilbildes.'**
  String get errorChangingProfilePicture;

  /// No description provided for @errorJoining.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Beitreten.'**
  String get errorJoining;

  /// No description provided for @requestSentSuccess.
  ///
  /// In de, this message translates to:
  /// **'Anfrage gesendet!'**
  String get requestSentSuccess;

  /// No description provided for @errorSendingRequest.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Senden der Anfrage.'**
  String get errorSendingRequest;

  /// No description provided for @leaveGroup.
  ///
  /// In de, this message translates to:
  /// **'Gruppe verlassen'**
  String get leaveGroup;

  /// No description provided for @confirmLeave.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du \"{name}\" wirklich verlassen?'**
  String confirmLeave(String name);

  /// No description provided for @errorLeavingGroup.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Verlassen der Gruppe.'**
  String get errorLeavingGroup;

  /// No description provided for @members.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder'**
  String get members;

  /// No description provided for @invitePeople.
  ///
  /// In de, this message translates to:
  /// **'Leute einladen'**
  String get invitePeople;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @joinGroup.
  ///
  /// In de, this message translates to:
  /// **'Gruppe beitreten'**
  String get joinGroup;

  /// No description provided for @requestSent.
  ///
  /// In de, this message translates to:
  /// **'Anfrage gesendet'**
  String get requestSent;

  /// No description provided for @sendJoinRequest.
  ///
  /// In de, this message translates to:
  /// **'Beitrittsanfrage senden'**
  String get sendJoinRequest;

  /// No description provided for @inviteOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur auf Einladung'**
  String get inviteOnly;

  /// No description provided for @removeOperatorLabel.
  ///
  /// In de, this message translates to:
  /// **'Operator\nentfernen'**
  String get removeOperatorLabel;

  /// No description provided for @makeOperatorLabel.
  ///
  /// In de, this message translates to:
  /// **'Zum Operator\nmachen'**
  String get makeOperatorLabel;

  /// No description provided for @transferAdminLabel.
  ///
  /// In de, this message translates to:
  /// **'Admin\nübertragen'**
  String get transferAdminLabel;

  /// No description provided for @banMember.
  ///
  /// In de, this message translates to:
  /// **'Mitglied bannen?'**
  String get banMember;

  /// No description provided for @banMembers.
  ///
  /// In de, this message translates to:
  /// **'{count} Mitglieder bannen?'**
  String banMembers(int count);

  /// No description provided for @banConfirmSingle.
  ///
  /// In de, this message translates to:
  /// **'Diese Person wird entfernt und kann der Gruppe nicht mehr beitreten.'**
  String get banConfirmSingle;

  /// No description provided for @banConfirmMultiple.
  ///
  /// In de, this message translates to:
  /// **'{count} Personen werden entfernt und können der Gruppe nicht mehr beitreten.'**
  String banConfirmMultiple(int count);

  /// No description provided for @transferAdminTitle.
  ///
  /// In de, this message translates to:
  /// **'Admin übertragen'**
  String get transferAdminTitle;

  /// No description provided for @transferAdminConfirm.
  ///
  /// In de, this message translates to:
  /// **'{name} wird zum neuen Admin. Du verlierst deine Admin-Rechte und wirst normales Mitglied.'**
  String transferAdminConfirm(String name);

  /// No description provided for @errorRemoving.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Entfernen.'**
  String get errorRemoving;

  /// No description provided for @errorChangingRole.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Ändern der Rolle.'**
  String get errorChangingRole;

  /// No description provided for @errorBanning.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Bannen.'**
  String get errorBanning;

  /// No description provided for @errorTransferring.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Übertragen.'**
  String get errorTransferring;

  /// No description provided for @groupSettings.
  ///
  /// In de, this message translates to:
  /// **'Gruppeneinstellungen'**
  String get groupSettings;

  /// No description provided for @changeName.
  ///
  /// In de, this message translates to:
  /// **'Namen ändern'**
  String get changeName;

  /// No description provided for @newName.
  ///
  /// In de, this message translates to:
  /// **'Neuer Name'**
  String get newName;

  /// No description provided for @errorRenaming.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Umbenennen.'**
  String get errorRenaming;

  /// No description provided for @changeImage.
  ///
  /// In de, this message translates to:
  /// **'Bild ändern'**
  String get changeImage;

  /// No description provided for @errorChangingImage.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Ändern des Bildes.'**
  String get errorChangingImage;

  /// No description provided for @joinMode.
  ///
  /// In de, this message translates to:
  /// **'Beitrittsart'**
  String get joinMode;

  /// No description provided for @open.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get open;

  /// No description provided for @openSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Jeder kann direkt beitreten'**
  String get openSubtitle;

  /// No description provided for @requestMode.
  ///
  /// In de, this message translates to:
  /// **'Anfrage'**
  String get requestMode;

  /// No description provided for @requestSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Beitritt per Anfrage – du entscheidest'**
  String get requestSubtitle;

  /// No description provided for @private.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get private;

  /// No description provided for @privateSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Nur Eingeladene – nicht in Entdecken sichtbar'**
  String get privateSubtitle;

  /// No description provided for @errorSaving.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern.'**
  String get errorSaving;

  /// No description provided for @previewDiscoverPage.
  ///
  /// In de, this message translates to:
  /// **'Vorschau (Entdecken-Seite)'**
  String get previewDiscoverPage;

  /// No description provided for @bannedMembers.
  ///
  /// In de, this message translates to:
  /// **'Gebannte Mitglieder'**
  String get bannedMembers;

  /// No description provided for @deleteGroup.
  ///
  /// In de, this message translates to:
  /// **'Gruppe löschen'**
  String get deleteGroup;

  /// No description provided for @confirmDeleteGroup.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du \"{name}\" wirklich löschen? Das kann nicht rückgängig gemacht werden.'**
  String confirmDeleteGroup(String name);

  /// No description provided for @errorDeleting.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen.'**
  String get errorDeleting;

  /// No description provided for @nobodyBanned.
  ///
  /// In de, this message translates to:
  /// **'Niemand ist gebannt.'**
  String get nobodyBanned;

  /// No description provided for @errorUnbanning.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Entbannen.'**
  String get errorUnbanning;

  /// No description provided for @manageInvites.
  ///
  /// In de, this message translates to:
  /// **'Einladungen verwalten'**
  String get manageInvites;

  /// No description provided for @enterName.
  ///
  /// In de, this message translates to:
  /// **'Name eingeben'**
  String get enterName;

  /// No description provided for @nameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Hannes'**
  String get nameHint;

  /// No description provided for @userNotFound.
  ///
  /// In de, this message translates to:
  /// **'Nutzer \"{name}\" nicht gefunden.'**
  String userNotFound(String name);

  /// No description provided for @errorSearching.
  ///
  /// In de, this message translates to:
  /// **'Fehler bei der Suche.'**
  String get errorSearching;

  /// No description provided for @cantInviteYourself.
  ///
  /// In de, this message translates to:
  /// **'Du kannst dich nicht selbst einladen.'**
  String get cantInviteYourself;

  /// No description provided for @alreadyMember.
  ///
  /// In de, this message translates to:
  /// **'\"{name}\" ist bereits Mitglied.'**
  String alreadyMember(String name);

  /// No description provided for @alreadyInvited.
  ///
  /// In de, this message translates to:
  /// **'\"{name}\" wurde bereits eingeladen.'**
  String alreadyInvited(String name);

  /// No description provided for @inviteSent.
  ///
  /// In de, this message translates to:
  /// **'Einladung an \"{name}\" gesendet.'**
  String inviteSent(String name);

  /// No description provided for @errorSendingInvite.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Senden der Einladung.'**
  String get errorSendingInvite;

  /// No description provided for @invitedPeople.
  ///
  /// In de, this message translates to:
  /// **'Eingeladene Personen'**
  String get invitedPeople;

  /// No description provided for @noneInvitedYet.
  ///
  /// In de, this message translates to:
  /// **'Noch niemand eingeladen.'**
  String get noneInvitedYet;

  /// No description provided for @errorLoadingMessages.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden der Nachrichten'**
  String get errorLoadingMessages;

  /// No description provided for @errorLoadingOlderMessages.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden älterer Nachrichten'**
  String get errorLoadingOlderMessages;

  /// No description provided for @noMessages.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten'**
  String get noMessages;

  /// No description provided for @beFirst.
  ///
  /// In de, this message translates to:
  /// **'Sei der Erste, der etwas schreibt!'**
  String get beFirst;

  /// No description provided for @writeMessage.
  ///
  /// In de, this message translates to:
  /// **'Nachricht schreiben...'**
  String get writeMessage;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @editProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get editProfile;

  /// No description provided for @appUpdate.
  ///
  /// In de, this message translates to:
  /// **'App-Update'**
  String get appUpdate;

  /// No description provided for @alreadyUpToDate.
  ///
  /// In de, this message translates to:
  /// **'Du verwendest bereits die neueste Version.'**
  String get alreadyUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In de, this message translates to:
  /// **'Update verfügbar – v{version}'**
  String updateAvailable(String version);

  /// No description provided for @changes.
  ///
  /// In de, this message translates to:
  /// **'Änderungen:'**
  String get changes;

  /// No description provided for @later.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get later;

  /// No description provided for @installNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt installieren'**
  String get installNow;

  /// No description provided for @signOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get deleteAccount;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du dein Konto wirklich dauerhaft löschen? Alle deine Daten werden unwiderruflich entfernt.'**
  String get confirmDeleteAccount;

  /// No description provided for @reloginRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte melde dich erneut an und versuche es nochmal.'**
  String get reloginRequired;

  /// No description provided for @nameRequired.
  ///
  /// In de, this message translates to:
  /// **'Name darf nicht leer sein'**
  String get nameRequired;

  /// No description provided for @ageRequired.
  ///
  /// In de, this message translates to:
  /// **'Alter darf nicht leer sein'**
  String get ageRequired;

  /// No description provided for @invalidAge.
  ///
  /// In de, this message translates to:
  /// **'Bitte ein gültiges Alter eingeben'**
  String get invalidAge;

  /// No description provided for @german.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @english.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @interestSportFitness.
  ///
  /// In de, this message translates to:
  /// **'Sport & Fitness'**
  String get interestSportFitness;

  /// No description provided for @interestMusik.
  ///
  /// In de, this message translates to:
  /// **'Musik'**
  String get interestMusik;

  /// No description provided for @interestGaming.
  ///
  /// In de, this message translates to:
  /// **'Gaming'**
  String get interestGaming;

  /// No description provided for @interestLesen.
  ///
  /// In de, this message translates to:
  /// **'Lesen'**
  String get interestLesen;

  /// No description provided for @interestKochen.
  ///
  /// In de, this message translates to:
  /// **'Kochen'**
  String get interestKochen;

  /// No description provided for @interestReisen.
  ///
  /// In de, this message translates to:
  /// **'Reisen'**
  String get interestReisen;

  /// No description provided for @interestFotografie.
  ///
  /// In de, this message translates to:
  /// **'Fotografie'**
  String get interestFotografie;

  /// No description provided for @interestKunst.
  ///
  /// In de, this message translates to:
  /// **'Kunst'**
  String get interestKunst;

  /// No description provided for @interestFilmSerien.
  ///
  /// In de, this message translates to:
  /// **'Film & Serien'**
  String get interestFilmSerien;

  /// No description provided for @interestTechnologie.
  ///
  /// In de, this message translates to:
  /// **'Technologie'**
  String get interestTechnologie;

  /// No description provided for @interestNatur.
  ///
  /// In de, this message translates to:
  /// **'Natur'**
  String get interestNatur;

  /// No description provided for @interestMode.
  ///
  /// In de, this message translates to:
  /// **'Mode'**
  String get interestMode;

  /// No description provided for @interestYoga.
  ///
  /// In de, this message translates to:
  /// **'Yoga'**
  String get interestYoga;

  /// No description provided for @interestTanzen.
  ///
  /// In de, this message translates to:
  /// **'Tanzen'**
  String get interestTanzen;

  /// No description provided for @interestWissenschaft.
  ///
  /// In de, this message translates to:
  /// **'Wissenschaft'**
  String get interestWissenschaft;

  /// No description provided for @interestGeschichte.
  ///
  /// In de, this message translates to:
  /// **'Geschichte'**
  String get interestGeschichte;

  /// No description provided for @interestSprachen.
  ///
  /// In de, this message translates to:
  /// **'Sprachen'**
  String get interestSprachen;

  /// No description provided for @interestTiere.
  ///
  /// In de, this message translates to:
  /// **'Tiere'**
  String get interestTiere;

  /// No description provided for @interestDIY.
  ///
  /// In de, this message translates to:
  /// **'DIY'**
  String get interestDIY;

  /// No description provided for @interestFinanzen.
  ///
  /// In de, this message translates to:
  /// **'Finanzen'**
  String get interestFinanzen;

  /// No description provided for @interestPolitik.
  ///
  /// In de, this message translates to:
  /// **'Politik'**
  String get interestPolitik;

  /// No description provided for @interestPhilosophie.
  ///
  /// In de, this message translates to:
  /// **'Philosophie'**
  String get interestPhilosophie;

  /// No description provided for @interestFamilie.
  ///
  /// In de, this message translates to:
  /// **'Familie'**
  String get interestFamilie;

  /// No description provided for @interestEhrenamt.
  ///
  /// In de, this message translates to:
  /// **'Ehrenamt'**
  String get interestEhrenamt;

  /// No description provided for @interestErnaehrung.
  ///
  /// In de, this message translates to:
  /// **'Ernährung'**
  String get interestErnaehrung;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
