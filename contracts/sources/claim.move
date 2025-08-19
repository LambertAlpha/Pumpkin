module pumpkin::claim {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::ecdsa_k1;
    use sui::hash;
    use std::vector;
    use pumpkin::pumpkin::{Self, Pumpkin};
    use pumpkin::mint::{Self, StakingVault, StakeRecord};

    /// Verifier authority that validates claims
    public struct VerifierCap has key {
        id: UID,
        /// Public key of the backend verifier service
        public_key: vector<u8>,
    }

    /// Upgrade certificate issued by the backend verifier
    public struct UpgradeCertificate has drop {
        /// Address of the pumpkin owner
        owner: address,
        /// NFT ID to be upgraded
        pumpkin_id: address,
        /// Target level after upgrade
        target_level: u64,
        /// Certificate expiration timestamp
        valid_until: u64,
        /// Backend verifier signature
        signature: vector<u8>,
    }

    /// Event emitted when rewards are claimed
    public struct RewardsClaimed has copy, drop {
        claimer: address,
        pumpkin_id: address,
        amount_claimed: u64,
        new_level: u64,
    }

    /// Event emitted when verifier is updated
    public struct VerifierUpdated has copy, drop {
        old_public_key: vector<u8>,
        new_public_key: vector<u8>,
    }

    /// Error codes
    const EInvalidSignature: u64 = 0;
    const ECertificateExpired: u64 = 1;
    const EUnauthorized: u64 = 2;
    const EInvalidOwner: u64 = 3;
    const EAlreadyClaimed: u64 = 4;
    const EInvalidLevel: u64 = 5;
    const EPumpkinMismatch: u64 = 6;

    /// Initialize the verifier authority (called once during deployment)
    fun init(ctx: &mut TxContext) {
        // TODO: Replace with actual verifier public key
        let initial_public_key = vector[
            0x04, 0x8b, 0x65, 0x32, 0xf4, 0x8e, 0x52, 0x74, 0x36, 0x17, 0xc4, 0xd7, 0x2c, 0x35, 0x45, 0x8b,
            0x9f, 0x61, 0x2d, 0x65, 0x8f, 0x7c, 0x3e, 0x4f, 0x1a, 0x2b, 0x8c, 0x9d, 0x3f, 0x6e, 0x7a, 0x8b,
            0x1c, 0x5d, 0x9e, 0x2f, 0x6a, 0x8b, 0x4c, 0x7d, 0x9e, 0x3f, 0x8a, 0x5c, 0x6d, 0x9e, 0x2f, 0x7a,
            0x8b, 0x4c, 0x5d, 0x6e, 0x9f, 0x2a, 0x7b, 0x8c, 0x3d, 0x6e, 0x9f, 0x4a, 0x7b, 0x8c, 0x5d, 0x6e
        ];
        
        let verifier_cap = VerifierCap {
            id: object::new(ctx),
            public_key: initial_public_key,
        };
        
        transfer::share_object(verifier_cap);
    }

    /// Core function to claim rewards with verifier authorization
    public entry fun claim_rewards(
        pumpkin: &mut Pumpkin,
        stake_record: &mut StakeRecord,
        vault: &mut StakingVault,
        certificate: UpgradeCertificate,
        verifier_cap: &VerifierCap,
        ctx: &mut TxContext
    ) {
        let claimer = tx_context::sender(ctx);
        let current_timestamp = tx_context::epoch(ctx); // Using epoch as timestamp proxy
        
        // 1. Verify certificate hasn't expired
        assert!(current_timestamp <= certificate.valid_until, ECertificateExpired);
        
        // 2. Verify the claimer is the rightful owner
        assert!(claimer == certificate.owner, EInvalidOwner);
        assert!(claimer == pumpkin::owner(pumpkin), EUnauthorized);
        
        // 3. Verify pumpkin ID matches
        let pumpkin_id = pumpkin::id(pumpkin);
        assert!(pumpkin_id == certificate.pumpkin_id, EPumpkinMismatch);
        
        // 4. Verify stake hasn't been claimed already
        assert!(!mint::is_claimed(stake_record), EAlreadyClaimed);
        
        // 5. Verify the stake record matches this pumpkin
        let (stake_owner, stake_amount, stake_pumpkin_id, _) = mint::get_stake_info(stake_record);
        assert!(stake_owner == claimer, EUnauthorized);
        assert!(stake_pumpkin_id == pumpkin_id, EPumpkinMismatch);
        
        // 6. Verify certificate signature
        verify_certificate_signature(&certificate, verifier_cap);
        
        // 7. Upgrade the pumpkin level
        let old_level = pumpkin::level(pumpkin);
        assert!(certificate.target_level > old_level, EInvalidLevel);
        pumpkin::upgrade_level(pumpkin, ctx);
        
        // 8. Mark stake as claimed and extract SUI
        mint::mark_claimed(stake_record);
        let claimed_coin = mint::extract_sui(vault, stake_amount, ctx);
        
        // 9. Transfer SUI back to claimer
        transfer::public_transfer(claimed_coin, claimer);
        
        // 10. Emit event
        sui::event::emit(RewardsClaimed {
            claimer,
            pumpkin_id,
            amount_claimed: stake_amount,
            new_level: certificate.target_level,
        });
    }

    /// Verify the certificate signature against verifier's public key
    fun verify_certificate_signature(
        certificate: &UpgradeCertificate,
        verifier_cap: &VerifierCap
    ) {
        // Construct the message that was signed by the verifier
        let message = construct_certificate_message(certificate);
        let message_hash = hash::keccak256(&message);
        
        // Verify the signature
        let is_valid = ecdsa_k1::secp256k1_verify(
            &certificate.signature,
            &verifier_cap.public_key,
            &message_hash,
            0 // hash_type: 0 for keccak256
        );
        
        assert!(is_valid, EInvalidSignature);
    }

    /// Construct the message that should be signed by the verifier
    fun construct_certificate_message(certificate: &UpgradeCertificate): vector<u8> {
        let mut message = vector::empty<u8>();
        
        // Add owner address
        let owner_bytes = sui::address::to_bytes(certificate.owner);
        vector::append(&mut message, owner_bytes);
        
        // Add pumpkin ID
        let pumpkin_id_bytes = sui::address::to_bytes(certificate.pumpkin_id);
        vector::append(&mut message, pumpkin_id_bytes);
        
        // Add target level as bytes
        let level_bytes = sui::bcs::to_bytes(&certificate.target_level);
        vector::append(&mut message, level_bytes);
        
        // Add valid_until timestamp
        let timestamp_bytes = sui::bcs::to_bytes(&certificate.valid_until);
        vector::append(&mut message, timestamp_bytes);
        
        message
    }

    /// Update verifier public key (admin only)
    public entry fun update_verifier_key(
        verifier_cap: &mut VerifierCap,
        new_public_key: vector<u8>,
        _ctx: &mut TxContext
    ) {
        let old_key = verifier_cap.public_key;
        verifier_cap.public_key = new_public_key;
        
        sui::event::emit(VerifierUpdated {
            old_public_key: old_key,
            new_public_key,
        });
    }

    /// Get current verifier public key
    public fun get_verifier_public_key(verifier_cap: &VerifierCap): vector<u8> {
        verifier_cap.public_key
    }

    /// Helper function to create certificate (for backend integration reference)
    public fun create_certificate(
        owner: address,
        pumpkin_id: address,
        target_level: u64,
        valid_until: u64,
        signature: vector<u8>
    ): UpgradeCertificate {
        UpgradeCertificate {
            owner,
            pumpkin_id,
            target_level,
            valid_until,
            signature,
        }
    }

    /// Extract certificate data (for verification purposes)
    public fun extract_certificate_data(certificate: &UpgradeCertificate): (address, address, u64, u64, vector<u8>) {
        (
            certificate.owner,
            certificate.pumpkin_id,
            certificate.target_level,
            certificate.valid_until,
            certificate.signature
        )
    }
}