import 'app_localizations.dart';

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '零界';

  @override
  String get appSubtitle => '零痕迹·零界限·零妥协';

  @override
  String get tabChats => '会话';

  @override
  String get tabSpace => '空间';

  @override
  String get tabWallet => '钱包';

  @override
  String get tabProfile => '我的';

  @override
  String get createIdentity => '创建身份';

  @override
  String get recoverIdentity => '恢复身份';

  @override
  String get mnemonicTitle => '恢复助记词';

  @override
  String get mnemonicDesc => '按顺序记下这 12 个单词。任何人拥有这组助记词就可以访问你的身份。请妥善保管，勿泄露。';

  @override
  String get copyPhrase => '复制到剪贴板';

  @override
  String get phraseCopied => '12个单词已复制';

  @override
  String get verifyIdentity => '验证助记词';

  @override
  String get verifyInstruction => '按正确顺序点击每个单词';

  @override
  String get verifySuccess => '身份验证成功';

  @override
  String get verifyFail => '顺序错误，请重试。';

  @override
  String get enterIdentity => '进入零界';

  @override
  String get enterApp => '进入零界';

  @override
  String get recoverInstruction => '输入你的 12 词恢复助记词以还原零界身份';

  @override
  String get recover => '恢复身份';

  @override
  String get recovering => '恢复中...';

  @override
  String get invalidMnemonic => '请输入恰好 12 个单词，用空格分隔。';

  @override
  String get welcomeTo => '欢迎来到';

  @override
  String get splashTagline => '零痕迹·零界限·零妥协';

  @override
  String get splashCreating => '正在创建加密身份...';

  @override
  String get splashRecovering => '正在恢复身份...';

  @override
  String get splashReady => '身份就绪';

  @override
  String get zeroChinese => '零 界';

  @override
  String get generateSeed => '生成助记词';

  @override
  String get generatingIdentity => '正在生成身份...';

  @override
  String get yourZeroIdentity => '你的零界身份';

  @override
  String get zeroTaglineDesc => '无需手机，无需邮箱，不留痕迹。\n只有助记词，只有你。';

  @override
  String get seedWarning => '切勿分享助记词。任何人拥有这些单词都可以访问你的身份。';

  @override
  String get saveSeedConfirm => '我已保存助记词';

  @override
  String get seedConfirmed => '助记词已确认。\n欢迎来到零界。';

  @override
  String get zeroIdLabel => '零界 ID';

  @override
  String get pasteWordsHint => '输入 12 个单词，空格分隔...\n\nabandon ability able about above absent\nabsorb abstract absurd abuse access accident';

  @override
  String get searchContacts => '搜索联系人...';

  @override
  String get noConversations => '还没有对话';

  @override
  String get noConversationsHint => '点击 + 开始安全聊天';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get online => '在线';

  @override
  String get typing => '正在输入...';

  @override
  String get encryptedMessage => '加密消息';

  @override
  String get messagePlaceholder => '输入消息...';

  @override
  String get send => '发送';

  @override
  String get connectToStart => '连接后开始聊天';

  @override
  String get e2eeOnline => '端到端加密 · 在线';

  @override
  String get voiceMsg => '语音';

  @override
  String get addContact => '添加联系人';

  @override
  String get addContactByID => '通过零界ID添加';

  @override
  String get addContactDesc => '输入零界ID或扫描二维码进行连接';

  @override
  String get zeroIdPlaceholder => '输入零界ID（如 Z3K7M2N8XP）';

  @override
  String get scanQR => '扫一扫';

  @override
  String get scanQRCode => '扫描二维码添加联系人';

  @override
  String get myQRCode => '我的二维码';

  @override
  String get myQRCodeCopied => '我的零界ID已复制到剪贴板';

  @override
  String get requestSent => '请求已发送！';

  @override
  String get friendRequestSent => '已向以下用户发送好友申请：';

  @override
  String get searchAnother => '继续搜索';

  @override
  String get addToContacts => '添加到通讯录';

  @override
  String get searchingNetwork => '正在搜索零界网络...';

  @override
  String get invalidZeroId => '请输入有效的零界ID（Z开头，10位字符）';

  @override
  String get qrScanningSim => '二维码扫描：模拟中...';

  @override
  String get recentRequests => '最近请求';

  @override
  String get searchByZeroId => '通过零界ID搜索';

  @override
  String get accepted => '已接受';

  @override
  String get declined => '已拒绝';

  @override
  String get lockAndExit => '锁定并退出';

  @override
  String get privacySecurity => '隐私与安全';

  @override
  String get appearance => '外观';

  @override
  String get about => '关于';

  @override
  String get securityLock => '安全锁';

  @override
  String get natStatus => 'NAT 状态';

  @override
  String get encryption => '加密方式';

  @override
  String get disappearingMessages => '阅后即焚';

  @override
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get animations => '动画效果';

  @override
  String get version => '版本';

  @override
  String get protocol => '协议';

  @override
  String get networkPeers => '网络节点';

  @override
  String get enabled => '已开启';

  @override
  String get disabled => '关闭';

  @override
  String get dark => '深色';

  @override
  String get subtle => '细腻';

  @override
  String get zeroCitizen => '零界公民';

  @override
  String get walletBalance => '余额';

  @override
  String get walletSend => '发送';

  @override
  String get walletReceive => '接收';

  @override
  String get walletSwap => '兑换';

  @override
  String get walletHistory => '记录';

  @override
  String get walletTokens => '代币';

  @override
  String get walletStake => '质押';

  @override
  String get noTransactions => '暂无交易记录';

  @override
  String get copyAddress => '复制地址';

  @override
  String get addressCopied => '地址已复制！';

  @override
  String get transactionHistory => '交易记录';

  @override
  String get aiAssistant => 'ZeroAI';

  @override
  String get aiThinking => 'ZeroAI 正在思考...';

  @override
  String get aiPlaceholder => '问 ZeroAI 任何问题...';

  @override
  String get aiQuickEncryption => '加密是如何工作的？';

  @override
  String get aiQuickWallet => '支持哪些钱包？';

  @override
  String get aiQuickPrivacy => '我的隐私如何被保护？';

  @override
  String get aiQuickTransfer => '如何转账代币？';

  @override
  String get clearConversation => '清空';

  @override
  String get bleTitle => 'BLE Mesh';

  @override
  String get bleScanning => '正在扫描 BLE 设备...';

  @override
  String get bleScanningAuto => '附近设备将会自动出现';

  @override
  String get bleNoDevices => '未发现设备';

  @override
  String get bleNoDevicesHint => '点击右上角蓝牙图标开始扫描';

  @override
  String get bleStartScan => '开始扫描';

  @override
  String get bleNearbyDevices => '附近设备';

  @override
  String get bleDiscovered => '已发现';

  @override
  String get bleConnect => '连接';

  @override
  String get bleConnected => '已连接';

  @override
  String get bleDisconnected => '已断开';

  @override
  String get bleScanningLabel => '扫描中';

  @override
  String get bleOfflineLabel => '离线';

  @override
  String get bleUnknownDevice => '未知设备';

  @override
  String get bleMessageViaBLE => '通过 BLE Mesh 发送消息';

  @override
  String get bleMessageHint => 'BLE 消息...';

  @override
  String get bleTapConnect => '点击连接';

  @override
  String get bleDeviceId => '设备 ID';

  @override
  String get bleSignal => '信号';

  @override
  String get bleStatus => '状态';

  @override
  String get bleZeroId => '零界 ID';

  @override
  String get bleAlreadyConnected => '已连接';

  @override
  String get bleDeviceConnected => '已连接至';

  @override
  String get bleStartChat => '已连接，开始聊天';

  @override
  String get bleNoMessages => '暂无消息';

  @override
  String get bleEncryptedHint => '通过 BLE Mesh 发送加密消息';

  @override
  String get dasnTitle => 'DASN 存储';

  @override
  String get dasnUsage => '存储用量';

  @override
  String get dasnUsed => '已用';

  @override
  String get dasnObjects => '对象数';

  @override
  String get dasnReplicas => '副本';

  @override
  String get dasnIPFS => 'IPFS 网关';

  @override
  String get dasnIPFSOnline => '在线';

  @override
  String get dasnIPFSOffline => '离线';

  @override
  String get dasnPin => '固定';

  @override
  String get dasnUnpin => '取消固定';

  @override
  String get dasnPinned => '已固定';

  @override
  String get dasnUnpinned => '未固定';

  @override
  String get dasnSize => '大小';

  @override
  String get dasnRetrieve => '检索';

  @override
  String get dasnUnknown => '未知';

  @override
  String get networkDashboard => '网络';

  @override
  String get networkLive => '在线';

  @override
  String get networkPeersCount => '节点数';

  @override
  String get networkCircuits => '中继线';

  @override
  String get networkDLSpeed => '下行速度';

  @override
  String get networkULSpeed => '上行速度';

  @override
  String get networkNat => 'NAT';

  @override
  String get networkNatType => 'NAT 类型';

  @override
  String get networkNatPublic => '公网 (FullCone)';

  @override
  String get networkNatPrivate => '内网 (中继)';

  @override
  String get networkRelay => '中继';

  @override
  String get networkRelayCircuits => '中继链路';

  @override
  String get networkLatency => '延迟';

  @override
  String get networkUptime => '运行时间';

  @override
  String get networkBandwidth => '带宽';

  @override
  String get networkDHTQueries => 'DHT 查询';

  @override
  String get networkDHTQRY => 'DHT 查询';

  @override
  String get networkMSGRTD => '消息路由';

  @override
  String get networkMessagesRouted => '已路由消息';

  @override
  String get networkTopology => '网络拓扑';

  @override
  String get networkPeerConnected => '有新节点加入网络';

  @override
  String get networkPeerDisconnected => '有节点断开连接';

  @override
  String get fileTransfer => '文件传输';

  @override
  String get fileActiveTransfers => '活跃传输';

  @override
  String get fileSending => '发送中';

  @override
  String get fileReceiving => '接收中';

  @override
  String get fileComplete => '已完成';

  @override
  String get fileFailed => '失败';

  @override
  String get fileShare => '分享文件';

  @override
  String get fileShareFile => '分享一个文件';

  @override
  String get fileEncrypted => '端到端加密';

  @override
  String get fileSelecting => '选择文件中...';

  @override
  String get voiceCall => '语音通话';

  @override
  String get voiceIncomingCall => '正在呼叫你...';

  @override
  String get voiceDecline => '拒绝';

  @override
  String get voiceAccept => '接听';

  @override
  String get voiceConnecting => '连接中...';

  @override
  String get voiceMute => '静音';

  @override
  String get voiceUnmute => '取消静音';

  @override
  String get voiceSpeaker => '扬声器';

  @override
  String get voiceHold => '保持';

  @override
  String get voiceResume => '恢复';

  @override
  String get voiceEnd => '挂断';

  @override
  String get voiceOnHold => '已保持';

  @override
  String get voiceE2EEncrypted => '端到端加密';

  @override
  String get spaceTitle => '空间';

  @override
  String get spaceDiscover => '发现';

  @override
  String get spaceMySpaces => '我的空间';

  @override
  String get spaceCreate => '创建空间';

  @override
  String get spaceCreateSpace => '创建空间';

  @override
  String get spaceJoin => '加入';

  @override
  String get spaceName => '空间名称';

  @override
  String get spaceDescription => '描述';

  @override
  String get spaceCreateButton => '创建';

  @override
  String get spaceMembers => '成员';

  @override
  String get spaceJoined => '已加入';

  @override
  String get spaceLastActive => '最近活跃';

  @override
  String get spaceEnter => '进入空间';

  @override
  String get spaceEndToEnd => '端到端加密群组空间';

  @override
  String get spaceNoSpaces => '还没有空间';

  @override
  String get spaceCreateFirst => '创建你的第一个空间吧！';

  @override
  String get spaceDiscoverHint => '发现并加入公开空间';

  @override
  String get spaceJoinConfirm => '加入空间';

  @override
  String get spaceJoinConfirmDesc => '加入此端到端加密空间？';

  @override
  String get groupChatTitle => '群聊';

  @override
  String get groupCreateGroup => '创建群组';

  @override
  String get groupMembers => '名成员';

  @override
  String get groupNoGroup => '暂无群组';

  @override
  String get attachCamera => '拍照';

  @override
  String get attachPhoto => '相册';

  @override
  String get attachFile => '文件';

  @override
  String get attachLocation => '位置';

  @override
  String get attachGIF => 'GIF';

  @override
  String get recording => '录音中';

  @override
  String get recordingSend => '发送';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get ok => '好的';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中...';

  @override
  String get creating => '创建中...';

  @override
  String get done => '完成';
}
