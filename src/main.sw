contract;

use std::{
    chain::auth::{
        AuthError,
        msg_sender,
    },
    constants::BASE_ASSET_ID,
    token::transfer_to_address,
};

enum State {
    awate_payment: (),
    awate_delivery: (),
    complete: (),
}

storage {
    state: State = State::awate_payment,
    Buyer_addr: Address = ~Address::from(0x9299da6c73e6dc03eeabcce242bb347de3f5f56cd1c70926d76526d7ed199b8b),
    Seller_addr: Address = ~Address::from(0x9299da6c73e6dc03eeabcce242bb347de3f5f56cd1c70926d76526d7ed199b8b),
    Arbiter_addr: Address = ~Address::from(0x9299da6c73e6dc03eeabcce242bb347de3f5f56cd1c70926d76526d7ed199b8b),
}

abi Escrow {
    #[storage(write)]
    fn constructor(buyer_addr: Address, seller_addr: Address);

    #[storage(read, write)]
    fn confirm_payment();

    #[storage(read, write)]
    fn confirm_delivery(amount_to_send: u64);

    #[storage(read)]
    fn return_payment(amount_to_send: u64);
}

impl Escrow for Contract {
    #[storage(write)]
    fn constructor(buyer_addr: Address, seller_addr: Address) {
        storage.Buyer_addr = buyer_addr;
        storage.Seller_addr = seller_addr;
        let sender: Result<Identity, AuthError> = msg_sender();
        let sender = match sender.unwrap() {
            Identity::Address(addr) => addr,
            _ => revert(0),
        };
        storage.Arbiter_addr = sender;
    }
    #[storage(read, write)]
    fn confirm_payment() {
        let sender: Result<Identity, AuthError> = msg_sender();
        match sender.unwrap() {
            Identity::Address(addr) => assert(addr == storage.Buyer_addr || addr == storage.Arbiter_addr),
            _ => revert(0),
        };
       // assert(storage.state == State::awate_payment);
        match storage.state {
            State::awate_payment => (),
            _ => revert(0),
        };

        storage.state = State::awate_delivery;
    }
    #[storage(read, write)]
    fn confirm_delivery(amount_to_send: u64) {
        let sender: Result<Identity, AuthError> = msg_sender();
        match sender.unwrap() {
            Identity::Address(addr) => assert(addr == storage.Buyer_addr || addr == storage.Seller_addr),
            _ => revert(0),
        };
       // assert(storage.state == State::awate_delivery);
        match storage.state {
            State::awate_delivery => (),
            _ => revert(0),
        };
        storage.state = State::complete;
        transfer_to_address(amount_to_send, BASE_ASSET_ID, storage.Seller_addr);
    }
    #[storage(read)]
    fn return_payment(amount_to_send: u64) {
        let sender: Result<Identity, AuthError> = msg_sender();
        match sender.unwrap() {
            Identity::Address(addr) => assert(addr == storage.Seller_addr),
            _ => revert(0),
        };
       // assert(storage.state == State::awate_delivery);
        match storage.state {
            State::awate_delivery => (),
            _ => revert(0),
        };
        transfer_to_address(amount_to_send, BASE_ASSET_ID, storage.Buyer_addr);
    }
}
