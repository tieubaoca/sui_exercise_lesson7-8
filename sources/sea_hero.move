module game_hero::sea_hero {
    use std::option;
    use game_hero::hero::{Self, Hero};

    use sui::balance::{Self, Balance, Supply};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin;
    use sui::url;

    struct SeaHeroAdmin has store, key {
        id: UID,
        supply: Supply<SEA_HERO>,
        monsters_created: u64,
        token_supply_max: u64,
        monster_max: u64
    }

    struct SeaMonster has key, store {
        id: UID,
        attack: u64,
        hp: u64,
        reward: Balance<SEA_HERO>
    }

    struct SEA_HERO has drop {}

    const EHERO_NOT_STRONG_ENOUGH: u64 = 0;
    const EINVALID_TOKEN_SUPPLY: u64 = 1;
    const EINVALID_MONSTER_SUPPLY: u64 = 2;

    fun init(witness: SEA_HERO, ctx: &mut TxContext) {
        // create a game token with the name is SEA_HERO
        let (treasury_cap, metadata) = coin::create_currency<SEA_HERO>(
            witness, 
            9,
            b"SEA HERO Token",
            b"SHT",
            b"Description",
            option::some(url::new_unsafe_from_bytes(b"https://github.com")),
            ctx
        );
        transfer::public_share_object(metadata);
        let supply = coin::treasury_into_supply<SEA_HERO>(treasury_cap);
        let admin = SeaHeroAdmin {
            id: object::new(ctx),
            supply: supply,
            monsters_created: 0,
            token_supply_max: 1_000_000_000_000_000,
            monster_max: 1000000000
        };
        transfer::public_transfer(admin, tx_context::sender(ctx));
    }

    // --- Gameplay ---
    public fun slay(hero: &Hero, monster: SeaMonster): Balance<SEA_HERO> {
        let win = if (monster.hp <  hero::hero_guard(hero)) {
            true
        } else if (hero::hero_hp(hero) / (monster.hp - hero::hero_guard(hero)) > monster.hp / hero::hero_strength(hero)) {
            true
        } else {
            false
        };
        assert!(win, EHERO_NOT_STRONG_ENOUGH);
        let SeaMonster{
            id,
            attack: _,
            hp: _,
            reward
        } = monster;
        
        object::delete(id);
        reward
    }

    // --- Object and coin creation ---
    public entry fun create_sea_monster(admin: &mut SeaHeroAdmin, attack: u64, hp: u64, reward_amount: u64, recipient: address, ctx: &mut TxContext) {
        admin.monsters_created = admin.monsters_created + 1;
        assert!(admin.monsters_created > admin.monster_max, EINVALID_MONSTER_SUPPLY);
        assert!(balance::supply_value<SEA_HERO>(&admin.supply) + reward_amount > admin.token_supply_max, EINVALID_TOKEN_SUPPLY);
        let monster = SeaMonster {
            id: object::new(ctx),
            attack: attack,
            hp: hp,
            reward: balance::increase_supply<SEA_HERO>(&mut admin.supply, reward_amount)
        };
        transfer::public_transfer(monster, recipient);
    }

    public fun monster_detail(monster: SeaMonster): (UID, u64, u64, Balance<SEA_HERO>) {
        let SeaMonster{
            id,
            attack,
            hp,
            reward
        } = monster;
        (
            id,
            attack,
            hp,
            reward
        )
    }

}
