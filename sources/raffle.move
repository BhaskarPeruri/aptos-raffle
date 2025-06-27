module raffle_addr::raffle {

    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::randomness;
    use aptos_framework::coin::Coin;
    use std::signer;
    use std::vector;

    //we declared friend declaration so our tests can call 'init_module'
    friend raffle_addr::raffle_test;

    //Error codes
    //error code when user tries to initiate the drawing but no users bought any tickets
    const E_NO_TICKETS: u64 = 2;
    //error code when the somebody tries to draw an already-closed raffle
    const E_RAFFLE_HAS_CLOSED: u64 = 3;

    const E_UNIQUE_USERS_ONLY: u64 = 4;
    //The minimum price of a raffle ticket, in APT
    const TICKET_PRICE: u64 = 10_000;

    //A list of users who bought raffle tickets allowing the unique addresses only

    struct Raffle has key {
        tickets: vector<address>,
        coins: Coin<AptosCoin>,
        is_closed: bool
    }

    struct UserInfo has key {
        userAddr: address
    }

    fun init_module(deployer: &signer) {
        move_to(
            deployer,
            Raffle {
                tickets: vector::empty(),
                coins: coin::zero(),
                is_closed: false
            }
        );

    }

    #[test_only]
    public(friend) fun init_module_for_testing(deployer: &signer) {
        init_module(deployer);
    }

    #[view]
    public fun get_ticket_price(): u64 {
        TICKET_PRICE
    }

    //Any user can call this to purchase a ticket in the raffle
    public entry fun buy_a_ticket(user: &signer) acquires Raffle {
        assert!(
            !exists<UserInfo>(signer::address_of(user)),
            E_UNIQUE_USERS_ONLY
        );
        move_to<UserInfo>(user, UserInfo { userAddr: signer::address_of(user) });
        //accessing the Raffle struct
        let raffle = borrow_global_mut<Raffle>(@raffle_addr);

        //charge the  price of. a raffle ticket from the user's balance
        let userCoins = coin::withdraw<AptosCoin>(user, TICKET_PRICE);
        //adding userCoins to the raffle treasury
        coin::merge(&mut raffle.coins, userCoins);

        //Issuing the ticket for that user
        vector::push_back(&mut raffle.tickets, signer::address_of(user));
    }

    //Made the below function to private to prevent test and abort attack
    #[randomness]
    entry fun randomly_pick_winner() acquires Raffle {
        randomly_pick_winner_internal();
    }

    public(friend) fun randomly_pick_winner_internal(): address acquires Raffle {
        //accessing the global storage of raffle
        let raffle = borrow_global_mut<Raffle>(@raffle_addr);

        //Only call when raffle is open
        assert!(!raffle.is_closed, E_RAFFLE_HAS_CLOSED);
        //only call when there is atleast one address
        assert!(!vector::is_empty(&raffle.tickets), E_NO_TICKETS);

        //picking a random number
        let winner_indx = randomness::u64_range(0, vector::length(&raffle.tickets));
        let winner_addr = *vector::borrow(&raffle.tickets, winner_indx);

        //finally paying all the coins in the raffle
        let coins = coin::extract_all(&mut raffle.coins);
        coin::deposit<AptosCoin>(winner_addr, coins);
        raffle.is_closed = true;

        winner_addr
    }
}
