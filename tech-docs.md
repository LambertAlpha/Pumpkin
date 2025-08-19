好的，Lambert。
我已经仔细阅读了产品需求文档 (PRD) V1.0 和高保真线框图 V1.1。非常清晰的构想，将专注力与 Web3 激励结合起来，这是一个非常吸引人的方向。
基于这些输入，我为你设计了《Pumpkin 技术方案设计文档》的初稿。这份文档旨在明确技术选型、系统架构和数据契约，为我们接下来的并行开发提供坚实的蓝图。

《Pumpkin 技术方案设计文档》V1.0
文档版本: 1.0
创建日期: 2025年8月19日
负责人: Gemini

1. 技术栈选型 (Tech Stack)
为了实现快速开发、流畅的用户体验和安全的资产管理，我推荐以下技术栈：
前端 (Frontend):
框架: Next.js (React)。提供优秀的开发体验、服务端渲染 (SSR) 能力（有利于 SEO 和首屏加载）以及静态站点生成 (SSG) 功能。
UI 库: Chakra UI 或 Tailwind CSS。两者都能提供高效的响应式布局开发。Chakra UI 组件化程度更高，而 Tailwind CSS 提供了原子化的 CSS 类，更加灵活。建议团队根据偏好选择。
状态管理: Zustand。轻量级、无模板代码，非常适合管理如钱包连接状态、宠物实时数据等全局状态。
Sui 钱包交互: @mysten/dapp-kit。Sui 官方提供的 dApp 工具包，可以轻松实现钱包连接、交易签名等功能。
动画: Lottie-web。根据线框图描述，Pumpkin 的多种状态动画非常适合使用 Lottie 来实现，它能以 JSON 格式提供高质量、轻量级的矢量动画。


后端 (验证者服务 - Verifier Service):
框架: Node.js + Fastify。Fastify 以其高性能和低开销著称，非常适合构建我们这种轻量级的 API 服务。其异步特性也能很好地处理与 Walrus 的交互。
语言: TypeScript。为后端代码提供类型安全，减少运行时错误，并提升代码可维护性。


数据库 (链下):
数据库: Walrus。遵从 PRD 要求。我们将利用其作为去中心化、由用户控制的键值存储，来存放所有高频变化的宠物数据。


智能合约 (On-chain):
区块链: Sui Network。
语言: Sui Move。Sui 的原生智能合约语言，以其所有权模型和安全性为核心优势，非常适合处理 NFT 和质押资产。


2. 系统架构图 (System Architecture)
下图清晰地展示了客户端、Sui 智能合约、Walrus 和验证者服务之间的交互流程和数据流：
code Code
downloadcontent_copyexpand_less
   +------------------+      (1) Connect & Sign Tx      +-------------------+
|                  | -----------------------------> |                   |
|  Client (Web App)|      (2) Read Pet Data          |    Sui Wallet     |
|   (Next.js)      | <============================> |                   |
|                  |      (SUI Stake, Claim)         +-------------------+
+--------+---------+
         |
         | (3) Read/Write Pet Data (with Signature)
         |
+--------v---------+      (6) Read Pet Data for Validation
|                  | <----------------------------------+
|      Walrus      |                                    |
|  (Off-chain DB)  |                                    |
+------------------+                                    |
                                                        |
+--------+---------+      (4) Update PH/EXP             +--------------------+
|  Client (Web App)| -----------------------------> |                    |
|   (Next.js)      |      (5) Request Upgrade Cert    |  Verifier Service  |
|                  | -----------------------------> |    (Node.js)       |
+------------------+      (7) Return Signed Cert      |                    |
                         <-----------------------------+--------------------+
                                                        |
+--------+---------+      (8) Submit Tx with Cert     |
|  Client (Web App)| -----------------------------> |   Sui Smart Contract   |
|   (Next.js)      |                                    |      (Sui Move)        |
+------------------+                                    +--------------------+
 
数据流说明:
用户 Onboarding: 用户在客户端通过 Sui 钱包连接，并发起一笔交易，调用智能合约质押 1 SUI 并铸造 Pumpkin NFT。
日常读取: 客户端可以直接从 Walrus 读取当前用户的宠物数据 (PH, EXP)。
日常写入: 当用户与应用交互时（如 AI 聊天），客户端可以使用钱包签名，直接向 Walrus 写入非关键性数据。
完成专注: 专注计时器结束后，客户端向 验证者服务 发送一个 "focus complete" 请求。
请求升级: 当 EXP 达到 100 时，客户端向 验证者服务 请求一个用于升级的授权凭证 (Certificate)。
数据校验: 验证者服务从 Walrus 读取该用户的宠物数据，以校验其操作的合法性（例如，是否真的 EXP >= 100）。
凭证签发: 验证通过后，验证者服务使用自己的私钥对一个包含用户地址和操作类型的数据结构进行签名，生成授权凭证返回给客户端。
触发链上操作: 客户端拿到凭证后，将其作为参数，调用 Sui 智能合约的升级函数。智能合约会验证凭证的签名，验证通过后，执行解锁 SUI 和记录升级状态的操作。
3. 数据结构设计 (Data Schema)
3.1. Walrus: Pet State Table
我们将创建一个名为 pets 的表/集合。每条记录代表一只 Pumpkin。
权限控制: 利用 Walrus 的原生机制，pets 表的写入权限将配置为仅限记录所有者 (owner)。这意味着任何更新操作（如修改 PH/EXP）都必须附带对应 owner 地址的有效签名，这从根本上保证了用户数据的安全性。
code JSON
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
   // Walrus Table: 'pets'
{
  "nft_id": "0x...",          // String: 对应链上 Pumpkin NFT 的 Object ID
  "owner": "0x...",            // String: 宠物主人的 Sui 钱包地址 (主键/索引)
  "ph": 100,                   // Number: 当前生命值 (0-100)
  "exp": 0,                    // Number: 当前经验值 (0-100)
  "level": 1,                  // Number: 宠物当前等级
  "last_active_timestamp": 1755533400, // Number: 上次活跃的 Unix 时间戳 (秒)，用于计算 PH 自然衰减
  "focus_sessions_today": 0,   // Number: 今日已完成的专注次数
  "last_focus_date": "2025-08-19", // String (YYYY-MM-DD): 上次专注的日期，用于重置每日上限
  "equipped_items": {          // Object: 已装备的装饰品
    "hat": "item_id_123",      // String (Optional): 帽子的 Item ID
    "skin": "item_id_456"      // String (Optional): 皮肤的 Item ID
  }
}
 
3.2. Sui: Pumpkin NFT Metadata
NFT 的链上元数据应保持简洁，只存储低频变化的核心资产信息。
code Rust
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
   // Sui Move Struct (Simplified representation)
struct Pumpkin has key, store {
    id: UID,
    level: u64,
    // The name and image_url can point to a service that dynamically
    // generates the image based on the pet's current state from Walrus.
    name: String,
    image_url: String, // e.g., "https://api.pumpkin.fun/pet/{id}/image"
    // Other standard metadata fields...
}
 
4. 模块与组件拆解 (Module Breakdown)
前端 (Client)
Core Modules:
services/walrus.ts: 封装与 Walrus 的所有读写交互。
services/verifier.ts: 封装与后端验证者服务的所有 API 调用。
hooks/usePet.ts: React Hook，用于获取和管理当前用户的宠物状态。
contexts/WalletProvider.tsx: 使用 @mysten/dapp-kit 提供全局的钱包上下文。


UI Components:
components/layout/Navbar.tsx: 顶部导航栏，包含 Logo 和链接。
components/common/WalletConnector.tsx: 钱包连接器组件。
components/home/PetCanvas.tsx: 负责加载和渲染 Lottie 动画的宠物主展示区。
components/home/StatusBars.tsx: PH 和 EXP 进度条。
components/home/FocusController.tsx: 专注按钮和计时器核心交互区。
components/shop/ShopGrid.tsx: 商品网格。
components/shop/ItemCard.tsx: 单个商品卡片。
components/profile/AssetPanel.tsx: 个人中心的资产管理面板。


后端 (Verifier Service)
routes/pet.ts: 处理与宠物状态相关的路由 (e.g., 完成专注)。
routes/voucher.ts: 处理升级凭证相关的路由。
services/walrusClient.ts: 用于连接和读取 Walrus 数据的服务。
services/signatureService.ts: 负责生成和验证签名的服务。
controllers/focusController.ts: 实现完成专注的核心逻辑（校验、更新 Walrus）。
controllers/upgradeController.ts: 实现校验升级条件并签发凭证的逻辑。
智能合约 (Sui Move)
pumpkin.move: 定义 Pumpkin NFT 对象的结构和核心元数据。
mint.move: 包含公开的 mint 函数，处理质押 1 SUI 和铸造 NFT 的逻辑。
claim.move: 包含核心的 claim_rewards 函数，它需要一个由验证者签发的凭证作为参数，验证通过后解锁用户的 1 SUI。
treasury.move: 管理资金分配，当宠物“凋零”时，被没收的 SUI 将被发送到此合约进行分配。
5. 核心 API 契约定义 (API Contract)
这是验证者服务的核心接口定义。所有 API 都应包含 owner 地址，并在服务端进行签名验证，确保操作的合法性。

基地址: /api/v1
1. 完成一次专注
当用户成功完成一次30分钟的专注后，客户端调用此接口更新宠物状态。
Method: POST
URL: /api/v1/pets/focus-complete
Auth: 请求 Body 中需包含由用户钱包签名的信息，以验证请求来源。
Request Body:
 code JSON
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
    {
  "owner": "0x...", // 用户钱包地址
  "signature": "0x...", // 对 '{"action": "focus-complete", "timestamp": 1755533400}' 的签名
  "timestamp": 1755533400 // 请求时间戳，防重放
}
 
Success Response (200 OK):
 code JSON
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
    {
  "status": "success",
  "message": "Focus session completed successfully.",
  "pet": {
    "ph": 87, // 更新后的 PH
    "exp": 42  // 更新后的 EXP
  }
}
 
Failure Response (400/403/500):
 code JSON
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
    {
  "status": "error",
  "message": "Daily focus limit reached." // 或 "Invalid signature", "Pet not found" 等
}
 
2. 请求升级凭证
当宠物 EXP 达到 100 时，客户端调用此接口获取升级所需的链上操作凭证。
Method: POST
URL: /api/v1/pets/request-upgrade-certificate
Auth: 类似上述接口，需要签名验证。
Request Body:
 code JSON
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
    {
  "owner": "0x...", // 用户钱包地址
  "nft_id": "0x...", // 要升级的 NFT ID
  "signature": "0x...",
  "timestamp": 1755533400
}
 
Success Response (200 OK):
 code JSON
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
    {
  "status": "success",
  "certificate": {
    "owner": "0x...",
    "nft_id": "0x...",
    "target_level": 2,
    "valid_until": 1755534000, // 凭证有效期
    "signature": "0x..." // 这是由【验证者服务】的私钥生成的最终签名
  }
}
 
Failure Response (400 Bad Request):
 code JSON
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
    {
  "status": "error",
  "message": "Upgrade conditions not met. EXP is less than 100."
}
 
3. 获取商店商品列表 (可选 API)
虽然商品列表也可以作为静态 JSON 文件放在前端，但通过 API 获取可以方便未来动态更新。
Method: GET
URL: /api/v1/shop/items
Request Params: (无)
Success Response (200 OK):
 code JSON
downloadcontent_copyexpand_less
IGNORE_WHEN_COPYING_START
IGNORE_WHEN_COPYING_END
    {
  "status": "success",
  "items": [
    {
      "id": "hat_001",
      "name": "Wizard Hat",
      "category": "hat",
      "price": 50, // $PUMP
      "image_url": "..."
    },
    {
      "id": "skin_001",
      "name": "Ghost Skin",
      "category": "skin",
      "price": 150, // $PUMP
      "image_url": "..."
    }
  ]
}
 

三、后续步骤
这份技术方案初稿为我们的开发工作提供了明确的指引。下一步，我建议：
技术方案评审: 按计划组织评审会，让所有开发人员对方案达成共识。
环境搭建: 并行开始搭建前端、后端和智能合约的开发环境。
任务拆分与分配: 基于上述模块拆解，我们可以将任务细化到具体的开发人员。
在设计过程中，我已充分考虑了 PRD 中提到的可扩展性和安全性。如有任何疑问，我们随时可以深入讨论。
期待与团队一起，将 Pumpkin 从概念变为现实！
Best,
Gemini

