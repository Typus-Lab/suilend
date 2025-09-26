/// No authority chech in these public functions, do not let `BalancePool` be exposed.
#[allow(unused)]
module typus_framework::balance_pool {
    use std::type_name::{TypeName};

    use typus_framework::authority::{Self, Authority};

    /// A pool that holds multiple types of token balances.
    /// It uses a main `Authority` object for access control on certain operations.
    public struct BalancePool has key, store {
        id: UID,
        /// A vector storing metadata about the balances in the pool.
        balance_infos: vector<BalanceInfo>,
        /// The `Authority` object that controls access to sensitive functions.
        authority: Authority,
    }

    /// Stores information about a specific token's balance.
    public struct BalanceInfo has copy, drop, store {
        /// The `TypeName` of the token.
        token: TypeName,
        /// The amount of the token.
        value: u64,
    }

    /// A namespaced balance pool that exists as a dynamic field within a `BalancePool`.
    /// This allows for separate, controlled sub-pools.
    public struct SharedBalancePool has key, store {
        id: UID,
        /// A vector storing metadata about the balances in the shared pool.
        balance_infos: vector<BalanceInfo>,
        /// The `Authority` object that controls access for this specific shared pool.
        authority: Authority,
    }
}