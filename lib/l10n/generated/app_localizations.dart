import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zero trace. Zero limit. Zero compromise.'**
  String get appSubtitle;

  /// No description provided for @tabChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get tabChats;

  /// No description provided for @tabSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get tabSpace;

  /// No description provided for @tabWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get tabWallet;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @createIdentity.
  ///
  /// In en, this message translates to:
  /// **'Create Identity'**
  String get createIdentity;

  /// No description provided for @recoverIdentity.
  ///
  /// In en, this message translates to:
  /// **'Recover Identity'**
  String get recoverIdentity;

  /// No description provided for @mnemonicTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Recovery Phrase'**
  String get mnemonicTitle;

  /// No description provided for @mnemonicDesc.
  ///
  /// In en, this message translates to:
  /// **'Write these 12 words down in order. Anyone with this phrase can access your identity. Keep it secret, keep it safe.'**
  String get mnemonicDesc;

  /// No description provided for @copyPhrase.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyPhrase;

  /// No description provided for @phraseCopied.
  ///
  /// In en, this message translates to:
  /// **'12 words copied'**
  String get phraseCopied;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify your seed'**
  String get verifyIdentity;

  /// No description provided for @verifyInstruction.
  ///
  /// In en, this message translates to:
  /// **'Tap each word in the correct order.'**
  String get verifyInstruction;

  /// No description provided for @verifySuccess.
  ///
  /// In en, this message translates to:
  /// **'Identity Verified'**
  String get verifySuccess;

  /// No description provided for @verifyFail.
  ///
  /// In en, this message translates to:
  /// **'Incorrect order. Please try again.'**
  String get verifyFail;

  /// No description provided for @enterIdentity.
  ///
  /// In en, this message translates to:
  /// **'Enter Zero'**
  String get enterIdentity;

  /// No description provided for @enterApp.
  ///
  /// In en, this message translates to:
  /// **'Enter Zero'**
  String get enterApp;

  /// No description provided for @recoverInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12-word recovery seed to restore your Zero identity.'**
  String get recoverInstruction;

  /// No description provided for @recover.
  ///
  /// In en, this message translates to:
  /// **'Recover Identity'**
  String get recover;

  /// No description provided for @recovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering...'**
  String get recovering;

  /// No description provided for @invalidMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 12 words separated by spaces.'**
  String get invalidMnemonic;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeTo;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Zero trace. Zero limit. Zero compromise.'**
  String get splashTagline;

  /// No description provided for @splashCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating your cryptographic identity...'**
  String get splashCreating;

  /// No description provided for @splashRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering your identity...'**
  String get splashRecovering;

  /// No description provided for @splashReady.
  ///
  /// In en, this message translates to:
  /// **'Identity ready'**
  String get splashReady;

  /// No description provided for @zeroChinese.
  ///
  /// In en, this message translates to:
  /// **'零 界'**
  String get zeroChinese;

  /// No description provided for @generateSeed.
  ///
  /// In en, this message translates to:
  /// **'Generate Seed'**
  String get generateSeed;

  /// No description provided for @generatingIdentity.
  ///
  /// In en, this message translates to:
  /// **'Generating your identity...'**
  String get generatingIdentity;

  /// No description provided for @yourZeroIdentity.
  ///
  /// In en, this message translates to:
  /// **'Your Zero identity'**
  String get yourZeroIdentity;

  /// No description provided for @zeroTaglineDesc.
  ///
  /// In en, this message translates to:
  /// **'No phone. No email. No trace.\nJust a seed. Just you.'**
  String get zeroTaglineDesc;

  /// No description provided for @seedWarning.
  ///
  /// In en, this message translates to:
  /// **'Never share your seed. Anyone with these words can access your identity.'**
  String get seedWarning;

  /// No description provided for @saveSeedConfirm.
  ///
  /// In en, this message translates to:
  /// **'I\'ve saved my seed'**
  String get saveSeedConfirm;

  /// No description provided for @seedConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your seed is confirmed.\nWelcome to Zero.'**
  String get seedConfirmed;

  /// No description provided for @zeroIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ZERO ID'**
  String get zeroIdLabel;

  /// No description provided for @pasteWordsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12 words separated by spaces...\n\nabandon ability able about above absent\nabsorb abstract absurd abuse access accident'**
  String get pasteWordsHint;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get searchContacts;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @noConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to start a secure chat'**
  String get noConversationsHint;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get typing;

  /// No description provided for @encryptedMessage.
  ///
  /// In en, this message translates to:
  /// **'Encrypted message'**
  String get encryptedMessage;

  /// No description provided for @messagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messagePlaceholder;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @connectToStart.
  ///
  /// In en, this message translates to:
  /// **'Connect to start chatting'**
  String get connectToStart;

  /// No description provided for @e2eeOnline.
  ///
  /// In en, this message translates to:
  /// **'E2EE · Online'**
  String get e2eeOnline;

  /// No description provided for @voiceMsg.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceMsg;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @addContactByID.
  ///
  /// In en, this message translates to:
  /// **'Add by ZeroID'**
  String get addContactByID;

  /// No description provided for @addContactDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter a ZeroID or scan a QR code to connect'**
  String get addContactDesc;

  /// No description provided for @zeroIdPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter Zero ID (e.g. Z3K7M2N8XP)'**
  String get zeroIdPlaceholder;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code to add contact'**
  String get scanQRCode;

  /// No description provided for @myQRCode.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get myQRCode;

  /// No description provided for @myQRCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'My Zero ID copied to clipboard'**
  String get myQRCodeCopied;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent!'**
  String get requestSent;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to'**
  String get friendRequestSent;

  /// No description provided for @searchAnother.
  ///
  /// In en, this message translates to:
  /// **'Search Another'**
  String get searchAnother;

  /// No description provided for @addToContacts.
  ///
  /// In en, this message translates to:
  /// **'Add to Contacts'**
  String get addToContacts;

  /// No description provided for @searchingNetwork.
  ///
  /// In en, this message translates to:
  /// **'Searching Zero network...'**
  String get searchingNetwork;

  /// No description provided for @invalidZeroId.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Zero ID (starts with Z, 10 chars)'**
  String get invalidZeroId;

  /// No description provided for @qrScanningSim.
  ///
  /// In en, this message translates to:
  /// **'QR scanning: simulating...'**
  String get qrScanningSim;

  /// No description provided for @recentRequests.
  ///
  /// In en, this message translates to:
  /// **'RECENT REQUESTS'**
  String get recentRequests;

  /// No description provided for @searchByZeroId.
  ///
  /// In en, this message translates to:
  /// **'SEARCH BY ZERO ID'**
  String get searchByZeroId;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @lockAndExit.
  ///
  /// In en, this message translates to:
  /// **'Lock & Exit'**
  String get lockAndExit;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @securityLock.
  ///
  /// In en, this message translates to:
  /// **'Security Lock'**
  String get securityLock;

  /// No description provided for @natStatus.
  ///
  /// In en, this message translates to:
  /// **'NAT Status'**
  String get natStatus;

  /// No description provided for @encryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get encryption;

  /// No description provided for @disappearingMessages.
  ///
  /// In en, this message translates to:
  /// **'Disappearing Messages'**
  String get disappearingMessages;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @animations.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get animations;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// No description provided for @networkPeers.
  ///
  /// In en, this message translates to:
  /// **'Network Peers'**
  String get networkPeers;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get disabled;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @subtle.
  ///
  /// In en, this message translates to:
  /// **'Subtle'**
  String get subtle;

  /// No description provided for @zeroCitizen.
  ///
  /// In en, this message translates to:
  /// **'Zero Citizen'**
  String get zeroCitizen;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get walletBalance;

  /// No description provided for @walletSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get walletSend;

  /// No description provided for @walletReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get walletReceive;

  /// No description provided for @walletSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get walletSwap;

  /// No description provided for @walletHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get walletHistory;

  /// No description provided for @walletTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get walletTokens;

  /// No description provided for @walletStake.
  ///
  /// In en, this message translates to:
  /// **'Stake'**
  String get walletStake;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy Address'**
  String get copyAddress;

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied!'**
  String get addressCopied;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION HISTORY'**
  String get transactionHistory;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'ZeroAI'**
  String get aiAssistant;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'ZeroAI is thinking...'**
  String get aiThinking;

  /// No description provided for @aiPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask ZeroAI anything...'**
  String get aiPlaceholder;

  /// No description provided for @aiQuickEncryption.
  ///
  /// In en, this message translates to:
  /// **'How does encryption work?'**
  String get aiQuickEncryption;

  /// No description provided for @aiQuickWallet.
  ///
  /// In en, this message translates to:
  /// **'What wallets do you support?'**
  String get aiQuickWallet;

  /// No description provided for @aiQuickPrivacy.
  ///
  /// In en, this message translates to:
  /// **'How is my privacy protected?'**
  String get aiQuickPrivacy;

  /// No description provided for @aiQuickTransfer.
  ///
  /// In en, this message translates to:
  /// **'How to transfer tokens?'**
  String get aiQuickTransfer;

  /// No description provided for @clearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearConversation;

  /// No description provided for @bleTitle.
  ///
  /// In en, this message translates to:
  /// **'BLE Mesh'**
  String get bleTitle;

  /// No description provided for @bleScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for BLE devices...'**
  String get bleScanning;

  /// No description provided for @bleScanningAuto.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices will appear automatically'**
  String get bleScanningAuto;

  /// No description provided for @bleNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get bleNoDevices;

  /// No description provided for @bleNoDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the Bluetooth icon to start scanning'**
  String get bleNoDevicesHint;

  /// No description provided for @bleStartScan.
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get bleStartScan;

  /// No description provided for @bleNearbyDevices.
  ///
  /// In en, this message translates to:
  /// **'Nearby Devices'**
  String get bleNearbyDevices;

  /// No description provided for @bleDiscovered.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERED'**
  String get bleDiscovered;

  /// No description provided for @bleConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get bleConnect;

  /// No description provided for @bleConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get bleConnected;

  /// No description provided for @bleDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get bleDisconnected;

  /// No description provided for @bleScanningLabel.
  ///
  /// In en, this message translates to:
  /// **'SCANNING'**
  String get bleScanningLabel;

  /// No description provided for @bleOfflineLabel.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get bleOfflineLabel;

  /// No description provided for @bleUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get bleUnknownDevice;

  /// No description provided for @bleMessageViaBLE.
  ///
  /// In en, this message translates to:
  /// **'Message via BLE Mesh'**
  String get bleMessageViaBLE;

  /// No description provided for @bleMessageHint.
  ///
  /// In en, this message translates to:
  /// **'BLE message...'**
  String get bleMessageHint;

  /// No description provided for @bleTapConnect.
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get bleTapConnect;

  /// No description provided for @bleDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get bleDeviceId;

  /// No description provided for @bleSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get bleSignal;

  /// No description provided for @bleStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get bleStatus;

  /// No description provided for @bleZeroId.
  ///
  /// In en, this message translates to:
  /// **'Zero ID'**
  String get bleZeroId;

  /// No description provided for @bleAlreadyConnected.
  ///
  /// In en, this message translates to:
  /// **'Already Connected'**
  String get bleAlreadyConnected;

  /// No description provided for @bleDeviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to'**
  String get bleDeviceConnected;

  /// No description provided for @bleStartChat.
  ///
  /// In en, this message translates to:
  /// **'Connected. Start chatting.'**
  String get bleStartChat;

  /// No description provided for @bleNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get bleNoMessages;

  /// No description provided for @bleEncryptedHint.
  ///
  /// In en, this message translates to:
  /// **'Send encrypted messages via BLE Mesh'**
  String get bleEncryptedHint;

  /// No description provided for @dasnTitle.
  ///
  /// In en, this message translates to:
  /// **'DASN Storage'**
  String get dasnTitle;

  /// No description provided for @dasnUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get dasnUsage;

  /// No description provided for @dasnUsed.
  ///
  /// In en, this message translates to:
  /// **'USED'**
  String get dasnUsed;

  /// No description provided for @dasnObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get dasnObjects;

  /// No description provided for @dasnReplicas.
  ///
  /// In en, this message translates to:
  /// **'Replicas'**
  String get dasnReplicas;

  /// No description provided for @dasnIPFS.
  ///
  /// In en, this message translates to:
  /// **'IPFS Gateway'**
  String get dasnIPFS;

  /// No description provided for @dasnIPFSOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get dasnIPFSOnline;

  /// No description provided for @dasnIPFSOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get dasnIPFSOffline;

  /// No description provided for @dasnPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get dasnPin;

  /// No description provided for @dasnUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get dasnUnpin;

  /// No description provided for @dasnPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get dasnPinned;

  /// No description provided for @dasnUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Unpinned'**
  String get dasnUnpinned;

  /// No description provided for @dasnSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get dasnSize;

  /// No description provided for @dasnRetrieve.
  ///
  /// In en, this message translates to:
  /// **'Retrieve'**
  String get dasnRetrieve;

  /// No description provided for @dasnUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get dasnUnknown;

  /// No description provided for @networkDashboard.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkDashboard;

  /// No description provided for @networkLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get networkLive;

  /// No description provided for @networkPeersCount.
  ///
  /// In en, this message translates to:
  /// **'PEERS'**
  String get networkPeersCount;

  /// No description provided for @networkCircuits.
  ///
  /// In en, this message translates to:
  /// **'CIRCUITS'**
  String get networkCircuits;

  /// No description provided for @networkDLSpeed.
  ///
  /// In en, this message translates to:
  /// **'DL SPEED'**
  String get networkDLSpeed;

  /// No description provided for @networkULSpeed.
  ///
  /// In en, this message translates to:
  /// **'UL SPEED'**
  String get networkULSpeed;

  /// No description provided for @networkNat.
  ///
  /// In en, this message translates to:
  /// **'NAT'**
  String get networkNat;

  /// No description provided for @networkNatType.
  ///
  /// In en, this message translates to:
  /// **'NAT TYPE'**
  String get networkNatType;

  /// No description provided for @networkNatPublic.
  ///
  /// In en, this message translates to:
  /// **'Public (FullCone)'**
  String get networkNatPublic;

  /// No description provided for @networkNatPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private (Relayed)'**
  String get networkNatPrivate;

  /// No description provided for @networkRelay.
  ///
  /// In en, this message translates to:
  /// **'Relay'**
  String get networkRelay;

  /// No description provided for @networkRelayCircuits.
  ///
  /// In en, this message translates to:
  /// **'relay circuits'**
  String get networkRelayCircuits;

  /// No description provided for @networkLatency.
  ///
  /// In en, this message translates to:
  /// **'LATENCY'**
  String get networkLatency;

  /// No description provided for @networkUptime.
  ///
  /// In en, this message translates to:
  /// **'UPTIME'**
  String get networkUptime;

  /// No description provided for @networkBandwidth.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth'**
  String get networkBandwidth;

  /// No description provided for @networkDHTQueries.
  ///
  /// In en, this message translates to:
  /// **'DHT Queries'**
  String get networkDHTQueries;

  /// No description provided for @networkDHTQRY.
  ///
  /// In en, this message translates to:
  /// **'DHT QRY'**
  String get networkDHTQRY;

  /// No description provided for @networkMSGRTD.
  ///
  /// In en, this message translates to:
  /// **'MSG RTD'**
  String get networkMSGRTD;

  /// No description provided for @networkMessagesRouted.
  ///
  /// In en, this message translates to:
  /// **'Messages Routed'**
  String get networkMessagesRouted;

  /// No description provided for @networkTopology.
  ///
  /// In en, this message translates to:
  /// **'Network Topology'**
  String get networkTopology;

  /// No description provided for @networkPeerConnected.
  ///
  /// In en, this message translates to:
  /// **'A new peer has connected'**
  String get networkPeerConnected;

  /// No description provided for @networkPeerDisconnected.
  ///
  /// In en, this message translates to:
  /// **'A peer has disconnected'**
  String get networkPeerDisconnected;

  /// No description provided for @fileTransfer.
  ///
  /// In en, this message translates to:
  /// **'File Transfer'**
  String get fileTransfer;

  /// No description provided for @fileActiveTransfers.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE TRANSFERS'**
  String get fileActiveTransfers;

  /// No description provided for @fileSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get fileSending;

  /// No description provided for @fileReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get fileReceiving;

  /// No description provided for @fileComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get fileComplete;

  /// No description provided for @fileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get fileFailed;

  /// No description provided for @fileShare.
  ///
  /// In en, this message translates to:
  /// **'Share File'**
  String get fileShare;

  /// No description provided for @fileShareFile.
  ///
  /// In en, this message translates to:
  /// **'Share a file'**
  String get fileShareFile;

  /// No description provided for @fileEncrypted.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get fileEncrypted;

  /// No description provided for @fileSelecting.
  ///
  /// In en, this message translates to:
  /// **'Selecting file...'**
  String get fileSelecting;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall;

  /// No description provided for @voiceIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'is calling you...'**
  String get voiceIncomingCall;

  /// No description provided for @voiceDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get voiceDecline;

  /// No description provided for @voiceAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get voiceAccept;

  /// No description provided for @voiceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get voiceConnecting;

  /// No description provided for @voiceMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get voiceMute;

  /// No description provided for @voiceUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get voiceUnmute;

  /// No description provided for @voiceSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get voiceSpeaker;

  /// No description provided for @voiceHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get voiceHold;

  /// No description provided for @voiceResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get voiceResume;

  /// No description provided for @voiceEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get voiceEnd;

  /// No description provided for @voiceOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get voiceOnHold;

  /// No description provided for @voiceE2EEncrypted.
  ///
  /// In en, this message translates to:
  /// **'E2E Encrypted'**
  String get voiceE2EEncrypted;

  /// No description provided for @spaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get spaceTitle;

  /// No description provided for @spaceDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get spaceDiscover;

  /// No description provided for @spaceMySpaces.
  ///
  /// In en, this message translates to:
  /// **'My Spaces'**
  String get spaceMySpaces;

  /// No description provided for @spaceCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Space'**
  String get spaceCreate;

  /// No description provided for @spaceCreateSpace.
  ///
  /// In en, this message translates to:
  /// **'Create Space'**
  String get spaceCreateSpace;

  /// No description provided for @spaceJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get spaceJoin;

  /// No description provided for @spaceName.
  ///
  /// In en, this message translates to:
  /// **'Space Name'**
  String get spaceName;

  /// No description provided for @spaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get spaceDescription;

  /// No description provided for @spaceCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get spaceCreateButton;

  /// No description provided for @spaceMembers.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get spaceMembers;

  /// No description provided for @spaceJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get spaceJoined;

  /// No description provided for @spaceLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get spaceLastActive;

  /// No description provided for @spaceEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter Space'**
  String get spaceEnter;

  /// No description provided for @spaceEndToEnd.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted group spaces'**
  String get spaceEndToEnd;

  /// No description provided for @spaceNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'No spaces yet'**
  String get spaceNoSpaces;

  /// No description provided for @spaceCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first space!'**
  String get spaceCreateFirst;

  /// No description provided for @spaceDiscoverHint.
  ///
  /// In en, this message translates to:
  /// **'Discover public spaces to join'**
  String get spaceDiscoverHint;

  /// No description provided for @spaceJoinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Join Space'**
  String get spaceJoinConfirm;

  /// No description provided for @spaceJoinConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Join this space with E2EE encryption?'**
  String get spaceJoinConfirmDesc;

  /// No description provided for @groupChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Chats'**
  String get groupChatTitle;

  /// No description provided for @groupCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get groupCreateGroup;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get groupMembers;

  /// No description provided for @groupNoGroup.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get groupNoGroup;

  /// No description provided for @attachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachCamera;

  /// No description provided for @attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get attachPhoto;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get attachFile;

  /// No description provided for @attachLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get attachLocation;

  /// No description provided for @attachGIF.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get attachGIF;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @recordingSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get recordingSend;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
