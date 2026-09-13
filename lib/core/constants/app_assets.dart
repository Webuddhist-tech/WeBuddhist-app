import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Application asset paths and icon constants
/// Contains all asset file paths and PhosphorIcons used throughout the app
/// Following Clean Architecture: Single source of truth for all visual assets
class AppAssets {
  AppAssets._();

  // ========== IMAGES ==========
  static const String routineCalendar = 'assets/images/routine_calendar.png';
  static const String homeMalaIcon = 'assets/images/mala-icon.png';
  static const String recitationCoverDefault =
      'assets/images/recitation_cover/recitation_05.jpg';
  static const String connect = 'assets/images/connect.png';
  static const String verseOfDayFallback = 'assets/images/buddha.jpeg';
  static const String collectionCompletion =
      'assets/images/collection-completion.png';

  // ========== AUDIO ==========
  // PCM WAV (not MP3): ExoPlayer's offload path mis-parses the encoded MP3 on
  // the first cold-start play (getFramesPerEncodedSample → IllegalArgumentException),
  // dropping the bell. PCM never takes that path, matching the working mala.wav.
  static const String meditationSound = 'assets/audios/meditation.wav';
  static const String malaSound = 'assets/audios/mala.wav';

  // ========== LOGOS ==========
  static const String weBuddhistLogo = 'assets/images/webuddhist_logo.png';
  static const String googleIcon = 'assets/images/google-icon.png';
  static const String googleMeetIcon = 'assets/images/google_meet_icon.png';
  static const String zoomIcon = 'assets/images/zoom_icon.png';

  // ========== AUTH ICONS ==========
  static const IconData apple = Icons.apple;

  // ========== BOTTOM NAVIGATION ICONS ==========
  static const IconData homeSelected = PhosphorIconsFill.house;
  static const IconData homeUnselected = PhosphorIconsRegular.house;
  static const IconData exploreSelected = PhosphorIconsFill.magnifyingGlass;
  static const IconData exploreUnselected =
      PhosphorIconsRegular.magnifyingGlass;
  static const IconData textsSelected = PhosphorIconsFill.bookOpenText;
  static const IconData textsUnselected = PhosphorIconsRegular.bookOpenText;
  static const IconData practiceSelected = PhosphorIconsFill.bell;
  static const IconData practiceUnselected = PhosphorIconsRegular.bell;
  static const IconData settingsSelected = PhosphorIconsFill.gearSix;
  static const IconData settingsUnselected = PhosphorIconsRegular.gearSix;
  static const IconData connectSelected = PhosphorIconsFill.usersThree;
  static const IconData connectUnselected = PhosphorIconsRegular.usersThree;
  static const IconData meSelected = PhosphorIconsFill.userCircle;
  static const IconData meUnselected = PhosphorIconsRegular.userCircle;

  // ========== READER ICONS ==========
  static const IconData readerVersionSettings = PhosphorIconsRegular.globe;
  static const IconData readerFontSize = PhosphorIconsRegular.textAa;
  static const IconData readerVersion = PhosphorIconsRegular.globe;
  static const IconData readerCommentary = PhosphorIconsRegular.chatText;
  static const IconData readerCopy = PhosphorIconsRegular.copy;
  static const IconData readerShare = PhosphorIconsRegular.shareNetwork;
  static const IconData readerChevronRight = PhosphorIconsRegular.caretRight;

  // ========== SETTINGS & PROFILE ICONS ==========
  static const IconData profile = PhosphorIconsRegular.user;
  static const IconData language = PhosphorIconsRegular.translate;
  static const IconData notification = PhosphorIconsRegular.bellRinging;
  static const IconData theme = PhosphorIconsRegular.sun;
  static const IconData themeMoon = PhosphorIconsRegular.moon;
  static const IconData about = PhosphorIconsRegular.info;
  static const IconData legal = PhosphorIconsRegular.gavel;
  static const IconData feedback = PhosphorIconsRegular.chatText;
  static const IconData signIn = PhosphorIconsRegular.signIn;
  static const IconData signOut = PhosphorIconsRegular.signOut;
  static const IconData settings = PhosphorIconsRegular.gear;
  static const IconData photoLibrary = PhosphorIconsRegular.images;
  static const IconData camera = PhosphorIconsRegular.camera;

  // ========== COMMON UI ICONS ==========
  static const IconData caretRight = PhosphorIconsRegular.caretRight;
  static const IconData caretRight2 = PhosphorIconsBold.caretRight;
  static const IconData caretDown = PhosphorIconsRegular.caretDown;
  static const IconData caretDoubleDown = PhosphorIconsRegular.caretDoubleDown;
  static const IconData caretUp = PhosphorIconsRegular.caretUp;
  static const IconData caretLeft = PhosphorIconsRegular.caretLeft;
  static const IconData caretLeft2 = PhosphorIconsBold.caretLeft;
  static const IconData arrowSquareOut = PhosphorIconsRegular.arrowSquareOut;
  static const IconData arrowLeft = PhosphorIconsRegular.arrowLeft;
  static const IconData lock = PhosphorIconsRegular.lock;
  static const IconData flame = PhosphorIconsFill.fire;
  static const IconData share = PhosphorIconsRegular.export;
  static const IconData heart = PhosphorIconsRegular.heart;
  static const IconData heartFill = PhosphorIconsFill.heart;
  static const IconData chatCircle = PhosphorIconsRegular.chatCircle;
  static const IconData chatCircleDots = PhosphorIconsRegular.chatCircleDots;
  static const IconData x = PhosphorIconsRegular.x;
  static const IconData dotsThreeVertical =
      PhosphorIconsRegular.dotsThreeVertical;
  static const IconData paperPlaneRight = PhosphorIconsRegular.paperPlaneRight;
  static const IconData arrowBendUpLeft = PhosphorIconsRegular.arrowBendUpLeft;
  static const IconData copy = PhosphorIconsRegular.copy;

  // ========== ACTION ICONS ==========
  static const IconData plus = PhosphorIconsRegular.plus;
  static const IconData plusCircle = PhosphorIconsRegular.plusCircle;
  static const IconData minus = PhosphorIconsRegular.minus;
  static const IconData minusCircle = PhosphorIconsRegular.minusCircle;
  static const IconData play = PhosphorIconsFill.play;
  static const IconData pause = PhosphorIconsFill.pause;
  static const IconData list = PhosphorIconsRegular.list;
  static const IconData trash = PhosphorIconsRegular.trash;
  static const IconData pencilSimple = PhosphorIconsRegular.pencilSimple;
  static const IconData fileText = PhosphorIconsRegular.fileText;
  static const IconData bookmarkSimple = PhosphorIconsRegular.bookmarkSimple;
  static const IconData bookmarkSimpleFill = PhosphorIconsFill.bookmarkSimple;
  static const IconData speakerSimpleHigh =
      PhosphorIconsRegular.speakerSimpleHigh;
  static const IconData headphones = PhosphorIconsRegular.headphones;
  static const IconData monitorPlay = PhosphorIconsRegular.monitorPlay;
  static const IconData vibrate = PhosphorIconsRegular.vibrate;
  static const IconData arrowCounterClockwise =
      PhosphorIconsRegular.arrowCounterClockwise;

  // ========== NOTIFICATION ICONS ==========
  static const IconData bell = PhosphorIconsRegular.bell;
  static const IconData bellSlash = PhosphorIconsRegular.bellSlash;

  // ========== STATUS ICONS ==========
  static const IconData checkCircle = PhosphorIconsRegular.checkCircle;
  static const IconData warningCircle = PhosphorIconsRegular.warningCircle;
  static const IconData warning = PhosphorIconsRegular.warning;
  static const IconData check = PhosphorIconsBold.check;

  // ========== SOCIAL MEDIA ICONS ==========
  static const IconData linkSimple = PhosphorIconsRegular.linkSimple;
  static const IconData instagram = PhosphorIconsRegular.instagramLogo;
  static const IconData facebook = PhosphorIconsRegular.facebookLogo;
  static const IconData twitter = PhosphorIconsRegular.xLogo;
  static const IconData youtube = PhosphorIconsRegular.youtubeLogo;
  static const IconData tiktok = PhosphorIconsRegular.tiktokLogo;
  static const IconData linkedin = PhosphorIconsRegular.linkedinLogo;
  static const IconData link = PhosphorIconsRegular.link;
  static const IconData globe = PhosphorIconsRegular.globe;

  // ========== HOME SHORTCUT ICONS ==========
  static const IconData homeChants = PhosphorIconsBold.bookOpenText;
  static const IconData homeTimer = PhosphorIconsBold.timer;
  static const IconData homeList = PhosphorIconsBold.listChecks;

  // ========== GROUP & SERIES ICONS ==========
  static const IconData usersThree = PhosphorIconsRegular.usersThree;
  static const IconData usercard = PhosphorIconsRegular.users;
  static const IconData bookOpenText = PhosphorIconsRegular.bookOpenText;
  static const IconData calendarDots = PhosphorIconsRegular.calendarDots;
  static const IconData mapPin = PhosphorIconsRegular.mapPin;
  static const IconData videoCamera = PhosphorIconsRegular.videoCamera;
  static const IconData clock = PhosphorIconsRegular.clock;
  static const IconData repeat = PhosphorIconsRegular.arrowsClockwise;
  static const IconData buildings = PhosphorIconsRegular.buildings;
  static const IconData arrowRight = PhosphorIconsRegular.arrowRight;
  static const IconData featuredSeriesPlanCount =
      PhosphorIconsRegular.calendarDots;
  static const IconData featuredSeriesEnrolledCount =
      PhosphorIconsRegular.usersThree;
}
