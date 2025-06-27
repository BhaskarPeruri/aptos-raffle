# Raffle Module

A decentralized raffle system built on the Aptos blockchain that allows users to purchase tickets and randomly selects a winner who receives the entire prize pool.

## Overview

The Raffle module implements a fair and transparent lottery system where:

1. Users can purchase tickets for a fixed price in APT
2. Each user can only buy one ticket per raffle
3. A random winner is selected from all ticket holders
4. The winner receives the entire accumulated prize pool
5. The raffle automatically closes after a winner is drawn

## Core Functionality

### Ticket Purchase

- Function: buy_a_ticket(user: &signer)

- Price: 10,000 octas (0.0001 APT) per ticket

- Restriction: One ticket per unique address

**Process:**

- Validates user hasn't already purchased a ticket.
- Withdraws ticket price from user's account

- Adds funds to the prize pool

- Records user's address in the ticket list

### Winner Selection

- Function: randomly_pick_winner() (entry point)

- Internal Logic: randomly_pick_winner_internal()

- Randomness: Uses Aptos Framework's secure randomness API

**Process:**

- Validates raffle is still open
- Ensures at least one ticket exists
- Generates random index within ticket array bounds
- Transfers entire prize pool to winner
- Marks raffle as closed

### View Functions

get_ticket_price(): Returns the current ticket price (10,000 octas)

## Security Features

1. The module uses a UserInfo resource to ensure that each user can only participate once per raffle. This prevents spamming or monopolizing ticket purchases.

2. Custom error codes ensure proper control flow:

   - E_NO_TICKETS (2): Prevents selecting a winner if no one bought tickets.

   - E_RAFFLE_HAS_CLOSED (3): Disallows rerunning the draw after closure.

   - E_UNIQUE_USERS_ONLY (4): Ensures a user cannot buy multiple tickets.

3. **Test-and-Abort Attack Prevention**

- Entry Function Protection:

  The winner selection function is implemented as an entry function with #[randomness] attribute, preventing external module calls

- AIP-41 Compliance:

  Follows Aptos Improvement Proposal 41 guidelines for secure randomness implementation

- Public Function Elimination:

  The module deliberately avoids exposing randomly_pick_winner() as a public function to prevent test-and-abort attacks where:

  1. An attacker could call the function from a script
  2. Check if they won using the return value
  3. Abort the transaction if they didn't win
  4. Retry until they become the winner

- Secure Architecture:

  Only entry functions can access randomness, ensuring the winner selection cannot be manipulated through transaction reverting strategies

## Compile

```
aptos move compile
```

## Test

```
aptos move test
```

## Test coverage

```
aptos move test --coverage
```

## For specific module coverage

```
aptos move coverage source --module <MODULE_NAME>
```

## Publish

```
aptos move publish
```

## Compile Script

```
aptos move compile-script

```

## Run Compile Script

```
aptos move run-script --compiled-script-path script.mv
```

## Format Move Code

```
aptos move fmt
```
