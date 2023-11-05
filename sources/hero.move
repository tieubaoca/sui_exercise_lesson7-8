module game_hero::hero {
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    const ERR_NOT_ENOUGH_STRENGTH :u64 = 1;

    const STRENGTH_DENOMINATOR :u64 = 10_000_000;
    const GUARD_DENOMINATOR :u64 = 20_000_000;
    const POTION_POTENCY_DENOMINATOR :u64 = 10_000_000;
    const VAULT :address = @vault;
    const EXP_THRESHOLD :u64 = 1000;

    const STRENGTH_GAIN_BY_LEVEL :u64 = 300;
    const GUARD_GAIN_BY_LEVEL :u64 = 20;
    const HP_GAIN_BY_LEVEL :u64 = 30;

    struct Hero has key, store {
        id: UID,
        hp: u64,
        mana: u64,
        level: u8,
        experience: u64,
        sword: Option<Sword>,
        armor: Option<Armor>,
        game_id: ID,
    }

    struct Sword has key, store {
        id: UID,
        exp: u64,
        magic: u64,
        strength: u64,
        game_id: ID,
    }

    struct Potion has key, store {
        id: UID,
        potency: u64,
        game_id: ID,
    }

    struct Armor has key,store {
        id: UID,
        exp: u64,
        guard: u64,
        game_id: ID,
    }

    struct Monster has store, key {
        id: UID,
        hp: u64,
        strength: u64,
        exp: u64,
        game_id: ID,
    }

    struct GameInfo has store, key {
        id: UID,
        admin: address
    }

    struct GameAdmin has store, key {
        id: UID,
        monster_created: u64,
        potions_created: u64,
        game_id: ID,
    }

    struct MonsterSlainEvent has copy, drop {
        slayer_address: address,
        hero: ID,
        monster: ID,
        game_id: ID,
    }

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let game_info = GameInfo {
            id: object::new(ctx),
            admin: sender,
        };
        let game_admin = GameAdmin{
            id: object::new(ctx),
            monster_created: 0,
            potions_created: 0,
            game_id: object::uid_to_inner(&game_info.id),
        };
        transfer::public_share_object(
            game_info
        );
        transfer::public_transfer(
            game_admin,
            sender
        );
    }

    // --- Gameplay ---
    public entry fun attack(_: &GameInfo, hero: &mut Hero, monster: Monster) {
        let win = if (monster.strength <  hero_guard(hero)) {
            true
        } else if (hero.hp / (monster.strength - hero_guard(hero)) > monster.hp / hero_strength(hero)) {
            true
        } else {
            false
        };
        assert!(win, ERR_NOT_ENOUGH_STRENGTH);
        let dmg_received = monster.hp / hero_strength(hero) * (monster.strength - hero_guard(hero));
        hero.hp = hero.hp - dmg_received;
        hero.experience = hero.experience + monster.exp;
        let sword = option::borrow_mut<Sword>(&mut hero.sword);
        let armor = option::borrow_mut<Armor>(&mut hero.armor);
        sword.exp = sword.exp + monster.hp;
        armor.exp = armor.exp + dmg_received;
        level_up_sword(sword);
        level_up_armor(armor);
        up_level_hero(hero);
        let Monster{
            id,
            hp: _,
            strength: _,
            exp: _,
            game_id: _,
        } = monster;
        object::delete(id);

    }

    public entry fun p2p_play(_: &GameInfo, hero1: &mut Hero, hero2: &mut Hero): bool {
        if (hero_strength(hero1) < hero_guard(hero2) && hero_strength(hero2) < hero_guard(hero1)) {
            return false
        };
        if (hero_strength(hero1) < hero_guard(hero2) && hero_strength(hero2) > hero_guard(hero1)) {
            // hero2 win
            true
        } else if (hero_strength(hero1) > hero_guard(hero2) && hero_strength(hero2) < hero_guard(hero1)) {
            // hero1 win
            false
        } else if (hero1.hp / hero_strength(hero2) > hero2.hp / hero_strength(hero1)) {
            // hero1 win
            false
        } else {
            // hero2 win
            true
        }
    }

    public fun up_level_hero(hero: &mut Hero) {
        if (hero.experience < EXP_THRESHOLD) {
            return
        };
        // calculator strength
        hero.level = hero.level + 1;
        hero.experience = hero.experience - EXP_THRESHOLD;
        hero.hp = hero.hp + HP_GAIN_BY_LEVEL;
    }

    public fun hero_strength(hero: &Hero): u64 {
       if (option::is_some(&hero.sword)) {
            let sword = option::borrow<Sword>(&hero.sword);
            return sword_strength(sword)

        };
        0u64
    }

    public fun hero_guard(hero: &Hero): u64 {
        if (option::is_some(&hero.armor)) {
            let armor = option::borrow<Armor>(&hero.armor);
            return armor.guard
        };
        0u64
    }

    public fun hero_hp(hero: &Hero): u64 {
        hero.hp
    }

    fun level_up_sword(sword: &mut Sword) {
        if (sword.exp < EXP_THRESHOLD) {
            return
        };
        // up power/strength for sword
        sword.strength = sword.strength + STRENGTH_GAIN_BY_LEVEL;
        sword.exp = sword.exp - EXP_THRESHOLD;
    }

    fun level_up_armor(armor: &mut Armor) {
        if (armor.exp < EXP_THRESHOLD) {
            return
        };
        // up guard for armor
        armor.guard = armor.guard + GUARD_GAIN_BY_LEVEL;
        armor.exp = armor.exp - EXP_THRESHOLD;
    }

    public fun sword_strength(sword: &Sword): u64 {
        sword.magic + sword.strength
    }

    public fun heal(hero: &mut Hero, potion: Potion) {
        // use the potion to heal
        hero.hp = hero.hp  + potion.potency;
        let Potion{
            id,
            potency: _,
            game_id: _,
        } = potion;
        object::delete(id);
    }

    public fun equip_sword(hero: &mut Hero, new_sword: Sword): Option<Sword> {
        option::swap_or_fill<Sword>(&mut hero.sword, new_sword)
    }

    // --- Object creation ---
    public fun create_sword(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Sword {
        // Create a sword, streight depends on payment amount
        let sword = Sword{
            id: object::new(ctx),
            magic: 0,
            exp: 0,
            strength: coin::value<SUI>(&payment) / STRENGTH_DENOMINATOR,
            game_id: object::uid_to_inner(&game.id),
        };
        transfer::public_transfer(
            payment,
            VAULT
        );
        sword
    }

    public fun create_armor(
        game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext
    ): Armor {
        // Create a armor, guard depends on payment amount
        let armor = Armor{
            id: object::new(ctx),
            guard: coin::value<SUI>(&payment) / GUARD_DENOMINATOR,
            exp: 0,
            game_id: object::uid_to_inner(&game.id),
        };
        transfer::public_transfer(
            payment,
            VAULT
        );
        armor
    }

    public entry fun acquire_hero(
        game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext
    ) {
        let payment_value = coin::value<SUI>(&payment);
        let split = coin::split<SUI>(&mut payment, payment_value / 2, ctx);
        // call function create_armor
        let armor = create_armor(game, split, ctx);
        // call function create_sword
        let sword = create_sword(game, payment, ctx); 
        // call function create_hero
        let hero = create_hero(game, sword, armor, ctx);
        // transfer hero to sender
        transfer::public_transfer(
            hero,
            tx_context::sender(ctx)
        );
    }

    public fun create_hero(game: &GameInfo, sword: Sword, armor: Armor, ctx: &mut TxContext): Hero {
        // Create a new hero
        Hero {
            id: object::new(ctx),
            hp: 1000,
            mana: 500,
            level: 1,
            experience: 0,
            sword: option::some<Sword>(sword),
            armor: option::some<Armor>(armor),
            game_id: object::uid_to_inner(&game.id),
        }
        
    }

    public entry fun send_potion(game: &GameInfo, payment: Coin<SUI>, player: address, ctx: &mut TxContext) {
        // send potion to hero, so that hero can healing
        let potion = Potion{
            id: object::new(ctx),
            potency: coin::value<SUI>(&payment) / POTION_POTENCY_DENOMINATOR,
            game_id: object::uid_to_inner(&game.id),
        };
        transfer::public_transfer(
            payment,
            VAULT
        );
        transfer::public_transfer(
            potion,
            player
        );
    }

    public entry fun send_monster(game: &GameInfo, admin: &mut GameAdmin, exp: u64, hp: u64, strength: u64, player: address, ctx: &mut TxContext) {
        // send monster to hero to attacks
        let monster = Monster{
            id: object::new(ctx),
            hp: hp,
            strength: strength,
            exp: exp,
            game_id: object::uid_to_inner(&game.id),
        };
        transfer::public_transfer(
            monster,
            player
        );
        admin.monster_created = admin.monster_created + 1;
    }

    public fun strength_denominator():u64 {
        STRENGTH_DENOMINATOR
    }

    public fun guard_denominator():u64 {
        GUARD_DENOMINATOR
    }

    public fun potion_potency_denominator():u64 {
        POTION_POTENCY_DENOMINATOR
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext){
        init(ctx);
    }
}


