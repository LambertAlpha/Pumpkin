# Pumpkin 智能合约部署报告

## 🎉 部署成功！

**部署时间**: 2025年8月19日  
**网络**: Sui Testnet  
**交易哈希**: `F2sSTWeFCQBWWryPkfczWDydxncJyVY2etruVhS582Wj`  
**Gas费用**: 65.077880 SUI (约 $0.06 USD)

---

## 📦 核心合约地址

### Package ID
```
0x18bfb42293c04e5037627d858303d03975082b6a9040569d4b8e9b0a509abe6f
```

### 共享对象 (Shared Objects)

#### 1. StakingVault - 质押金库
```
ID: 0x274431c453435415f87281c547ddf1a21ea0bfe1bc7db37f79da06741999a84f
Type: pumpkin::mint::StakingVault
```
用于存放所有用户质押的 SUI

#### 2. Treasury - 资金管理
```
ID: 0x1bb37fad7b8685e4d7100e9ba00b7019563a276fe3586ddb56d0ec54d5bb3f53
Type: pumpkin::treasury::Treasury
```
管理项目资金和奖励池（70%/30% 分配）

#### 3. VerifierCap - 验证者权限
```
ID: 0xe9dcacd8931b13f17ff6d835611db35b2a3fc4e38c6c63dea871d43d11a15cb5
Type: pumpkin::claim::VerifierCap
```
用于验证后端服务签名的权限对象

### 管理员对象 (Admin Objects)

#### TreasuryAdminCap - 资金管理权限
```
ID: 0x0b8be31a348272df303e3693c25d0d802e0f4420a74513385c63111c52ad04d6
Owner: 0x2783bec4e12c4649d77da1da31cd65500786ea636a1fb8b7950c5b8a4fffe6b1
Type: pumpkin::treasury::TreasuryAdminCap
```

#### UpgradeCap - 合约升级权限
```
ID: 0xfb45e770f5d1915e6de3bb6c5f1d316cc0d6b0baa4a1c7dc5ae35bc26d2b8d1e
Owner: 0x2783bec4e12c4649d77da1da31cd65500786ea636a1fb8b7950c5b8a4fffe6b1
Type: sui::package::UpgradeCap
```

---

## 🔧 前端集成配置

### 环境变量配置
```typescript
// .env.local
NEXT_PUBLIC_SUI_NETWORK=testnet
NEXT_PUBLIC_PACKAGE_ID=0x18bfb42293c04e5037627d858303d03975082b6a9040569d4b8e9b0a509abe6f
NEXT_PUBLIC_STAKING_VAULT_ID=0x274431c453435415f87281c547ddf1a21ea0bfe1bc7db37f79da06741999a84f
NEXT_PUBLIC_TREASURY_ID=0x1bb37fad7b8685e4d7100e9ba00b7019563a276fe3586ddb56d0ec54d5bb3f53
NEXT_PUBLIC_VERIFIER_CAP_ID=0xe9dcacd8931b13f17ff6d835611db35b2a3fc4e38c6c63dea871d43d11a15cb5
```

### 合约调用示例

#### 1. 质押SUI并铸造Pumpkin NFT
```typescript
const tx = new TransactionBlock();
tx.moveCall({
  target: `${PACKAGE_ID}::mint::stake_and_mint`,
  arguments: [
    tx.object(suiCoinId),           // 1 SUI coin object
    tx.pure("我的小南瓜"),           // 宠物名称
    tx.object(STAKING_VAULT_ID),    // 质押金库
  ],
});
```

#### 2. 领取升级奖励
```typescript
const tx = new TransactionBlock();
tx.moveCall({
  target: `${PACKAGE_ID}::claim::claim_rewards_entry`,
  arguments: [
    tx.object(pumpkinNftId),        // Pumpkin NFT object
    tx.object(stakeRecordId),       // 质押记录 object
    tx.object(STAKING_VAULT_ID),    // 质押金库
    tx.pure(certificate.owner),     // 证书数据
    tx.pure(certificate.pumpkin_id),
    tx.pure(certificate.target_level),
    tx.pure(certificate.valid_until),
    tx.pure(certificate.signature),
    tx.object(VERIFIER_CAP_ID),     // 验证者权限
  ],
});
```

---

## 🔧 后端集成配置

### 证书签名配置
后端需要生成符合以下格式的升级证书：

```javascript
// 证书数据结构
const certificate = {
  owner: "0x...",           // 用户钱包地址
  pumpkin_id: "0x...",      // NFT object ID
  target_level: 2,          // 目标等级
  valid_until: timestamp,   // 有效期 (Unix timestamp)
  signature: "0x..."        // ECDSA签名
};

// 签名消息构造 (按顺序拼接)
const message = concat([
  addressToBytes(owner),
  addressToBytes(pumpkin_id), 
  u64ToBytes(target_level),
  u64ToBytes(valid_until)
]);

// 使用 Keccak256 + ECDSA-K1 签名
const messageHash = keccak256(message);
const signature = sign(messageHash, privateKey);
```

### 当前验证者公钥
```
0x048b6532f48e527436...（需要更新为实际的后端公钥）
```

**⚠️ 重要**: 需要调用 `update_verifier_key` 函数更新为后端服务的实际公钥。

---

## 🧪 测试指南

### 1. 基础功能测试

#### 测试质押功能
```bash
# 使用 Sui CLI 测试质押
sui client call \
  --package 0x18bfb42293c04e5037627d858303d03975082b6a9040569d4b8e9b0a509abe6f \
  --module mint \
  --function stake_and_mint \
  --args <SUI_COIN_ID> "测试南瓜" 0x274431c453435415f87281c547ddf1a21ea0bfe1bc7db37f79da06741999a84f \
  --gas-budget 10000000
```

#### 查看金库状态
```bash
sui client object 0x274431c453435415f87281c547ddf1a21ea0bfe1bc7db37f79da06741999a84f
```

### 2. 事件监听

监听以下关键事件：
- `StakeAndMint`: 新用户质押事件
- `PumpkinCreated`: NFT创建事件  
- `RewardsClaimed`: 奖励领取事件
- `SuiConfiscated`: 宠物凋零事件

---

## 📊 监控指标

### 关键指标监控

1. **总质押金额**
   ```bash
   # 查看金库总质押
   sui client call --package <PACKAGE_ID> --module mint --function vault_total_staked --args <VAULT_ID>
   ```

2. **资金分配状态**
   ```bash
   # 查看资金库状态
   sui client call --package <PACKAGE_ID> --module treasury --function get_treasury_stats --args <TREASURY_ID>
   ```

3. **活跃用户统计**
   - 监控 `StakeAndMint` 事件频率
   - 统计每日新增质押用户
   - 跟踪升级成功率

---

## 🔄 下一步行动

### 立即执行
1. **前端团队**: 使用上述配置开始集成测试
2. **后端团队**: 实现证书签名逻辑，更新验证者公钥
3. **测试团队**: 执行基础功能测试流程

### 短期优化
1. 更新后端验证者公钥
2. 完善事件监听和状态同步
3. 实现完整的前后端交互流程

### 中期计划
1. 进行全面的集成测试
2. 性能优化和安全审计
3. 准备主网部署

---

## 📞 技术支持

如遇到集成问题，请提供以下信息：
- 交易哈希
- 错误信息
- 使用的对象 ID
- 网络环境 (testnet)

**合约验证链接**: [Sui Explorer](https://testnet.suivision.xyz/package/0x18bfb42293c04e5037627d858303d03975082b6a9040569d4b8e9b0a509abe6f)

---

*部署报告生成时间: 2025年8月19日 13:22*  
*合约版本: v1.0*  
*状态: ✅ 部署成功，可用于开发集成*