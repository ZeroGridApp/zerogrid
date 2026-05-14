import 'dart:math';

class ZeroAIService {
  factory ZeroAIService() => _instance;
  ZeroAIService._internal();
  static final ZeroAIService _instance = ZeroAIService._internal();

  final _random = Random();

  String generateResponse(String query) {
    final q = query.toLowerCase();

    if (_containsAny(q, ['你好', 'hello', 'hi', 'hey', '在吗', '在不在'])) {
      return _greet();
    }
    if (_containsAny(q, ['你是谁', '你是什么', '你的名字', '介绍自己'])) {
      return _whoAmI();
    }
    if (_containsAll(q, ['洋葱', '路由']) || _containsAll(q, ['onion', 'routing'])) {
      return _onionRouting();
    }
    if (_containsAll(q, ['加密', '工作', '怎么']) || _containsAll(q, ['encrypt', 'work'])) {
      return _encryption();
    }
    if (_containsAny(q, ['e2ee', '端到端', '端对端'])) {
      return _e2ee();
    }
    if (_containsAny(q, ['钱包', 'wallet']) && _containsAny(q, ['支持', '哪些', '什么链', '几条'])) {
      return _walletChains();
    }
    if (_containsAny(q, ['钱包', 'wallet']) && _containsAny(q, ['bip44', 'bip', '助记词', 'mnemonic'])) {
      return _bip44();
    }
    if (_containsAny(q, ['钱包', 'wallet']) && _containsAny(q, ['创建', 'create', '新建', '添加'])) {
      return _createWallet();
    }
    if (_containsAny(q, ['钱包', 'wallet'])) {
      return _walletBasics();
    }
    if (_containsAll(q, ['zero', 'pay']) || _containsAny(q, ['zeropay', '/pay'])) {
      return _zeroPay();
    }
    if (_containsAll(q, ['域名', 'zero']) || _containsAll(q, ['.zero', 'domain']) || q.contains('zerodns')) {
      return _zeroDNS();
    }
    if (_containsAny(q, ['dasn', '存储', 'storage', '文件', '上传', 'download', '下载', 'cid'])) {
      return _dasn();
    }
    if (_containsAll(q, ['群聊', '加密']) || _containsAll(q, ['sender', 'key'])) {
      return _groupE2EE();
    }
    if (_containsAll(q, ['群聊', '创建']) || _containsAll(q, ['群', '怎么', '新建']) || _containsAll(q, ['group', 'create'])) {
      return _createGroup();
    }
    if (_containsAny(q, ['did', '身份', 'identity', '零界id', 'zeroid'])) {
      return _did();
    }
    if (_containsAny(q, ['zero', '代币', 'token', '经济', '通缩', '通胀', '价格', '估值'])) {
      return _zetEconomics();
    }
    if (_containsAny(q, ['隐私', 'privacy', '匿名', 'anonymous'])) {
      return _privacy();
    }
    if (_containsAny(q, ['转账', 'transfer', 'send', '发送']) && _containsAny(q, ['token', 'zero', '币', '金额'])) {
      return _transfer();
    }
    if (_containsAny(q, ['怎么用', '使用', '教程', '开始', '入门', 'get started', 'tutorial'])) {
      return _tutorial();
    }
    if (_containsAny(q, ['安全', 'security', '安全吗', '破解'])) {
      return _security();
    }
    if (_containsAny(q, ['频道', 'channel', '广播', 'broadcast'])) {
      return _channels();
    }
    if (_containsAny(q, ['集市', 'market', '买卖', '购物', '交易'])) {
      return _zeroMarket();
    }
    if (_containsAny(q, ['节点', 'node', '中继', 'relay']) && _containsAny(q, ['挖矿', '收益', '赚钱', 'mine'])) {
      return _nodeMining();
    }
    if (_containsAny(q, ['节点', 'node', '中继', 'relay'])) {
      return _nodes();
    }
    if (_containsAny(q, ['对战', 'game', '游戏', '娱乐'])) {
      return _games();
    }
    if (_containsAny(q, ['未来', '路线图', 'roadmap', '规划', '计划'])) {
      return _roadmap();
    }
    if (_containsAny(q, ['对比', '比较', 'vs', '区别', '竞品'])) {
      return _comparison();
    }
    if (_containsAny(q, ['谢谢', 'thank', '感谢', '厉害'])) {
      return _thanks();
    }

    return _fallback();
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  bool _containsAll(String text, List<String> keywords) {
    return keywords.every((k) => text.contains(k));
  }

  String _greet() {
    final msgs = [
      '👋 你好！我是 **ZeroAI**，零界的智能助手。\n\n我可以回答关于加密协议、多链钱包、洋葱路由、DASN 存储、ZeroDNS 域名、ZERO 代币经济等全生态问题。\n\n直接问我吧！',
    ];
    return msgs[_random.nextInt(msgs.length)];
  }

  String _whoAmI() {
    return '我是 **ZeroAI**，Zero 生态的专属 AI 助手。\n\n'
        '🌐 运行在零界协议的端侧推理引擎上\n'
        '🧠 知识覆盖 Zero 全栈：加密、钱包、路由、存储、域名、代币经济\n'
        '🔐 完全本地推理，你的提问永不离开设备\n\n'
        '我不只是 Q&A 机器人。未来我会支持：\n'
        '  · 智能消息摘要（总结群聊内容）\n'
        '  · 实时多语言翻译（在加密层内完成）\n'
        '  · 交易风险评估（链上行为分析）\n'
        '  · 智能内容审核（去中心化，非审查）';
  }

  String _encryption() {
    return 'Zero 采用三明治加密架构，确保你的隐私绝对安全：\n\n'
        '**第一层：X3DH 初始握手**\n'
        '  · 通过 4 次 DH 密钥交换建立初始会话密钥\n'
        '  · 支持异步通信，即使对方离线也能建立安全通道\n'
        '  · 使用 P-256 (secp256r1) 椭圆曲线\n\n'
        '**第二层：Double Ratchet 消息棘轮**\n'
        '  · DH 棘轮：定期更新共享密钥，实现前向安全性\n'
        '  · 对称棘轮：每条消息独立派生 ChaCha20 密钥\n'
        '  · 每发送/接收一条消息，棘轮前进一格\n\n'
        '**第三层：洋葱路由**\n'
        '  · 消息经过 3 跳中继节点转发\n'
        '  · 每跳使用独立的 ChaCha20-Poly1305 AEAD 加密\n'
        '  · 中继节点不知道消息的完整路径\n\n'
        '✅ 前向保密（Forward Secrecy）\n'
        '✅ 后妥协安全（Post-Compromise Security）\n'
        '✅ 默认可否认性（Deniable Authentication）';
  }

  String _e2ee() {
    return 'Zero 的 E2EE 基于 **X3DH + Double Ratchet**，与 Signal 协议同源：\n\n'
        '🔐 **X3DH（扩展三重 Diffie-Hellman）**\n'
        '  · 4 次 DH 密钥交换建立初始会话\n'
        '  · 支持离线预密钥（PreKey Bundle）\n'
        '  · 一次性预密钥防重放攻击\n\n'
        '🔄 **Double Ratchet（双棘轮）**\n'
        '  · 每条消息使用唯一对称密钥\n'
        '  · DH 棘轮 + 对称棘轮双重保障\n'
        '  · 密钥泄露后自动恢复安全性\n\n'
        '📦 **群聊 E2EE（Sender Key）**\n'
        '  · 每个成员拥有独立 Sender Key\n'
        '  · 成员变动时全量密钥轮换\n'
        '  · Epoch 机制防重放\n\n'
        '所有消息、通话、文件传输均默认启用。';
  }

  String _walletChains() {
    return '**ZeroPay 多链钱包** 基于 BIP44 标准，从单一助记词派生：\n\n'
        '| 链 | 地址格式 | BIP44 路径 | 状态 |\n'
        '|-----|---------|-----------|------|\n'
        '| BTC | P2PKH (1...) | m/44\'/0\'/0\'/0 | ✅ 已支持 |\n'
        '| ETH | EVM (0x...) | m/44\'/60\'/0\'/0 | ✅ 已支持 |\n'
        '| BSC | EVM（共享ETH） | m/44\'/60\'/0\'/0 | ✅ 已支持 |\n'
        '| TRX | TRC-20 (T...) | m/44\'/195\'/0\'/0 | ✅ 已支持 |\n'
        '| SOL | SPL | m/44\'/501\'/0\'/0 | ✅ 已支持 |\n\n'
        '⚠️ ETH 和 BSC 共享同一地址，注意转账前确认网络。\n'
        '🔐 私钥仅存储在设备本地，永不离开——你是唯一掌控者。';
  }

  String _bip44() {
    return '**BIP44 分层确定性钱包** 从单一种子派生无限地址：\n\n'
        '🌳 层级结构：\n'
        '  `m / purpose\' / coin_type\' / account\' / change / index`\n\n'
        '  · purpose\' = 44\'（BIP44 标准）\n'
        '  · coin_type\' = 链标识（0\'=BTC, 60\'=ETH, 195\'=TRX, 501\'=SOL）\n'
        '  · account\' = 子账户（默认 0\'）\n'
        '  · change = 0 收款 / 1 找零\n'
        '  · index = 地址序号\n\n'
        '🔑 只需记住 12 或 24 个助记词，即可恢复所有链的全部地址。\n'
        '⚠️ 助记词 = 资产主权。请离线保存，绝不分享给任何人。';
  }

  String _createWallet() {
    return '创建 ZeroPay 多链钱包只需三步：\n\n'
        '1️⃣ 打开 Zero → 钱包 Tab → 点击"创建新钱包"\n'
        '2️⃣ 系统生成 12/24 个 BIP39 助记词 → 离线抄写保存\n'
        '3️⃣ 确认助记词后，自动派生所有链地址\n\n'
        '安全提示：\n'
        '  🔒 助记词是钱包的唯一钥匙，丢失无法找回\n'
        '  📝 推荐纸质备份 + 金属板备份双保险\n'
        '  🚫 绝不截图、不云存储、不发给任何人\n'
        '  📱 设备丢失时，用助记词在新设备恢复\n\n'
        '你已拥有完全的资产主权。';
  }

  String _walletBasics() {
    return 'Zero 内嵌 **ZeroPay 多链钱包**，核心特性：\n\n'
        '💰 多链支持：BTC / ETH / BSC / TRX / SOL\n'
        '🔑 私钥本地：永不离开设备\n'
        '📋 BIP44 标准：助记词恢复全链地址\n'
        '🔄 Zero ID 转账：零手续费、实时到账\n'
        '🧾 交易历史：链上拉取 + 本地缓存\n'
        '📸 QR 收付款：一键生成收款码\n'
        '💬 聊天内支付：/pay 指令智能解析\n\n'
        '进入钱包 Tab 查看所有功能。';
  }

  String _zeroPay() {
    return '**ZeroPay** —— 聊天框里的支付革命 💬→💰\n\n'
        '在任意聊天框输入 `/pay` 指令即可发起支付：\n\n'
        '```\n'
        '/pay 0.5 ETH 给 Alice 买咖啡 ☕\n'
        '/pay 100 USDT @Bob 昨天午饭 🍜\n'
        '/pay 10 SOL 0xAbC...DeF NFT交易\n'
        '```\n\n'
        'AI 自动识别：\n'
        '  · 金额 + 币种（ETH/USDT/SOL 等）\n'
        '  · 收款方（名字/地址/DID）\n'
        '  · 备注（可选）\n'
        '  · 链选择（根据币种自动匹配）\n\n'
        '弹出确认卡片 → 确认 Gas 费 → 本地签名 → 广播上链 ✅\n\n'
        'Zero ID 间转账 **零手续费、秒到**。';
  }

  String _zeroDNS() {
    return '**ZeroDNS** —— 你的 .zero 域名就是你 Web3 世界的身份证 🌐\n\n'
        '阶梯定价：\n'
        '  · 4 字符及以上：10 ZERO/年\n'
        '  · 3 字符：100 ZERO/年\n'
        '  · 2 字符：500 ZERO/年\n'
        '  · 1 字符：1000 ZERO/年\n\n'
        '域名用途：\n'
        '  🔗 替代长地址：alice.zero → ZID + 多链地址\n'
        '  📧 去中心化消息：直接向 alice.zero 发送 E2EE 消息\n'
        '  🏪 未来 ZeroStore：alice.zero 成为个人商店\n'
        '  🎨 域名即 NFT：可转让、可拍卖\n\n'
        '在钱包 Tab → 右上角 🌐 图标打开 ZeroDNS。';
  }

  String _dasn() {
    return '**DASN**（Decentralized Anonymous Storage Network）—— 你的数据，你做主 📦\n\n'
        '存储流程：\n'
        '  1️⃣ 选择文件 → 客户端分片（256KB/片）\n'
        '  2️⃣ 每片 SHA256 计算 CID（内容寻址）\n'
        '  3️⃣ 分片分发到多个存储节点（默认 3 副本）\n'
        '  4️⃣ 下载时按 CID 检索 → 重新组装\n\n'
        '特性：\n'
        '  · 📍 内容寻址：相同文件相同 CID，天然去重\n'
        '  · 🔒 端到端加密：存储节点无法查看内容\n'
        '  · 🌍 全球分布式：3-5 个节点保存副本\n'
        '  · 📌 可固定（Pin）：重要文件永不被清理\n'
        '  · 💰 按量付费：~0.1 ZERO/GB/月\n\n'
        '在 DASN Tab → "+" 按钮上传文件体验。';
  }

  String _groupE2EE() {
    return 'Zero 群聊采用 **Sender Key 协议** 实现真正的群组端到端加密：\n\n'
        '🔑 密钥架构：\n'
        '  · 每个成员拥有独立的 256-bit ChaCha20 Sender Key\n'
        '  · 发送消息时用自己的 Sender Key 加密\n'
        '  · 接收方用发送者的 Sender Key 解密\n\n'
        '🔄 密钥管理：\n'
        '  · 成员加入 → 分配新 Key + 分发当前 Keys\n'
        '  · 成员离开 → 全量密钥轮换（防止已离开成员解密）\n'
        '  · Epoch 递增：每次轮换 epoch+1\n'
        '  · 防重放：epoch 不匹配的消息直接拒绝\n\n'
        '⚖️ 对比 MLS：更简单，更适合中小群组（<1000人）。\n'
        '想了解更多？查看群聊 AppBar 的 🔒 Sender Key v1 标识。';
  }

  String _createGroup() {
    return '创建加密群聊只需几步：\n\n'
        '1️⃣ 聊天室 Tab → 右上角 "+" → "New Group"\n'
        '2️⃣ 输入群名称 → 添加头像 → 设置群公告\n'
        '3️⃣ 从联系人列表勾选初始成员\n'
        '4️⃣ 每个成员获得独立 Sender Key → E2EE 自动生效\n\n'
        '或通过邀请码加入：\n'
        '  群主分享 6 位邀请码 → 成员输入即可加入\n'
        '  加入时自动获取所有 Sender Keys\n\n'
        '所有群聊默认端到端加密，管理员也无法查看消息内容。';
  }

  String _did() {
    return 'Zero 使用 **W3C DID（去中心化身份标识符）** 标准：\n\n'
        'DID 格式：`did:zero:{CID}`\n'
        '  · CID 由身份公钥的 SHA256 哈希生成\n'
        '  · 格式：`z0` + 64位十六进制字符\n\n'
        '🆔 Zero ID = 你的匿名身份\n'
        '  · 无需手机号、邮箱\n'
        '  · 由 BIP39 助记词派生（你拥有完整主权）\n'
        '  · 一个 DID 绑定所有链地址\n'
        '  · 跨 DApp 通用身份\n\n'
        '📜 DID 文档包含：\n'
        '  · 身份公钥（ECDSA P-256）\n'
        '  · 加密公钥（用于 E2EE）\n'
        '  · 服务端点（中继节点地址）\n\n'
        '你的身份，你完全掌控。';
  }

  String _zetEconomics() {
    return '**ZERO 代币经济模型** 完整解析：\n\n'
        '📊 总量：10 亿 ZERO，永不变\n\n'
        '分配：\n'
        '  · 节点激励 40%（4亿）— 20年线性递减释放\n'
        '  · 生态基金 20%（2亿）— DAO 投票拨款\n'
        '  · 创始团队 15%（1.5亿）— 4年解禁\n'
        '  · 社区空投 15%（1.5亿）— 3轮\n'
        '  · DAO 金库 10%（1亿）— 永远归社区\n\n'
        '通胀路径：\n'
        '  Y1: 81% → Y5: 11% → Y10: ~3% → Y20: 0%\n\n'
        '通缩临界点：~Y6，约 100万 DAU 即可触发\n\n'
        '三重价值捕获：\n'
        '  ⓵ Gas（燃料）— 每次服务消耗 ZERO\n'
        '  ⓶ Stake（股权）— 节点质押赚收益\n'
        '  ⓷ Vote（选票）— 治理投票权\n\n'
        '保守估值：100万 DAU → ZERO ~$0.50\n'
        '详细分析请查看 ZERO_ECONOMIC_MODEL.md。';
  }

  String _privacy() {
    return 'Zero 的隐私保护是体系化设计，不只是口号：\n\n'
        '🔒 通信隐私\n'
        '  · E2EE：服务端零知识\n'
        '  · 洋葱路由：中继节点不知全路径\n'
        '  · Sender Key：群聊同样加密\n\n'
        '🆔 身份隐私\n'
        '  · 无手机号、无邮箱注册\n'
        '  · DID 匿名标识符\n'
        '  · 不使用个人信息\n\n'
        '📡 网络隐私\n'
        '  · 洋葱路由（类似 Tor）\n'
        '  · BLE Mesh 离线通信\n'
        '  · 不记录 IP/MAC\n\n'
        '💰 财务隐私\n'
        '  · 私钥纯本地\n'
        '  · Zero ID 间转账不留链上痕迹\n'
        '  · 不追踪交易行为\n\n'
        '你的每次呼吸，都只属于你。';
  }

  String _transfer() {
    return '**ZeroPay 转账** 两种模式：\n\n'
        '🚀 Zero ID 转账（推荐）\n'
        '  · 零手续费、实时到账\n'
        '  · 聊天框 /pay 直接发起\n'
        '  · 双方 Zero 用户专用\n\n'
        '⛓️ 链上转账\n'
        '  · 支持 BTC/ETH/BSC/TRX/SOL\n'
        '  · 需支付对应链 Gas 费\n'
        '  · 本地签名 → 广播上链\n\n'
        '操作步骤：\n'
        '  1. 钱包 Tab → 选择链 → 发送\n'
        '  2. 输入地址或 Zero ID\n'
        '  3. 确认金额 + Gas 费\n'
        '  4. 签名 → 完成 ✅\n\n'
        '💡 小额高频用 Zero ID，大额链上用链上。';
  }

  String _tutorial() {
    return '🎓 **Zero 快速入门** —— 三步开始你的去中心化之旅\n\n'
        '**第一步：创建身份** 🆔\n'
        '  打开 Zero → 生成 12 个 BIP39 助记词 → 抄写备份\n'
        '  → 系统自动创建你的 DID 和加密密钥\n\n'
        '**第二步：添加联系人** 👥\n'
        '  联系人 Tab → 搜索 Zero ID 或扫码 → 发起 E2EE 聊天\n'
        '  或开启附近发现 → 雷达扫描周边 Zero 用户\n\n'
        '**第三步：畅享隐私通信** 💬\n'
        '  点对点加密聊天 → 创建加密群聊 → 发送加密文件\n'
        '  浏览 ZeroFeed → 管理 .zero 域名 → 用 /pay 转账\n\n'
        '🚀 现在你已是去中心化世界的公民！';
  }

  String _security() {
    return 'Zero 的安全性基于密码学，而非信任：\n\n'
        '🏰 **协议级安全**\n'
        '  · X3DH + Double Ratchet：Signal 同级\n'
        '  · P-256 椭圆曲线：NSA Suite B 标准\n'
        '  · ChaCha20-Poly1305 AEAD：抗侧信道\n'
        '  · 洋葱路由：3 跳加密封装\n\n'
        '🔑 **密钥安全**\n'
        '  · 私钥永不离开设备\n'
        '  · 每次会话使用独立密钥\n'
        '  · 支持硬件安全模块集成\n\n'
        '🛡️ **已知防御**\n'
        '  · 中间人攻击 → ECDSA 签名验证\n'
        '  · 重放攻击 → Ratchet Epoch 机制\n'
        '  · Sybil 攻击 → 四层费率防御\n'
        '  · 密钥泄露 → 后妥协安全自动恢复\n\n'
        '数学，是 Zero 唯一信任的权威。';
  }

  String _channels() {
    return 'Zero **频道系统** 支持一对多广播：\n\n'
        '📢 频道特性：\n'
        '  · 创建频道 → 邀请订阅者 → 发布消息\n'
        '  · 支持文字/图片/文件/语音广播\n'
        '  · 订阅者实时接收推送\n'
        '  · 频道主可置顶重要消息\n\n'
        '🔐 安全：\n'
        '  · 频道消息同样 E2EE（频道密钥共享给订阅者）\n'
        '  · 取消订阅 → 频道密钥立即轮换\n'
        '  · 防止已退订者解密历史消息\n\n'
        '💡 使用场景：项目更新、社区公告、DAO 治理通知。\n'
        '在聊天室 Tab → "+" → "New Channel" 创建。';
  }

  String _zeroMarket() {
    return '**ZeroMarket** —— 去中心化 P2P 自由集市 🛒\n\n'
        '核心特性：\n'
        '  · 零平台费：真 P2P，无中间商抽成\n'
        '  · ZERO 定价：商品以 ZERO 标价\n'
        '  · ZERO Escrow：买家付款锁定，确认收货后释放\n'
        '  · 声誉系统：交易评价建立链上信誉\n'
        '  · Zero ID 身份：一个账号全平台通用\n\n'
        '交易流程：\n'
        '  1️⃣ 卖家发布商品（图+描述+ZERO价格）\n'
        '  2️⃣ 买家下单 → ZERO 锁定在 Escrow\n'
        '  3️⃣ 卖家发货 → 更新物流 → 买家确认\n'
        '  4️⃣ Escrow 自动释放 → 双方互评\n\n'
        '在钱包 Tab → ZeroMarket 入口浏览。\n'
        'ZERO 经济飞轮的关键一环。';
  }

  String _nodeMining() {
    return '运行 Zero 节点赚取 ZERO 收益：\n\n'
        '📡 中继节点（Relay Node）\n'
        '  · 质押：1,000-10,000 ZERO\n'
        '  · 收益：按转发消息量计费\n'
        '  · 年化 ROI：29%-53%\n'
        '  · 要求：24/7 在线 + 稳定带宽\n\n'
        '💾 存储节点（Storage Node）\n'
        '  · 质押：5,000-50,000 ZERO\n'
        '  · 收益：按存储容量计费 (~0.1 ZERO/GB/月)\n'
        '  · 年化 ROI：1%-10%\n'
        '  · 要求：大容量存储 + 高可用\n\n'
        '如何开始：\n'
        '  网络仪表盘 → 节点状态 → 下载 ZeroNode CLI\n'
        '  配置 → 质押 ZERO → 自动接入洋葱网络\n\n'
        '你的闲置带宽，变成 ZERO 收益。';
  }

  String _nodes() {
    return 'Zero 网络由四类节点组成：\n\n'
        '📡 **中继节点**：转发加密消息，核心网络层\n'
        '  · 当前在线：~10 个全球种子节点\n'
        '  · 分布于：新加坡/东京/法兰克福/旧金山等\n\n'
        '💾 **存储节点**：存储 DASN 文件分片\n'
        '  · 256KB 分片 → 3+ 副本\n'
        '  · 可用性 ≥ 99%\n\n'
        '🔗 **验证节点**：区块打包与验证\n'
        '  · 未来 ZeroChain 测试网上线后启用\n\n'
        '🧭 **DHT 节点**：路由查询、节点发现\n'
        '  · Kademlia DHT 协议\n'
        '  · 轻量级，手机也可运行\n\n'
        '在网络仪表盘 → 右上角图层图标查看洋葱路由控制台。';
  }

  String _onionRouting() {
    return '**洋葱路由（Onion Routing）** —— Zero 隐私通信的灵魂 🧅\n\n'
        '工作原理：\n'
        '  你的消息被层层加密（像洋葱一样），通过 3 个中继节点转发：\n\n'
        '  YOU → 🔐Alpha(SG) → 🔐Delta(SF) → 🔐Gamma(FRA) → DEST\n'
        '       解密第一层     解密第二层      解密第三层     “原来在叫我”\n'
        '       “转给Delta”    “转给Gamma”     “送达目的地”\n\n'
        '每层使用独立的 ChaCha20-Poly1305 AEAD 加密：\n'
        '  · 入口节点知道：你来访 + 下一跳地址\n'
        '  · 中继节点知道：上一跳 + 下一跳\n'
        '  · 出口节点知道：消息内容 + 目的地\n'
        '  · 没有任何节点同时知道：你是谁 + 你在和谁通信\n\n'
        '这是 Zero 区别于 Telegram/Signal 的核心隐私能力。\n'
        '在网络仪表盘体验洋葱路由可视化。';
  }

  String _games() {
    return '🎮 **零界休闲站** —— 加密世界的轻松一刻\n\n'
        '当前已上线：\n'
        '  🧩 零界拼图 · 灵感来自 $ZERE 爆发—数字解压\n'
        '  🎲 区块链大富翁 · Web3 版 Monopoly\n'
        '  🪨✂️📄 猜拳博弈 · P2P 链上对决\n'
        '  🎰 老虎机 · 试试手气\n'
        '  🎯 飞镖 · 瞄准你的目标\n'
        '  🔢 数字滑动 · 2048 加密版\n'
        '\n'
        '所有游戏玩家数据 E2EE 加密存储。\n'
        '在设置或 Home 底部找到娱乐入口。';
  }

  String _roadmap() {
    return '**Zero 路线图** —— 五阶段走向完全去中心化：\n\n'
        '**Phase 1 - ✅ 种子期（已完成）**\n'
        '  · 核心加密协议 + BIP44 钱包 + E2EE 聊天\n'
        '  · ZeroFeed 信息流 + ZeroDNS 域名\n'
        '  · DASN 去中心化存储 + 洋葱路由\n\n'
        '**Phase 2 - 🔄 萌芽期（进行中）**\n'
        '  · ZeroPay /pay 指令系统\n'
        '  · ZeroMarket P2P 自由集市\n'
        '  · 频道广播系统 + AI 助手升级\n\n'
        '**Phase 3 - 🗓️ 生长期**\n'
        '  · ZeroChain 测试网上线\n'
        '  · ZERO 代币 TGE + 空投\n'
        '  · 开发者 SDK + API\n\n'
        '**Phase 4 - 🚀 爆发期**\n'
        '  · 用户增长运营\n'
        '  · 更多公链接入\n'
        '  · CEX 上市\n\n'
        '**Phase 5 - 🌍 愿景期**\n'
        '  · 成为 Web3 通信基础设施\n'
        '  · 零界 DAO 完全自主治理\n'
        '  · 10 亿用户目标';
  }

  String _comparison() {
    return 'Zero 与其他通信工具的对比：\n\n'
        '| 特性 | Zero | Signal | Telegram | WhatsApp |\n'
        '|------|:---:|:-----:|:------:|:------:|\n'
        '| E2EE | ✅ | ✅ | ❌(非默认) | ✅ |\n'
        '| 匿名身份 | ✅ | ❌ | ❌ | ❌ |\n'
        '| 洋葱路由 | ✅ | ❌ | ❌ | ❌ |\n'
        '| 多链钱包 | ✅ | ❌ | ❌(TON) | ❌ |\n'
        '| 去中心化存储 | ✅ | ❌ | ❌ | ❌ |\n'
        '| 无手机号 | ✅ | ❌ | ❌ | ❌ |\n'
        '| 域名系统 | ✅ | ❌ | ✅ | ❌ |\n'
        '| P2P 集市 | ✅ | ❌ | ❌ | ❌ |\n'
        '| 开放协议 | ✅ | ✅ | ❌ | ❌ |\n\n'
        'Zero = Signal 的安全性 + Telegram 的功能 + Bitcoin 的经济模型';
  }

  String _thanks() {
    final msgs = [
      '😊 不客气！很高兴能帮到你。Zero 的世界还有很多等待探索，随时回来问我。',
      '🤝 能为零界公民服务是我的荣幸。有问题随时找我！',
      '💚 你的满意是我存在的意义。零界因你而更好。',
    ];
    return msgs[_random.nextInt(msgs.length)];
  }

  String _fallback() {
    final msgs = [
      '我还在学习中，这个问题超出了我当前的知识范围 😅\n\n'
      '你可以尝试问我：\n'
      '  🔐 "加密是如何工作的？"\n'
      '  💰 "支持哪些钱包？"\n'
      '  🧅 "什么是洋葱路由？"\n'
      '  🌐 "如何注册 .zero 域名？"\n'
      '  📦 "DASN 怎么上传文件？"\n'
      '  💸 "ZERO 经济模型是什么？"\n'
      '  🛒 "ZeroMarket 怎么用？"',
    ];
    return msgs[_random.nextInt(msgs.length)];
  }
}