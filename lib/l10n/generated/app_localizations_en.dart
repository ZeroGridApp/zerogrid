import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zero';

  @override
  String get appSubtitle => 'Zero trace. Zero limit. Zero compromise.';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabSpace => 'Space';

  @override
  String get tabWallet => 'Wallet';

  @override
  String get tabProfile => 'Profile';

  @override
  String get createIdentity => 'Create Identity';

  @override
  String get recoverIdentity => 'Recover Identity';

  @override
  String get mnemonicTitle => 'Your Recovery Phrase';

  @override
  String get mnemonicDesc => 'Write these 12 words down in order. Anyone with this phrase can access your identity. Keep it secret, keep it safe.';

  @override
  String get copyPhrase => 'Copy to Clipboard';

  @override
  String get phraseCopied => '12 words copied';

  @override
  String get verifyIdentity => 'Verify your seed';

  @override
  String get verifyInstruction => 'Tap each word in the correct order.';

  @override
  String get verifySuccess => 'Identity Verified';

  @override
  String get verifyFail => 'Incorrect order. Please try again.';

  @override
  String get enterIdentity => 'Enter Zero';

  @override
  String get enterApp => 'Enter Zero';

  @override
  String get recoverInstruction => 'Enter your 12-word recovery seed to restore your Zero identity.';

  @override
  String get recover => 'Recover Identity';

  @override
  String get recovering => 'Recovering...';

  @override
  String get invalidMnemonic => 'Enter exactly 12 words separated by spaces.';

  @override
  String get welcomeTo => 'Welcome to';

  @override
  String get splashTagline => 'Zero trace. Zero limit. Zero compromise.';

  @override
  String get splashCreating => 'Creating your cryptographic identity...';

  @override
  String get splashRecovering => 'Recovering your identity...';

  @override
  String get splashReady => 'Identity ready';

  @override
  String get zeroChinese => '零 界';

  @override
  String get generateSeed => 'Generate Seed';

  @override
  String get generatingIdentity => 'Generating your identity...';

  @override
  String get yourZeroIdentity => 'Your Zero identity';

  @override
  String get zeroTaglineDesc => 'No phone. No email. No trace.\nJust a seed. Just you.';

  @override
  String get seedWarning => 'Never share your seed. Anyone with these words can access your identity.';

  @override
  String get saveSeedConfirm => 'I\'ve saved my seed';

  @override
  String get seedConfirmed => 'Your seed is confirmed.\nWelcome to Zero.';

  @override
  String get zeroIdLabel => 'ZERO ID';

  @override
  String get pasteWordsHint => 'Enter your 12 words separated by spaces...\n\nabandon ability able about above absent\nabsorb abstract absurd abuse access accident';

  @override
  String get searchContacts => 'Search contacts...';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get noConversationsHint => 'Tap + to start a secure chat';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get online => 'Online';

  @override
  String get typing => 'typing...';

  @override
  String get encryptedMessage => 'Encrypted message';

  @override
  String get messagePlaceholder => 'Message...';

  @override
  String get send => 'Send';

  @override
  String get connectToStart => 'Connect to start chatting';

  @override
  String get e2eeOnline => 'E2EE · Online';

  @override
  String get voiceMsg => 'Voice';

  @override
  String get addContact => 'Add Contact';

  @override
  String get addContactByID => 'Add by ZeroID';

  @override
  String get addContactDesc => 'Enter a ZeroID or scan a QR code to connect';

  @override
  String get zeroIdPlaceholder => 'Enter Zero ID (e.g. Z3K7M2N8XP)';

  @override
  String get scanQR => 'Scan QR';

  @override
  String get scanQRCode => 'Scan QR code to add contact';

  @override
  String get myQRCode => 'My QR Code';

  @override
  String get myQRCodeCopied => 'My Zero ID copied to clipboard';

  @override
  String get requestSent => 'Request sent!';

  @override
  String get friendRequestSent => 'Friend request sent to';

  @override
  String get searchAnother => 'Search Another';

  @override
  String get addToContacts => 'Add to Contacts';

  @override
  String get searchingNetwork => 'Searching Zero network...';

  @override
  String get invalidZeroId => 'Please enter a valid Zero ID (starts with Z, 10 chars)';

  @override
  String get qrScanningSim => 'QR scanning: simulating...';

  @override
  String get recentRequests => 'RECENT REQUESTS';

  @override
  String get searchByZeroId => 'SEARCH BY ZERO ID';

  @override
  String get accepted => 'Accepted';

  @override
  String get declined => 'Declined';

  @override
  String get lockAndExit => 'Lock & Exit';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get appearance => 'Appearance';

  @override
  String get about => 'About';

  @override
  String get securityLock => 'Security Lock';

  @override
  String get natStatus => 'NAT Status';

  @override
  String get encryption => 'Encryption';

  @override
  String get disappearingMessages => 'Disappearing Messages';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get animations => 'Animations';

  @override
  String get version => 'Version';

  @override
  String get protocol => 'Protocol';

  @override
  String get networkPeers => 'Network Peers';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Off';

  @override
  String get dark => 'Dark';

  @override
  String get subtle => 'Subtle';

  @override
  String get zeroCitizen => 'Zero Citizen';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletSend => 'Send';

  @override
  String get walletReceive => 'Receive';

  @override
  String get walletSwap => 'Swap';

  @override
  String get walletHistory => 'History';

  @override
  String get walletTokens => 'Tokens';

  @override
  String get walletStake => 'Stake';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get copyAddress => 'Copy Address';

  @override
  String get addressCopied => 'Address copied!';

  @override
  String get transactionHistory => 'TRANSACTION HISTORY';

  @override
  String get aiAssistant => 'ZeroAI';

  @override
  String get aiThinking => 'ZeroAI is thinking...';

  @override
  String get aiPlaceholder => 'Ask ZeroAI anything...';

  @override
  String get aiQuickEncryption => 'How does encryption work?';

  @override
  String get aiQuickWallet => 'What wallets do you support?';

  @override
  String get aiQuickPrivacy => 'How is my privacy protected?';

  @override
  String get aiQuickTransfer => 'How to transfer tokens?';

  @override
  String get clearConversation => 'Clear';

  @override
  String get bleTitle => 'BLE Mesh';

  @override
  String get bleScanning => 'Scanning for BLE devices...';

  @override
  String get bleScanningAuto => 'Nearby devices will appear automatically';

  @override
  String get bleNoDevices => 'No devices found';

  @override
  String get bleNoDevicesHint => 'Tap the Bluetooth icon to start scanning';

  @override
  String get bleStartScan => 'Start Scan';

  @override
  String get bleNearbyDevices => 'Nearby Devices';

  @override
  String get bleDiscovered => 'DISCOVERED';

  @override
  String get bleConnect => 'Connect';

  @override
  String get bleConnected => 'Connected';

  @override
  String get bleDisconnected => 'Disconnected';

  @override
  String get bleScanningLabel => 'SCANNING';

  @override
  String get bleOfflineLabel => 'OFFLINE';

  @override
  String get bleUnknownDevice => 'Unknown Device';

  @override
  String get bleMessageViaBLE => 'Message via BLE Mesh';

  @override
  String get bleMessageHint => 'BLE message...';

  @override
  String get bleTapConnect => 'Tap to connect';

  @override
  String get bleDeviceId => 'Device ID';

  @override
  String get bleSignal => 'Signal';

  @override
  String get bleStatus => 'Status';

  @override
  String get bleZeroId => 'Zero ID';

  @override
  String get bleAlreadyConnected => 'Already Connected';

  @override
  String get bleDeviceConnected => 'Connected to';

  @override
  String get bleStartChat => 'Connected. Start chatting.';

  @override
  String get bleNoMessages => 'No messages yet';

  @override
  String get bleEncryptedHint => 'Send encrypted messages via BLE Mesh';

  @override
  String get dasnTitle => 'DASN Storage';

  @override
  String get dasnUsage => 'Storage Usage';

  @override
  String get dasnUsed => 'USED';

  @override
  String get dasnObjects => 'Objects';

  @override
  String get dasnReplicas => 'Replicas';

  @override
  String get dasnIPFS => 'IPFS Gateway';

  @override
  String get dasnIPFSOnline => 'Online';

  @override
  String get dasnIPFSOffline => 'Offline';

  @override
  String get dasnPin => 'Pin';

  @override
  String get dasnUnpin => 'Unpin';

  @override
  String get dasnPinned => 'Pinned';

  @override
  String get dasnUnpinned => 'Unpinned';

  @override
  String get dasnSize => 'Size';

  @override
  String get dasnRetrieve => 'Retrieve';

  @override
  String get dasnUnknown => 'Unknown';

  @override
  String get networkDashboard => 'Network';

  @override
  String get networkLive => 'LIVE';

  @override
  String get networkPeersCount => 'PEERS';

  @override
  String get networkCircuits => 'CIRCUITS';

  @override
  String get networkDLSpeed => 'DL SPEED';

  @override
  String get networkULSpeed => 'UL SPEED';

  @override
  String get networkNat => 'NAT';

  @override
  String get networkNatType => 'NAT TYPE';

  @override
  String get networkNatPublic => 'Public (FullCone)';

  @override
  String get networkNatPrivate => 'Private (Relayed)';

  @override
  String get networkRelay => 'Relay';

  @override
  String get networkRelayCircuits => 'relay circuits';

  @override
  String get networkLatency => 'LATENCY';

  @override
  String get networkUptime => 'UPTIME';

  @override
  String get networkBandwidth => 'Bandwidth';

  @override
  String get networkDHTQueries => 'DHT Queries';

  @override
  String get networkDHTQRY => 'DHT QRY';

  @override
  String get networkMSGRTD => 'MSG RTD';

  @override
  String get networkMessagesRouted => 'Messages Routed';

  @override
  String get networkTopology => 'Network Topology';

  @override
  String get networkPeerConnected => 'A new peer has connected';

  @override
  String get networkPeerDisconnected => 'A peer has disconnected';

  @override
  String get fileTransfer => 'File Transfer';

  @override
  String get fileActiveTransfers => 'ACTIVE TRANSFERS';

  @override
  String get fileSending => 'Sending';

  @override
  String get fileReceiving => 'Receiving';

  @override
  String get fileComplete => 'Complete';

  @override
  String get fileFailed => 'Failed';

  @override
  String get fileShare => 'Share File';

  @override
  String get fileShareFile => 'Share a file';

  @override
  String get fileEncrypted => 'End-to-end encrypted';

  @override
  String get fileSelecting => 'Selecting file...';

  @override
  String get voiceCall => 'Voice Call';

  @override
  String get voiceIncomingCall => 'is calling you...';

  @override
  String get voiceDecline => 'Decline';

  @override
  String get voiceAccept => 'Accept';

  @override
  String get voiceConnecting => 'Connecting...';

  @override
  String get voiceMute => 'Mute';

  @override
  String get voiceUnmute => 'Unmute';

  @override
  String get voiceSpeaker => 'Speaker';

  @override
  String get voiceHold => 'Hold';

  @override
  String get voiceResume => 'Resume';

  @override
  String get voiceEnd => 'End';

  @override
  String get voiceOnHold => 'On Hold';

  @override
  String get voiceE2EEncrypted => 'E2E Encrypted';

  @override
  String get spaceTitle => 'Spaces';

  @override
  String get spaceDiscover => 'Discover';

  @override
  String get spaceMySpaces => 'My Spaces';

  @override
  String get spaceCreate => 'Create Space';

  @override
  String get spaceCreateSpace => 'Create Space';

  @override
  String get spaceJoin => 'Join';

  @override
  String get spaceName => 'Space Name';

  @override
  String get spaceDescription => 'Description';

  @override
  String get spaceCreateButton => 'Create';

  @override
  String get spaceMembers => 'members';

  @override
  String get spaceJoined => 'Joined';

  @override
  String get spaceLastActive => 'Last active';

  @override
  String get spaceEnter => 'Enter Space';

  @override
  String get spaceEndToEnd => 'End-to-end encrypted group spaces';

  @override
  String get spaceNoSpaces => 'No spaces yet';

  @override
  String get spaceCreateFirst => 'Create your first space!';

  @override
  String get spaceDiscoverHint => 'Discover public spaces to join';

  @override
  String get spaceJoinConfirm => 'Join Space';

  @override
  String get spaceJoinConfirmDesc => 'Join this space with E2EE encryption?';

  @override
  String get groupChatTitle => 'Group Chats';

  @override
  String get groupCreateGroup => 'Create Group';

  @override
  String get groupMembers => 'members';

  @override
  String get groupNoGroup => 'No groups yet';

  @override
  String get attachCamera => 'Camera';

  @override
  String get attachPhoto => 'Photo';

  @override
  String get attachFile => 'File';

  @override
  String get attachLocation => 'Location';

  @override
  String get attachGIF => 'GIF';

  @override
  String get recording => 'Recording';

  @override
  String get recordingSend => 'Send';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get creating => 'Creating...';

  @override
  String get done => 'Done';
}
