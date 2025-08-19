module pumpkin::pumpkin {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};

    /// The Pumpkin NFT struct representing a digital pet
    public struct Pumpkin has key, store {
        id: UID,
        /// Current level of the pumpkin (starts at 1)
        level: u64,
        /// Name of the pumpkin pet
        name: String,
        /// Dynamic image URL that reflects current state
        image_url: String,
        /// Owner address for verification
        owner: address,
    }

    /// Event emitted when a new Pumpkin is created
    public struct PumpkinCreated has copy, drop {
        id: address,
        owner: address,
        level: u64,
        name: String,
    }

    /// Event emitted when a Pumpkin is upgraded
    public struct PumpkinUpgraded has copy, drop {
        id: address,
        owner: address,
        old_level: u64,
        new_level: u64,
    }

    /// Error codes
    const EInvalidLevel: u64 = 0;
    const ENotOwner: u64 = 1;

    /// Create a new Pumpkin NFT
    public fun new_pumpkin(
        name: String,
        owner: address,
        ctx: &mut TxContext
    ): Pumpkin {
        let id = object::new(ctx);
        let pumpkin_id = object::uid_to_address(&id);
        
        let mut image_url = string::utf8(b"https://api.pumpkin.fun/pet/");
        string::append(&mut image_url, string::utf8(object::uid_to_bytes(&id)));
        string::append(&mut image_url, string::utf8(b"/image"));

        let pumpkin = Pumpkin {
            id,
            level: 1,
            name,
            image_url,
            owner,
        };

        sui::event::emit(PumpkinCreated {
            id: pumpkin_id,
            owner,
            level: 1,
            name,
        });

        pumpkin
    }

    /// Upgrade pumpkin to next level (called by claim module)
    public fun upgrade_level(pumpkin: &mut Pumpkin, ctx: &TxContext) {
        assert!(tx_context::sender(ctx) == pumpkin.owner, ENotOwner);
        
        let old_level = pumpkin.level;
        pumpkin.level = pumpkin.level + 1;

        sui::event::emit(PumpkinUpgraded {
            id: object::uid_to_address(&pumpkin.id),
            owner: pumpkin.owner,
            old_level,
            new_level: pumpkin.level,
        });
    }

    /// Get pumpkin level
    public fun level(pumpkin: &Pumpkin): u64 {
        pumpkin.level
    }

    /// Get pumpkin name
    public fun name(pumpkin: &Pumpkin): String {
        pumpkin.name
    }

    /// Get pumpkin image URL
    public fun image_url(pumpkin: &Pumpkin): String {
        pumpkin.image_url
    }

    /// Get pumpkin owner
    public fun owner(pumpkin: &Pumpkin): address {
        pumpkin.owner
    }

    /// Get pumpkin ID
    public fun id(pumpkin: &Pumpkin): address {
        object::uid_to_address(&pumpkin.id)
    }

    /// Transfer pumpkin to new owner
    public entry fun transfer_pumpkin(
        pumpkin: Pumpkin,
        recipient: address,
        _ctx: &mut TxContext
    ) {
        transfer::public_transfer(pumpkin, recipient)
    }
}