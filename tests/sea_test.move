#[test_only]
module game_hero::hero_test {
    use sui::test_scenario::{Self as test, next_tx, Scenario, ctx};
    use sui::test_utils::{assert_eq};
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    use sui::transfer;
    // use sui::clock::{Self};
    use game_hero::hero::{Self, Hero};

    public fun scenario(): Scenario { test::begin(@0x1) }
    #[test]
    fun test_slay_monter() {
        let scenario = scenario();
        let (admin, user) = (@0x1, @0x2);

        next_tx(&mut scenario, admin);
        {
            transfer::public_transfer(coin::mint_for_testing<SUI>(1_000_000_000_000, ctx(&mut scenario)), user);
        };  

        next_tx(&mut scenario, admin);
        {
            hero::init_for_testing(ctx(&mut scenario));
        };
        // - create hero
        next_tx(&mut scenario, user);
        {
            let sui_coin =test::take_from_sender<Coin<SUI>>(&mut scenario);
            let game_info = test::take_shared<hero::GameInfo>(&mut scenario);
            let payment = coin::split<SUI>(&mut sui_coin, 1_000_000_000, ctx(&mut scenario));
            hero::acquire_hero(&game_info, payment, ctx(&mut scenario));
            let hero = test::take_from_sender<Hero>(&mut scenario);

            assert_eq(hero::hero_hp(&hero), 10000);

            test::return_shared(game_info);
            test::return_to_sender(&mut scenario, sui_coin);
            test::return_to_sender(&mut scenario, hero);
        };

        // - create monster
        // - slay

        test::end(scenario);
    }

    #[test]
    fun test_slay_sea_monter() {
        // - create hero
        // - create sea monter
        // - slay
    }

    #[test]
    fun test_hero_helper_slay() {
        // - create hero
        // - create hero 2
        // - create sea monter
        // - create help
        // - slay
    }

    #[test]
    fun test_hero_attack_hero() {
        // - create hero
        // - create hero 2
        // - slay 1 vs 2
        // check who will win
    }
}
