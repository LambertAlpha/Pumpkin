#[test_only]
module pumpkin::pumpkin_tests {
    use pumpkin::pumpkin;
    use pumpkin::mint;
    use sui::test_scenario;
    use sui::coin;
    use sui::sui::SUI;
    use std::string;

    #[test]
    fun test_pumpkin_creation() {
        let admin = @0xA;
        let user = @0xB;
        
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        // Test creating a new pumpkin
        test_scenario::next_tx(scenario, user);
        {
            let ctx = test_scenario::ctx(scenario);
            let pumpkin = pumpkin::new_pumpkin(
                string::utf8(b"Test Pumpkin"),
                user,
                ctx
            );
            
            // Verify initial state
            assert!(pumpkin::level(&pumpkin) == 1, 0);
            assert!(pumpkin::name(&pumpkin) == string::utf8(b"Test Pumpkin"), 1);
            assert!(pumpkin::owner(&pumpkin) == user, 2);
            
            // Transfer to user for cleanup
            pumpkin::transfer_pumpkin(pumpkin, user, ctx);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_stake_and_mint_flow() {
        let admin = @0xA;
        let user = @0xB;
        
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        // Initialize the mint module
        test_scenario::next_tx(scenario, admin);
        {
            mint::init_for_testing(test_scenario::ctx(scenario));
        };
        
        // User stakes SUI and mints pumpkin
        test_scenario::next_tx(scenario, user);
        {
            let vault = test_scenario::take_shared<mint::StakingVault>(scenario);
            let payment = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(scenario));
            
            mint::stake_and_mint(
                payment,
                b"My Pumpkin",
                &mut vault,
                test_scenario::ctx(scenario)
            );
            
            test_scenario::return_shared(vault);
        };
        
        // Verify pumpkin and stake record were created
        test_scenario::next_tx(scenario, user);
        {
            // Check if pumpkin NFT exists
            assert!(test_scenario::has_most_recent_for_sender<pumpkin::Pumpkin>(scenario), 3);
            
            // Check if stake record exists
            assert!(test_scenario::has_most_recent_for_sender<mint::StakeRecord>(scenario), 4);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_vault_balance_tracking() {
        let admin = @0xA;
        let user = @0xB;
        
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        // Initialize
        test_scenario::next_tx(scenario, admin);
        {
            mint::init_for_testing(test_scenario::ctx(scenario));
        };
        
        // Check initial vault state
        test_scenario::next_tx(scenario, user);
        {
            let vault = test_scenario::take_shared<mint::StakingVault>(scenario);
            assert!(mint::vault_total_staked(&vault) == 0, 5);
            assert!(mint::vault_balance_value(&vault) == 0, 6);
            test_scenario::return_shared(vault);
        };
        
        // Stake SUI
        test_scenario::next_tx(scenario, user);
        {
            let vault = test_scenario::take_shared<mint::StakingVault>(scenario);
            let payment = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(scenario));
            
            mint::stake_and_mint(
                payment,
                b"Test Pumpkin",
                &mut vault,
                test_scenario::ctx(scenario)
            );
            
            // Verify vault balance increased
            assert!(mint::vault_total_staked(&vault) == 1_000_000_000, 7);
            assert!(mint::vault_balance_value(&vault) == 1_000_000_000, 8);
            
            test_scenario::return_shared(vault);
        };
        
        test_scenario::end(scenario_val);
    }
}
