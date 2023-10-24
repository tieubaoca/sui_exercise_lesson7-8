module game_hero::sea_hero {
    use game_hero::hero::{Self, Hero};

    use sui::balance::{Self, Balance, Supply};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct SeaHeroAdmin {
        id: UID,
        supply: Supply<VBI_TOKEN>,
        monsters_created: u64,
        token_supply_max: u64,
        monster_max: u64
    }

    struct SeaMonster has key, store {
        id: UID,
        reward: Balance<VBI_TOKEN>
    }

    struct VBI_TOKEN has drop {}

    const EHERO_NOT_STRONG_ENOUGH: u64 = 0;
    const EINVALID_TOKEN_SUPPLY: u64 = 1;
    const EINVALID_MONSTER_SUPPLY: u64 = 2;

    fun init(ctx: &mut TxContext) {
        // create a game token with the name is VBI_TOKEN
    }

    // --- Gameplay ---
    public fun slay(hero: &Hero, monster: SeaMonster): Balance<VBI_TOKEN> {
        // after attack succeeds, hero will have a reward with VBI_TOKEn
    }

    // --- Object and coin creation ---
    public entry fun create_sea_monster(admin: &mut SeaHeroAdmin, reward_amount: u64, recipient: address, ctx: &mut TxContext) {
    }
}
