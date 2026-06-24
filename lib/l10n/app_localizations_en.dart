// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Try again';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get unknown => 'Unknown';

  @override
  String get interests => 'Interests';

  @override
  String get editInterests => 'Edit Interests';

  @override
  String get interestsTip => 'Tap an interest to add or remove it.';

  @override
  String get pleaseSelectInterest => 'Please select at least one interest.';

  @override
  String get noInterestsAdded => 'No interests added yet.';

  @override
  String get all => 'All';

  @override
  String get admin => 'Admin';

  @override
  String get operator => 'Operator';

  @override
  String get you => 'You';

  @override
  String get ban => 'Ban';

  @override
  String get unban => 'Unban';

  @override
  String get leave => 'Leave';

  @override
  String get transfer => 'Transfer';

  @override
  String get invite => 'Invite';

  @override
  String get accepted => 'Accepted';

  @override
  String get declined => 'Declined';

  @override
  String get pending => 'Pending';

  @override
  String get nameLabel => 'Name';

  @override
  String get ageLabel => 'Age';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String memberCount(int count) {
    return '$count members';
  }

  @override
  String ageYears(int age) {
    return '$age years old';
  }

  @override
  String generalError(String message) {
    return 'Error: $message';
  }

  @override
  String networkError(String message) {
    return 'Network error: $message';
  }

  @override
  String sendError(String error) {
    return 'Error sending: $error';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String membersWithCount(int count) {
    return 'Members ($count)';
  }

  @override
  String removeCount(int count) {
    return 'Remove $count';
  }

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get setupProfile => 'Create your profile';

  @override
  String get setupProfileSubtitle => 'How should others see you?';

  @override
  String get next => 'Next';

  @override
  String get yourInterests => 'Your Interests';

  @override
  String get selectAtLeastOneInterest => 'Select at least one interest.';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get pleaseEnterName => 'Please enter your name.';

  @override
  String get pleaseEnterValidAge => 'Please enter a valid age.';

  @override
  String get myCircles => 'My Circles';

  @override
  String get searchCircles => 'Search circles...';

  @override
  String get createNewCircle => 'Create new circle';

  @override
  String get selectImage => 'Select image';

  @override
  String get circleNameLabel => 'Circle name';

  @override
  String get circleNameHint => 'e.g. Besties, Photography, Running...';

  @override
  String get pleaseEnterCircleName => 'Please enter a name.';

  @override
  String get nameTooShort => 'Name must be at least 2 characters.';

  @override
  String get categorySelectHint => 'Category (select at least 1)';

  @override
  String get selectAtLeastOneCategory => 'Select at least one category.';

  @override
  String get createCircle => 'Create circle';

  @override
  String get errorCreatingCircle => 'Error creating circle.';

  @override
  String get errorLoadingCircles => 'Error loading circles.';

  @override
  String get removeFromTop => 'Remove from Top Circles';

  @override
  String get addToTop => 'Add to Top Circles';

  @override
  String get topCircles => 'Top Circles';

  @override
  String get allCircles => 'All Circles';

  @override
  String get yourCircles => 'Your Circles';

  @override
  String get noCirclesYet =>
      'You\'re not in any circles yet.\nDiscover new groups!';

  @override
  String get noCirclesFound => 'No circles found.';

  @override
  String get discover => 'Discover';

  @override
  String get searchGroups => 'Search groups...';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get recommendedGroups => 'Recommended Groups';

  @override
  String get noGroupsFound => 'No groups found.';

  @override
  String get showMore => 'Show more';

  @override
  String get notifications => 'Notifications';

  @override
  String get errorLoadingNotifications => 'Error loading notifications.';

  @override
  String get noNotifications => 'No new notifications.';

  @override
  String inviteToCircle(String name) {
    return 'Invitation to circle \"$name\"';
  }

  @override
  String get youWereInvited => 'You were invited to this circle.';

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String joinedCircle(String name) {
    return 'You are now in \"$name\"!';
  }

  @override
  String get errorAccepting => 'Error accepting.';

  @override
  String get errorDeclining => 'Error declining.';

  @override
  String wantsToJoin(String name) {
    return '$name wants to join';
  }

  @override
  String joinRequestFor(String name) {
    return 'Join request for \"$name\"';
  }

  @override
  String memberAdded(String name) {
    return '$name was added!';
  }

  @override
  String get myProfile => 'My Profile';

  @override
  String get errorChangingProfilePicture => 'Error changing profile picture.';

  @override
  String get errorJoining => 'Error joining.';

  @override
  String get requestSentSuccess => 'Request sent!';

  @override
  String get errorSendingRequest => 'Error sending request.';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String confirmLeave(String name) {
    return 'Do you really want to leave \"$name\"?';
  }

  @override
  String get errorLeavingGroup => 'Error leaving group.';

  @override
  String get members => 'Members';

  @override
  String get invitePeople => 'Invite people';

  @override
  String get settings => 'Settings';

  @override
  String get joinGroup => 'Join group';

  @override
  String get requestSent => 'Request sent';

  @override
  String get sendJoinRequest => 'Send join request';

  @override
  String get inviteOnly => 'Invite only';

  @override
  String get removeOperatorLabel => 'Remove\nOperator';

  @override
  String get makeOperatorLabel => 'Make\nOperator';

  @override
  String get transferAdminLabel => 'Transfer\nAdmin';

  @override
  String get banMember => 'Ban member?';

  @override
  String banMembers(int count) {
    return 'Ban $count members?';
  }

  @override
  String get banConfirmSingle =>
      'This person will be removed and can no longer join the group.';

  @override
  String banConfirmMultiple(int count) {
    return '$count people will be removed and can no longer join the group.';
  }

  @override
  String get transferAdminTitle => 'Transfer Admin';

  @override
  String transferAdminConfirm(String name) {
    return '$name will become the new admin. You will lose your admin rights and become a regular member.';
  }

  @override
  String get errorRemoving => 'Error removing.';

  @override
  String get errorChangingRole => 'Error changing role.';

  @override
  String get errorBanning => 'Error banning.';

  @override
  String get errorTransferring => 'Error transferring.';

  @override
  String get groupSettings => 'Group Settings';

  @override
  String get changeName => 'Change Name';

  @override
  String get newName => 'New Name';

  @override
  String get errorRenaming => 'Error renaming.';

  @override
  String get changeImage => 'Change image';

  @override
  String get errorChangingImage => 'Error changing image.';

  @override
  String get joinMode => 'Join Mode';

  @override
  String get open => 'Open';

  @override
  String get openSubtitle => 'Anyone can join directly';

  @override
  String get requestMode => 'Request';

  @override
  String get requestSubtitle => 'Join by request – you decide';

  @override
  String get private => 'Private';

  @override
  String get privateSubtitle => 'Invite only – not visible in Discover';

  @override
  String get errorSaving => 'Error saving.';

  @override
  String get previewDiscoverPage => 'Preview (Discover page)';

  @override
  String get bannedMembers => 'Banned Members';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String confirmDeleteGroup(String name) {
    return 'Do you really want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get errorDeleting => 'Error deleting.';

  @override
  String get nobodyBanned => 'Nobody is banned.';

  @override
  String get errorUnbanning => 'Error unbanning.';

  @override
  String get manageInvites => 'Manage Invitations';

  @override
  String get enterName => 'Enter name';

  @override
  String get nameHint => 'e.g. Hannes';

  @override
  String userNotFound(String name) {
    return 'User \"$name\" not found.';
  }

  @override
  String get errorSearching => 'Error searching.';

  @override
  String get cantInviteYourself => 'You can\'t invite yourself.';

  @override
  String alreadyMember(String name) {
    return '\"$name\" is already a member.';
  }

  @override
  String alreadyInvited(String name) {
    return '\"$name\" has already been invited.';
  }

  @override
  String inviteSent(String name) {
    return 'Invitation sent to \"$name\".';
  }

  @override
  String get errorSendingInvite => 'Error sending invitation.';

  @override
  String get invitedPeople => 'Invited People';

  @override
  String get noneInvitedYet => 'Nobody invited yet.';

  @override
  String get errorLoadingMessages => 'Error loading messages';

  @override
  String get errorLoadingOlderMessages => 'Error loading older messages';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get beFirst => 'Be the first to write something!';

  @override
  String get writeMessage => 'Write a message...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get appUpdate => 'App Update';

  @override
  String get alreadyUpToDate => 'You are already using the latest version.';

  @override
  String updateAvailable(String version) {
    return 'Update available – v$version';
  }

  @override
  String get changes => 'Changes:';

  @override
  String get later => 'Later';

  @override
  String get installNow => 'Install now';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get confirmDeleteAccount =>
      'Do you really want to permanently delete your account? All your data will be irreversibly removed.';

  @override
  String get reloginRequired => 'Please sign in again and try again.';

  @override
  String get nameRequired => 'Name cannot be empty';

  @override
  String get ageRequired => 'Age cannot be empty';

  @override
  String get invalidAge => 'Please enter a valid age';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'English';

  @override
  String get interestSportFitness => 'Sports & Fitness';

  @override
  String get interestMusik => 'Music';

  @override
  String get interestGaming => 'Gaming';

  @override
  String get interestLesen => 'Reading';

  @override
  String get interestKochen => 'Cooking';

  @override
  String get interestReisen => 'Travel';

  @override
  String get interestFotografie => 'Photography';

  @override
  String get interestKunst => 'Art';

  @override
  String get interestFilmSerien => 'Film & TV';

  @override
  String get interestTechnologie => 'Technology';

  @override
  String get interestNatur => 'Nature';

  @override
  String get interestMode => 'Fashion';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestTanzen => 'Dancing';

  @override
  String get interestWissenschaft => 'Science';

  @override
  String get interestGeschichte => 'History';

  @override
  String get interestSprachen => 'Languages';

  @override
  String get interestTiere => 'Animals';

  @override
  String get interestDIY => 'DIY';

  @override
  String get interestFinanzen => 'Finance';

  @override
  String get interestPolitik => 'Politics';

  @override
  String get interestPhilosophie => 'Philosophy';

  @override
  String get interestFamilie => 'Family';

  @override
  String get interestEhrenamt => 'Volunteering';

  @override
  String get interestErnaehrung => 'Nutrition';
}
