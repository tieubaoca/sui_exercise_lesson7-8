module game_hero::sea_hero_helper {
    use game_hero::sea_hero::{Self, SeaMonster, VBI_TOKEN};
    use game_hero::hero::Hero;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct HelpMeSlayThisMonster has key {
        id: UID,
        monster: SeaMonster,
        monster_owner: address,
        helper_reward: u64,
    }

    public fun create_help(monster: SeaMonster, helper_reward: u64, helper: address, ctx: &mut TxContext,) {
        // create a helper to help you attack strong monter
    }

    public fun attack(hero: &Hero, wrapper: HelpMeSlayThisMonster, ctx: &mut TxContext,): Coin<VBI_TOKEN> {
        // hero & hero helper will collaborative to attack monter
    }

    public fun return_to_owner(wrapper: HelpMeSlayThisMonster) {
        // after attack success, hero_helper will return to owner
    }

    public fun owner_reward(wrapper: &HelpMeSlayThisMonster): u64 {
        // the amount will reward for hero helper
    }
}
