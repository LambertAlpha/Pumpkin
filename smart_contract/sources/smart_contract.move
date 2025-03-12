module smart_contract::smart_contract;

use std::ascii::String as AString;
use std::string::String;
use sui::object::{Self, UID};
use sui::tx_context::{Self, TxContext};
use sui::transfer;
use sui::table::{Self, Table};
use sui::event;

//==============================================================================================
// Constants
//==============================================================================================
//==============================================================================================
// Error codes
//==============================================================================================
//// You already have a Profile
//==============================================================================================
// Structs
//==============================================================================================
public struct Pet has key {
    id: UID,
    name: String,
    owner: address,
    hp: u64,
    level: u64,
}

public struct State has key{
    id: UID,
    pets: Table<address, address>
}
//==============================================================================================
// Event Structs
//==============================================================================================
public struct PetCreated has copy, drop {
    pet: address,
    owner: address,
}
//==============================================================================================
// Init
//==============================================================================================
fun init(ctx: &mut TxContext){
    transfer::share_object(State {
        id: object::new(ctx),
        pets: table::new(ctx),
    });
}
//==============================================================================================
// Entry Functions
//==============================================================================================
public entry fun adopt_pet(
    name: String,
    state: &mut State,
    ctx: &mut TxContext,
) {
    let owner = tx_context::sender(ctx);
    assert!(!table::contains(&state.pets, owner), 0);
    let uid = object::new(ctx);
    let id = object::uid_to_inner(&uid);
    let hp = 100;
    let level = 1;

    let new_pet = Pet {
        id: uid,
        name,
        owner,
        hp,
        level,
    };

    transfer::transfer(new_pet, owner);
    table::add(&mut state.pets, owner, object::id_to_address(&id));
    event::emit(PetCreated {
        pet: object::id_to_address(&id),
        owner,
    });
}
//==============================================================================================
// Getter Functions
//==============================================================================================
//==============================================================================================
// Helper Functions
//==============================================================================================
//package id: 0xbc5f446756f942b12f08d9de8e63c2f2cdfe3268fb02c14f36a3926e0d0d0b8d
//state id: 0x2f991b4f1979a793c81b3a19357425940fdcd825f4fee43ee1c3261aaa5c01f8