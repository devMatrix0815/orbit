// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galerie';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get interests => 'Interessen';

  @override
  String get editInterests => 'Interessen bearbeiten';

  @override
  String get interestsTip =>
      'Tippe auf ein Interesse um es hinzuzufügen oder zu entfernen.';

  @override
  String get pleaseSelectInterest => 'Bitte wähle mindestens ein Interesse.';

  @override
  String get noInterestsAdded => 'Noch keine Interessen hinzugefügt.';

  @override
  String get all => 'Alle';

  @override
  String get admin => 'Admin';

  @override
  String get operator => 'Operator';

  @override
  String get you => 'Du';

  @override
  String get ban => 'Bannen';

  @override
  String get unban => 'Entbannen';

  @override
  String get leave => 'Verlassen';

  @override
  String get transfer => 'Übertragen';

  @override
  String get invite => 'Einladen';

  @override
  String get accepted => 'Akzeptiert';

  @override
  String get declined => 'Abgelehnt';

  @override
  String get pending => 'Ausstehend';

  @override
  String get nameLabel => 'Name';

  @override
  String get ageLabel => 'Alter';

  @override
  String get language => 'Sprache';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get yesterday => 'Gestern';

  @override
  String get monday => 'Montag';

  @override
  String get tuesday => 'Dienstag';

  @override
  String get wednesday => 'Mittwoch';

  @override
  String get thursday => 'Donnerstag';

  @override
  String get friday => 'Freitag';

  @override
  String get saturday => 'Samstag';

  @override
  String get sunday => 'Sonntag';

  @override
  String memberCount(int count) {
    return '$count Mitglieder';
  }

  @override
  String ageYears(int age) {
    return '$age Jahre';
  }

  @override
  String generalError(String message) {
    return 'Fehler: $message';
  }

  @override
  String networkError(String message) {
    return 'Netzwerkfehler: $message';
  }

  @override
  String sendError(String error) {
    return 'Fehler beim Senden: $error';
  }

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String membersWithCount(int count) {
    return 'Mitglieder ($count)';
  }

  @override
  String removeCount(int count) {
    return '$count entfernen';
  }

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String loginFailed(String error) {
    return 'Login fehlgeschlagen: $error';
  }

  @override
  String get setupProfile => 'Erstelle dein Profil';

  @override
  String get setupProfileSubtitle => 'Wie sollen andere dich sehen?';

  @override
  String get next => 'Weiter';

  @override
  String get yourInterests => 'Deine Interessen';

  @override
  String get selectAtLeastOneInterest => 'Wähle mindestens ein Interesse aus.';

  @override
  String get createProfile => 'Profil erstellen';

  @override
  String get pleaseEnterName => 'Bitte gib deinen Namen ein.';

  @override
  String get pleaseEnterValidAge => 'Bitte gib ein gültiges Alter ein.';

  @override
  String get myCircles => 'Meine Kreise';

  @override
  String get searchCircles => 'Kreise suchen...';

  @override
  String get createNewCircle => 'Neuen Kreis erstellen';

  @override
  String get selectImage => 'Bild auswählen';

  @override
  String get circleNameLabel => 'Kreisname';

  @override
  String get circleNameHint => 'z.B. Besties, Fotografie, Running...';

  @override
  String get pleaseEnterCircleName => 'Bitte einen Namen eingeben.';

  @override
  String get nameTooShort => 'Name muss mindestens 2 Zeichen haben.';

  @override
  String get categorySelectHint => 'Kategorie (mind. 1 auswählen)';

  @override
  String get selectAtLeastOneCategory => 'Wähle mindestens eine Kategorie.';

  @override
  String get createCircle => 'Kreis erstellen';

  @override
  String get errorCreatingCircle => 'Fehler beim Erstellen des Kreises.';

  @override
  String get errorLoadingCircles => 'Fehler beim Laden der Kreise.';

  @override
  String get removeFromTop => 'Von Top-Kreise entfernen';

  @override
  String get addToTop => 'Zu Top-Kreise hinzufügen';

  @override
  String get topCircles => 'Top-Kreise';

  @override
  String get allCircles => 'Alle Kreise';

  @override
  String get yourCircles => 'Deine Kreise';

  @override
  String get noCirclesYet =>
      'Du bist noch in keinem Kreis.\nEntdecke neue Gruppen!';

  @override
  String get noCirclesFound => 'Keine Kreise gefunden.';

  @override
  String get discover => 'Entdecken';

  @override
  String get searchGroups => 'Suche nach Gruppen...';

  @override
  String get filterByCategory => 'Nach Kategorie filtern';

  @override
  String get recommendedGroups => 'Empfohlene Gruppen';

  @override
  String get noGroupsFound => 'Keine Gruppen gefunden.';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get errorLoadingNotifications =>
      'Fehler beim Laden der Benachrichtigungen.';

  @override
  String get noNotifications => 'Keine neuen Benachrichtigungen.';

  @override
  String inviteToCircle(String name) {
    return 'Einladung zum Kreis \"$name\"';
  }

  @override
  String get youWereInvited => 'Du wurdest in diesen Kreis eingeladen.';

  @override
  String get decline => 'Ablehnen';

  @override
  String get accept => 'Annehmen';

  @override
  String joinedCircle(String name) {
    return 'Du bist jetzt in \"$name\"!';
  }

  @override
  String get errorAccepting => 'Fehler beim Annehmen.';

  @override
  String get errorDeclining => 'Fehler beim Ablehnen.';

  @override
  String wantsToJoin(String name) {
    return '$name möchte beitreten';
  }

  @override
  String joinRequestFor(String name) {
    return 'Beitrittsanfrage für \"$name\"';
  }

  @override
  String memberAdded(String name) {
    return '$name wurde aufgenommen!';
  }

  @override
  String get myProfile => 'Mein Profil';

  @override
  String get errorChangingProfilePicture =>
      'Fehler beim Ändern des Profilbildes.';

  @override
  String get errorJoining => 'Fehler beim Beitreten.';

  @override
  String get requestSentSuccess => 'Anfrage gesendet!';

  @override
  String get errorSendingRequest => 'Fehler beim Senden der Anfrage.';

  @override
  String get leaveGroup => 'Gruppe verlassen';

  @override
  String confirmLeave(String name) {
    return 'Möchtest du \"$name\" wirklich verlassen?';
  }

  @override
  String get errorLeavingGroup => 'Fehler beim Verlassen der Gruppe.';

  @override
  String get members => 'Mitglieder';

  @override
  String get invitePeople => 'Leute einladen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get joinGroup => 'Gruppe beitreten';

  @override
  String get requestSent => 'Anfrage gesendet';

  @override
  String get sendJoinRequest => 'Beitrittsanfrage senden';

  @override
  String get inviteOnly => 'Nur auf Einladung';

  @override
  String get removeOperatorLabel => 'Operator\nentfernen';

  @override
  String get makeOperatorLabel => 'Zum Operator\nmachen';

  @override
  String get transferAdminLabel => 'Admin\nübertragen';

  @override
  String get banMember => 'Mitglied bannen?';

  @override
  String banMembers(int count) {
    return '$count Mitglieder bannen?';
  }

  @override
  String get banConfirmSingle =>
      'Diese Person wird entfernt und kann der Gruppe nicht mehr beitreten.';

  @override
  String banConfirmMultiple(int count) {
    return '$count Personen werden entfernt und können der Gruppe nicht mehr beitreten.';
  }

  @override
  String get transferAdminTitle => 'Admin übertragen';

  @override
  String transferAdminConfirm(String name) {
    return '$name wird zum neuen Admin. Du verlierst deine Admin-Rechte und wirst normales Mitglied.';
  }

  @override
  String get errorRemoving => 'Fehler beim Entfernen.';

  @override
  String get errorChangingRole => 'Fehler beim Ändern der Rolle.';

  @override
  String get errorBanning => 'Fehler beim Bannen.';

  @override
  String get errorTransferring => 'Fehler beim Übertragen.';

  @override
  String get groupSettings => 'Gruppeneinstellungen';

  @override
  String get changeName => 'Namen ändern';

  @override
  String get newName => 'Neuer Name';

  @override
  String get errorRenaming => 'Fehler beim Umbenennen.';

  @override
  String get changeImage => 'Bild ändern';

  @override
  String get errorChangingImage => 'Fehler beim Ändern des Bildes.';

  @override
  String get joinMode => 'Beitrittsart';

  @override
  String get open => 'Offen';

  @override
  String get openSubtitle => 'Jeder kann direkt beitreten';

  @override
  String get requestMode => 'Anfrage';

  @override
  String get requestSubtitle => 'Beitritt per Anfrage – du entscheidest';

  @override
  String get private => 'Privat';

  @override
  String get privateSubtitle => 'Nur Eingeladene – nicht in Entdecken sichtbar';

  @override
  String get errorSaving => 'Fehler beim Speichern.';

  @override
  String get previewDiscoverPage => 'Vorschau (Entdecken-Seite)';

  @override
  String get bannedMembers => 'Gebannte Mitglieder';

  @override
  String get deleteGroup => 'Gruppe löschen';

  @override
  String confirmDeleteGroup(String name) {
    return 'Möchtest du \"$name\" wirklich löschen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get errorDeleting => 'Fehler beim Löschen.';

  @override
  String get nobodyBanned => 'Niemand ist gebannt.';

  @override
  String get errorUnbanning => 'Fehler beim Entbannen.';

  @override
  String get manageInvites => 'Einladungen verwalten';

  @override
  String get enterName => 'Name eingeben';

  @override
  String get nameHint => 'z.B. Hannes';

  @override
  String userNotFound(String name) {
    return 'Nutzer \"$name\" nicht gefunden.';
  }

  @override
  String get errorSearching => 'Fehler bei der Suche.';

  @override
  String get cantInviteYourself => 'Du kannst dich nicht selbst einladen.';

  @override
  String alreadyMember(String name) {
    return '\"$name\" ist bereits Mitglied.';
  }

  @override
  String alreadyInvited(String name) {
    return '\"$name\" wurde bereits eingeladen.';
  }

  @override
  String inviteSent(String name) {
    return 'Einladung an \"$name\" gesendet.';
  }

  @override
  String get errorSendingInvite => 'Fehler beim Senden der Einladung.';

  @override
  String get invitedPeople => 'Eingeladene Personen';

  @override
  String get noneInvitedYet => 'Noch niemand eingeladen.';

  @override
  String get errorLoadingMessages => 'Fehler beim Laden der Nachrichten';

  @override
  String get errorLoadingOlderMessages =>
      'Fehler beim Laden älterer Nachrichten';

  @override
  String get noMessages => 'Noch keine Nachrichten';

  @override
  String get beFirst => 'Sei der Erste, der etwas schreibt!';

  @override
  String get writeMessage => 'Nachricht schreiben...';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get appUpdate => 'App-Update';

  @override
  String get alreadyUpToDate => 'Du verwendest bereits die neueste Version.';

  @override
  String updateAvailable(String version) {
    return 'Update verfügbar – v$version';
  }

  @override
  String get changes => 'Änderungen:';

  @override
  String get later => 'Später';

  @override
  String get installNow => 'Jetzt installieren';

  @override
  String get signOut => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get confirmDeleteAccount =>
      'Möchtest du dein Konto wirklich dauerhaft löschen? Alle deine Daten werden unwiderruflich entfernt.';

  @override
  String get reloginRequired =>
      'Bitte melde dich erneut an und versuche es nochmal.';

  @override
  String get nameRequired => 'Name darf nicht leer sein';

  @override
  String get ageRequired => 'Alter darf nicht leer sein';

  @override
  String get invalidAge => 'Bitte ein gültiges Alter eingeben';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'English';

  @override
  String get interestSportFitness => 'Sport & Fitness';

  @override
  String get interestMusik => 'Musik';

  @override
  String get interestGaming => 'Gaming';

  @override
  String get interestLesen => 'Lesen';

  @override
  String get interestKochen => 'Kochen';

  @override
  String get interestReisen => 'Reisen';

  @override
  String get interestFotografie => 'Fotografie';

  @override
  String get interestKunst => 'Kunst';

  @override
  String get interestFilmSerien => 'Film & Serien';

  @override
  String get interestTechnologie => 'Technologie';

  @override
  String get interestNatur => 'Natur';

  @override
  String get interestMode => 'Mode';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestTanzen => 'Tanzen';

  @override
  String get interestWissenschaft => 'Wissenschaft';

  @override
  String get interestGeschichte => 'Geschichte';

  @override
  String get interestSprachen => 'Sprachen';

  @override
  String get interestTiere => 'Tiere';

  @override
  String get interestDIY => 'DIY';

  @override
  String get interestFinanzen => 'Finanzen';

  @override
  String get interestPolitik => 'Politik';

  @override
  String get interestPhilosophie => 'Philosophie';

  @override
  String get interestFamilie => 'Familie';

  @override
  String get interestEhrenamt => 'Ehrenamt';

  @override
  String get interestErnaehrung => 'Ernährung';
}
