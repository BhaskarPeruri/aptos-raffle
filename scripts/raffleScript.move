script {
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_framework::coin;
    use raffle_addr::raffle;

    use std::signer;

    fun main(attacker: &signer) {
        let attacker_addr = signer::address_of(attacker);
        let old_balance = coin::balance<AptosCoin>(attacker_addr);

        let new_balance = coin::balance<AptosCoin>(attacker_addr);

        //the below call will fail because the randomly_pick_winner() is private entry function.

        // raffle::randomly_pick_winner();

        //commenting the below condition to execute script otherwise it aborts
        // if (new_balance == old_balance) {
        //     abort(1)
        // };
    }
}
