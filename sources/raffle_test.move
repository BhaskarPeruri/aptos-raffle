module raffle_addr::raffle_test {

    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    #[test_only]
    use aptos_framework::coin;
    #[test_only]
    use aptos_framework::coin::MintCapability;

    #[test_only]
    use aptos_std::debug;

    #[test_only]
    use std::signer;
    #[test_only]
    use std::string;
    #[test_only]
    use std::vector;

    #[test_only]
    use raffle_addr::raffle;
    #[test_only]
    use aptos_std::crypto_algebra::enable_cryptography_algebra_natives;
    #[test_only]
    use aptos_framework::randomness;

    #[test_only]
    fun give_coins(mint_cap: &MintCapability<AptosCoin>, to: &signer) {
        let to_addr = signer::address_of(to);
        //if the account doesn't exists at given address, we are creating the account
        if (!account::exists_at(to_addr)) {
            account::create_account_for_test(to_addr);
        };
        coin::register<AptosCoin>(to);

        let coins = coin::mint(raffle::get_ticket_price(), mint_cap);
        //deposting the aptos coin to the user
        coin::deposit(to_addr, coins);

    }

    #[
        test(
            deployer = @raffle_addr,
            fx = @aptos_framework,
            user1 = @0xA001,
            user2 = @0xA002,
            user3 = @0xA003,
            user4 = @0xA004,
            user5 = @0xA005,
            user6 = @0xA006
        )
    ]
    fun test_raffle(
        deployer: signer,
        fx: signer,
        user1: signer,
        user2: signer,
        user3: signer,
        user4: signer,
        user5: signer,
        user6: signer
    ) {
        enable_cryptography_algebra_natives(&fx);
        randomness::initialize_for_testing(&fx);

        //Deploying the raffle smart contract
        account::create_account_for_test(signer::address_of(&deployer));
        raffle::init_module_for_testing(&deployer);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&fx);

        //create fake coins for users participating in raffle and initialize aptos_framework
        give_coins(&mint_cap, &user1);
        give_coins(&mint_cap, &user2);
        give_coins(&mint_cap, &user3);
        give_coins(&mint_cap, &user4);
        give_coins(&mint_cap, &user5);
        give_coins(&mint_cap, &user6);

        let winner =
            test_raffle_with_randomness(&user1, &user2, &user3, &user4, &user5, &user6);

        let players = vector[
            signer::address_of(&user1),
            signer::address_of(&user2),
            signer::address_of(&user3),
            signer::address_of(&user4),
            signer::address_of(&user5),
            signer::address_of(&user6)
        ];

        //assert the winner should got all the money
        let i = 0;
        let num_players = vector::length(&players);
        while (i < num_players) {
            let player = *vector::borrow(&players, i);

            if (player == winner) {
                assert!(
                    coin::balance<AptosCoin>(player)
                        == raffle::get_ticket_price() * num_players,
                    1
                );

            } else {
                assert!(coin::balance<AptosCoin>(player) == 0, 1);
            };
            i = i + 1;

        };
        //cleaning up
        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        coin::destroy_mint_cap<AptosCoin>(mint_cap);

    }

    #[test_only]
    fun test_raffle_with_randomness(
        user1: &signer,
        user2: &signer,
        user3: &signer,
        user4: &signer,
        user5: &signer,
        user6: &signer

    ): address {
        //each user sends a txn to buy their ticket
        raffle::buy_a_ticket(user1);
        raffle::buy_a_ticket(user2);
        raffle::buy_a_ticket(user3);
        raffle::buy_a_ticket(user4);
        raffle::buy_a_ticket(user5);
        raffle::buy_a_ticket(user6);

        let winner_addr = raffle::randomly_pick_winner_internal();

        debug::print(&string::utf8(b"The winner is : "));

        debug::print(&winner_addr);

        winner_addr
    }

    #[test(deployer = @raffle_addr, fx = @aptos_framework, user1 = @0xA001)]
    #[expected_failure(abort_code = 4, location = raffle_addr::raffle)]
    // #[expected_failure(abort_code=4)]
    // #[expected_failure]
    fun test_only_unique_users(
        deployer: signer, fx: signer, user1: signer
    ) {
        enable_cryptography_algebra_natives(&fx);
        randomness::initialize_for_testing(&fx);

        account::create_account_for_test(signer::address_of(&deployer));
        //calling init_module for testing
        raffle::init_module_for_testing(&deployer);

        //minting coins for test
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&fx);

        give_coins(&mint_cap, &user1);
        raffle::buy_a_ticket(&user1);
        raffle::buy_a_ticket(&user1);

        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        coin::destroy_mint_cap<AptosCoin>(mint_cap);

    }

    //test when there is only one single player, that player should be winner

    #[test(deployer = @raffle_addr, fx = @aptos_framework, user1 = @0xA001)]
    fun test_raffle_single_player(
        deployer: signer, fx: signer, user1: signer
    ) {
        enable_cryptography_algebra_natives(&fx);
        randomness::initialize_for_testing(&fx);

        account::create_account_for_test(signer::address_of(&deployer));
        raffle::init_module_for_testing(&deployer);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&fx);

        give_coins(&mint_cap, &user1);
        raffle::buy_a_ticket(&user1);

        let winner_addr = raffle::randomly_pick_winner_internal();

        debug::print(&string::utf8(b"The winner is : "));

        debug::print(&winner_addr);

        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        coin::destroy_mint_cap<AptosCoin>(mint_cap);

    }

    // Test for E_NO_TICKETS error - trying to pick winner when no tickets sold

    #[test(deployer = @raffle_addr, fx = @aptos_framework)]
    #[expected_failure(abort_code = 2, location = raffle_addr::raffle)]
    fun test_pick_when_there_are_players(deployer: signer, fx: signer) {
        enable_cryptography_algebra_natives(&fx);
        randomness::initialize_for_testing(&fx);

        account::create_account_for_test(signer::address_of(&deployer));
        raffle::init_module_for_testing(&deployer);

        raffle::randomly_pick_winner_internal();
    }

    // Test for E_RAFFLE_HAS_CLOSED error - trying to pick winner after raffle closed
    #[test(deployer = @raffle_addr, fx = @aptos_framework, user1 = @0xA001)]
    #[expected_failure(abort_code = 3, location = raffle_addr::raffle)]
    fun test_raffle_already_closed_error(
        deployer: signer, fx: signer, user1: signer
    ) {
        enable_cryptography_algebra_natives(&fx);
        randomness::initialize_for_testing(&fx);

        account::create_account_for_test(signer::address_of(&deployer));
        raffle::init_module_for_testing(&deployer);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&fx);

        give_coins(&mint_cap, &user1);
        raffle::buy_a_ticket(&user1);

        //pick winner, this will close the raffle
        raffle::randomly_pick_winner_internal();

        //try to pick winner again- should fail with E_RAFFLE_HAS_CLOSED
        raffle::randomly_pick_winner_internal();

        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        coin::destroy_mint_cap<AptosCoin>(mint_cap);

    }

    //test the view function get_ticket_price
    #[test]
    fun test_get_ticket_price() {
        let price = raffle::get_ticket_price();
        assert!(price == 10_000, 1);
    }

    //test raffle with two users
    #[test(
        deployer = @raffle_addr, fx = @aptos_framework, user1 = @0xA001, user2 = @0xA002
    )]

    fun test_two_user_raffle(
        deployer: signer,
        fx: signer,
        user1: signer,
        user2: signer
    ) {
        enable_cryptography_algebra_natives(&fx);
        randomness::initialize_for_testing(&fx);

        account::create_account_for_test(signer::address_of(&deployer));
        raffle::init_module_for_testing(&deployer);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&fx);

        give_coins(&mint_cap, &user1);
        give_coins(&mint_cap, &user2);

        let user1Addr = signer::address_of(&user1);
        let user2Addr = signer::address_of(&user2);

        raffle::buy_a_ticket(&user1);
        raffle::buy_a_ticket(&user2);

        let winner = raffle::randomly_pick_winner_internal();

        assert!(winner == user1Addr || winner == user2Addr);

        //winner should have all the money and the loser should have 0
        if (winner == user1Addr) {
            assert!(
                coin::balance<AptosCoin>(user1Addr) == raffle::get_ticket_price() * 2,
                1
            );
            assert!(coin::balance<AptosCoin>(user2Addr) == 0, 1);
        } else {
            assert!(coin::balance<AptosCoin>(user1Addr) == 0, 1);
            assert!(
                coin::balance<AptosCoin>(user2Addr) == raffle::get_ticket_price() * 2,
                1
            );

        };

        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        coin::destroy_mint_cap<AptosCoin>(mint_cap);

    }
}
