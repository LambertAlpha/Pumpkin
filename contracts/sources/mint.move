module pumpkin::mint {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use std::string;
    use pumpkin::pumpkin::{Self, Pumpkin};

    /// Staking vault that holds all staked SUI
    public struct StakingVault has key {
        id: UID,
        /// Total SUI staked in the vault
        balance: Balance<SUI>,
        /// Mapping from owner address to staked amount (for tracking)
        total_staked: u64,
    }

    /// Staking record for individual users
    public struct StakeRecord has key, store {
        id: UID,
        /// Address of the staker
        owner: address,
        /// Amount staked (should be 1 SUI = 1_000_000_000 MIST)
        amount: u64,
        /// Associated Pumpkin NFT ID
        pumpkin_id: address,
        /// Whether the stake has been claimed
        is_claimed: bool,
    }

    /// Event emitted when SUI is staked and Pumpkin is minted
    public struct StakeAndMint has copy, drop {
        staker: address,
        amount: u64,
        pumpkin_id: address,
        stake_record_id: address,
    }

    /// Error codes
    const EInvalidStakeAmount: u64 = 0;
    const EInsufficientFunds: u64 = 1;
    const EStakeNotFound: u64 = 2;
    const EAlreadyClaimed: u64 = 3;

    /// Required stake amount: 1 SUI = 1_000_000_000 MIST
    const REQUIRED_STAKE_AMOUNT: u64 = 1_000_000_000;

    /// Initialize the staking vault (called once during deployment)
    fun init(ctx: &mut TxContext) {
        let vault = StakingVault {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            total_staked: 0,
        };
        transfer::share_object(vault);
    }

    /// Public function to stake 1 SUI and mint a Pumpkin NFT
    public entry fun stake_and_mint(
        payment: Coin<SUI>,
        pumpkin_name: vector<u8>,
        vault: &mut StakingVault,
        ctx: &mut TxContext
    ) {
        let staker = tx_context::sender(ctx);
        let amount = coin::value(&payment);
        
        // Verify the exact stake amount
        assert!(amount == REQUIRED_STAKE_AMOUNT, EInvalidStakeAmount);

        // Create new Pumpkin NFT
        let pumpkin = pumpkin::new_pumpkin(
            string::utf8(pumpkin_name),
            staker,
            ctx
        );
        let pumpkin_id = pumpkin::id(&pumpkin);

        // Create stake record
        let stake_record_id = object::new(ctx);
        let stake_record_addr = object::uid_to_address(&stake_record_id);
        
        let stake_record = StakeRecord {
            id: stake_record_id,
            owner: staker,
            amount,
            pumpkin_id,
            is_claimed: false,
        };

        // Add payment to vault
        let payment_balance = coin::into_balance(payment);
        balance::join(&mut vault.balance, payment_balance);
        vault.total_staked = vault.total_staked + amount;

        // Emit event
        sui::event::emit(StakeAndMint {
            staker,
            amount,
            pumpkin_id,
            stake_record_id: stake_record_addr,
        });

        // Transfer NFT to user and store stake record
        transfer::public_transfer(pumpkin, staker);
        transfer::public_transfer(stake_record, staker);
    }

    /// Get stake record information
    public fun get_stake_info(stake_record: &StakeRecord): (address, u64, address, bool) {
        (
            stake_record.owner,
            stake_record.amount,
            stake_record.pumpkin_id,
            stake_record.is_claimed
        )
    }

    /// Mark stake as claimed (called by claim module)
    public fun mark_claimed(stake_record: &mut StakeRecord) {
        stake_record.is_claimed = true;
    }

    /// Check if stake is claimed
    public fun is_claimed(stake_record: &StakeRecord): bool {
        stake_record.is_claimed
    }

    /// Get vault total staked amount (for monitoring)
    public fun vault_total_staked(vault: &StakingVault): u64 {
        vault.total_staked
    }

    /// Get vault balance value
    public fun vault_balance_value(vault: &StakingVault): u64 {
        balance::value(&vault.balance)
    }

    /// Extract SUI from vault (only callable by claim module)
    public fun extract_sui(
        vault: &mut StakingVault,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        assert!(balance::value(&vault.balance) >= amount, EInsufficientFunds);
        
        let extracted_balance = balance::split(&mut vault.balance, amount);
        vault.total_staked = vault.total_staked - amount;
        
        coin::from_balance(extracted_balance, ctx)
    }

    /// Test-only initialization function
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}