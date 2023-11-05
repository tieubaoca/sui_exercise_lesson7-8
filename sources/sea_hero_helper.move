module game_hero::sea_hero_helper {
    use game_hero::sea_hero::{Self, SeaMonster, SEA_HERO};
    use game_hero::hero::Hero;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance;

    struct HelpMeSlayThisMonster has store, key {
        id: UID,
        monster: SeaMonster,
        monster_owner: address,
        helper_reward: u64,
    }

    public fun create_help(monster: SeaMonster, helper_reward: u64, helper: address, ctx: &mut TxContext,) {
        let wrapper = HelpMeSlayThisMonster {
            id: object::new(ctx),
            monster: monster,
            monster_owner: tx_context::sender(ctx),
            helper_reward: helper_reward,
        };
        transfer::public_transfer(wrapper, helper);
    }

    public fun attack(hero: &Hero, wrapper: HelpMeSlayThisMonster, ctx: &mut TxContext,): Coin<SEA_HERO> {
        let HelpMeSlayThisMonster{
            id,
            monster,
            monster_owner,
            helper_reward,
        } = wrapper;
        
        let total_reward = sea_hero::slay(hero, monster);
        let reward = balance::split(&mut total_reward, helper_reward);
        transfer::public_transfer(coin::from_balance<SEA_HERO>(total_reward, ctx), monster_owner);
        object::delete(id);
        coin::from_balance(reward, ctx)
    }

    public fun return_to_owner(wrapper: HelpMeSlayThisMonster) {
        let owner = wrapper.monster_owner;
        transfer::transfer(wrapper, owner);
    }
}
