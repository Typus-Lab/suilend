module typus_framework::authority {
    use sui::linked_table::{Self, LinkedTable};

    const E_UNAUTHORIZED: u64 = 0;
    const E_EMPTY_WHITELIST: u64 = 1;

    /// A struct that holds a whitelist of authorized users.
    public struct Authority has store {
        /// A linked table mapping user addresses to a boolean `true`.
        whitelist: LinkedTable<address, bool>,
    }

}