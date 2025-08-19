module pumpkin::treasury {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use pumpkin::mint::{Self, StakingVault, StakeRecord};

    /// Treasury that holds project funds and reward pool
    public struct Treasury has key {
        id: UID,
        /// 30% of confiscated SUI goes to project treasury
        project_balance: Balance<SUI>,
        /// 70% of confiscated SUI goes to reward pool
        reward_pool_balance: Balance<SUI>,
        /// Total amount confiscated
        total_confiscated: u64,
        /// Total distributed to project
        total_to_project: u64,
        /// Total distributed to reward pool
        total_to_reward_pool: u64,
    }

    /// Admin capability for treasury management
    public struct TreasuryAdminCap has key {
        id: UID,
    }

    /// Event emitted when SUI is confiscated from withered pets
    public struct SuiConfiscated has copy, drop {
        pet_owner: address,
        amount_confiscated: u64,
        to_project: u64,
        to_reward_pool: u64,
        reason: vector<u8>, // "pet_withered"
    }

    /// Event emitted when project funds are withdrawn
    public struct ProjectFundsWithdrawn has copy, drop {
        recipient: address,
        amount: u64,
        remaining_balance: u64,
    }

    /// Event emitted when reward pool funds are used
    public struct RewardPoolUsed has copy, drop {
        recipient: address,
        amount: u64,
        remaining_balance: u64,
        purpose: vector<u8>, // e.g., "pump_token_reward"
    }

    /// Error codes
    const EInsufficientFunds: u64 = 0;
    const EUnauthorized: u64 = 1;
    const EInvalidAmount: u64 = 2;
    const EStakeAlreadyClaimed: u64 = 3;

    /// Distribution percentages (basis points: 10000 = 100%)
    const PROJECT_SHARE_BP: u64 = 3000; // 30%
    const REWARD_POOL_SHARE_BP: u64 = 7000; // 70%
    const BASIS_POINTS_TOTAL: u64 = 10000;

    /// Initialize treasury (called once during deployment)
    fun init(ctx: &mut TxContext) {
        let treasury = Treasury {
            id: object::new(ctx),
            project_balance: balance::zero<SUI>(),
            reward_pool_balance: balance::zero<SUI>(),
            total_confiscated: 0,
            total_to_project: 0,
            total_to_reward_pool: 0,
        };

        let admin_cap = TreasuryAdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(treasury);
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Confiscate SUI from withered pet and distribute according to tokenomics
    public entry fun confiscate_withered_pet_stake(
        stake_record: &mut StakeRecord,
        vault: &mut StakingVault,
        treasury: &mut Treasury,
        ctx: &mut TxContext
    ) {
        // Verify the stake hasn't been claimed yet
        assert!(!mint::is_claimed(stake_record), EStakeAlreadyClaimed);

        let (pet_owner, stake_amount, _pumpkin_id, _) = mint::get_stake_info(stake_record);
        
        // Mark stake as claimed to prevent double spending
        mint::mark_claimed(stake_record);
        
        // Extract SUI from vault
        let confiscated_coin = mint::extract_sui(vault, stake_amount, ctx);
        let confiscated_balance = coin::into_balance(confiscated_coin);
        
        // Calculate distribution amounts
        let to_project = (stake_amount * PROJECT_SHARE_BP) / BASIS_POINTS_TOTAL;
        let to_reward_pool = stake_amount - to_project; // Remainder goes to reward pool
        
        // Split the balance
        let project_portion = balance::split(&mut confiscated_balance, to_project);
        let reward_pool_portion = confiscated_balance; // Remainder
        
        // Add to treasury balances
        balance::join(&mut treasury.project_balance, project_portion);
        balance::join(&mut treasury.reward_pool_balance, reward_pool_portion);
        
        // Update statistics
        treasury.total_confiscated = treasury.total_confiscated + stake_amount;
        treasury.total_to_project = treasury.total_to_project + to_project;
        treasury.total_to_reward_pool = treasury.total_to_reward_pool + to_reward_pool;
        
        // Emit event
        sui::event::emit(SuiConfiscated {
            pet_owner,
            amount_confiscated: stake_amount,
            to_project,
            to_reward_pool,
            reason: b"pet_withered",
        });
    }

    /// Withdraw project funds (admin only)
    public entry fun withdraw_project_funds(
        _admin_cap: &TreasuryAdminCap,
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let available_balance = balance::value(&treasury.project_balance);
        assert!(amount <= available_balance, EInsufficientFunds);
        assert!(amount > 0, EInvalidAmount);
        
        let withdrawal_balance = balance::split(&mut treasury.project_balance, amount);
        let withdrawal_coin = coin::from_balance(withdrawal_balance, ctx);
        
        let remaining_balance = balance::value(&treasury.project_balance);
        
        transfer::public_transfer(withdrawal_coin, recipient);
        
        sui::event::emit(ProjectFundsWithdrawn {
            recipient,
            amount,
            remaining_balance,
        });
    }

    /// Use reward pool funds for token rewards (admin only)
    public entry fun use_reward_pool_funds(
        _admin_cap: &TreasuryAdminCap,
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        purpose: vector<u8>,
        ctx: &mut TxContext
    ) {
        let available_balance = balance::value(&treasury.reward_pool_balance);
        assert!(amount <= available_balance, EInsufficientFunds);
        assert!(amount > 0, EInvalidAmount);
        
        let usage_balance = balance::split(&mut treasury.reward_pool_balance, amount);
        let usage_coin = coin::from_balance(usage_balance, ctx);
        
        let remaining_balance = balance::value(&treasury.reward_pool_balance);
        
        transfer::public_transfer(usage_coin, recipient);
        
        sui::event::emit(RewardPoolUsed {
            recipient,
            amount,
            remaining_balance,
            purpose,
        });
    }

    /// Get treasury statistics
    public fun get_treasury_stats(treasury: &Treasury): (u64, u64, u64, u64, u64) {
        (
            balance::value(&treasury.project_balance),
            balance::value(&treasury.reward_pool_balance),
            treasury.total_confiscated,
            treasury.total_to_project,
            treasury.total_to_reward_pool
        )
    }

    /// Get project balance
    public fun get_project_balance(treasury: &Treasury): u64 {
        balance::value(&treasury.project_balance)
    }

    /// Get reward pool balance
    public fun get_reward_pool_balance(treasury: &Treasury): u64 {
        balance::value(&treasury.reward_pool_balance)
    }

    /// Get total confiscated amount
    public fun get_total_confiscated(treasury: &Treasury): u64 {
        treasury.total_confiscated
    }

    /// Transfer admin capability
    public entry fun transfer_admin_cap(
        admin_cap: TreasuryAdminCap,
        recipient: address,
        _ctx: &mut TxContext
    ) {
        transfer::transfer(admin_cap, recipient);
    }

    /// Note: Batch confiscation should be handled by calling confiscate_withered_pet_stake 
    /// multiple times in a single transaction from the client side, as Move doesn't 
    /// support vectors of mutable references
}