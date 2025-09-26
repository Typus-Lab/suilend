/// No authority chech in these public functions, do not let `DepositVault` `BidVault` and `RefundVault` be exposed.
#[allow(unused)]
module typus_framework::vault {
    use std::string::{Self, String};
    use std::type_name::{Self, TypeName};

    use sui::balance::{Self, Balance};
    use sui::coin::Coin;
    use sui::display;
    use sui::dynamic_field;

    use typus_framework::balance_pool::{Self, BalancePool};

    /// One-time witness for the vault module.
    public struct VAULT has drop {}

    /// The main vault for user deposits. It manages different sub-vaults (active, deactivating, inactive, warmup, premium, incentive)
    /// as balances and tracks user shares in a `BigVector`.
    ///
    /// The lifecycle of funds in the vault is as follows:
    /// 1. **Deposit**: User deposits funds, which go into the `warmup` sub-vault.
    /// 2. **Activate**: A manager activates the vault, moving funds from `warmup` to `active`.
    /// 3. **Unsubscribe**: A user unsubscribes, moving their share from `active` to `deactivating`.
    /// 4. **Recoup/Settle/Delivery**: These are manager-only functions that handle the outcome of the strategy.
    ///    - Unfilled portions are refunded.
    ///    - Premiums are collected.
    ///    - Funds are moved between sub-vaults based on the outcome and whether there is a next round.
    /// 5. **Claim/Harvest**: Users claim their funds from the `inactive` sub-vault or harvest premiums.
    public struct DepositVault has key, store {
        id: UID,
        /// The type of the token that is deposited into the vault.
        deposit_token: TypeName,
        /// The type of the token that is used for bidding/premiums.
        bid_token: TypeName,
        /// The type of the incentive token, if any.
        incentive_token: Option<TypeName>,
        /// An index for the vault, often corresponding to an auction.
        index: u64,
        /// The fee in basis points.
        fee_bp: u64,
        /// The portion of the fee that is shared, in basis points.
        fee_share_bp: u64,
        /// The key for the shared fee pool, if any.
        shared_fee_pool: Option<vector<u8>>,
        /// The total supply of shares in the active sub-vault.
        active_share_supply: u64,
        /// The total supply of shares in the deactivating sub-vault (for users who have unsubscribed).
        deactivating_share_supply: u64, // unsubscribe
        /// The total supply of shares in the inactive sub-vault (for users to claim).
        inactive_share_supply: u64, // claim
        /// The total supply of shares in the warmup sub-vault (for new deposits).
        warmup_share_supply: u64, // deposit / withdraw
        /// The total supply of shares in the premium sub-vault (for harvesting).
        premium_share_supply: u64, // harvest
        /// The total supply of shares in the incentive sub-vault (for redeeming).
        incentive_share_supply: u64, // redeem
        /// A flag indicating if there is a next round for the vault.
        has_next: bool,
        /// Metadata for display purposes.
        metadata: String,
        /// Padding for additional u64 fields.
        u64_padding: vector<u64>,
        /// Padding for additional BCS-encoded fields.
        bcs_padding: vector<u8>,
    }

    /// Holds the funds from bidders.
    public struct BidVault has key, store {
        id: UID,
        /// The type of the token that is deposited into the vault.
        deposit_token: TypeName,
        /// The type of the token that is used for bidding.
        bid_token: TypeName,
        /// The type of the incentive token, if any.
        incentive_token: Option<TypeName>,
        /// An index for the vault.
        index: u64,
        /// The total supply of shares in the vault.
        share_supply: u64,
        /// Metadata for display purposes.
        metadata: String,
        /// Padding for additional u64 fields.
        u64_padding: vector<u64>,
        /// Padding for additional BCS-encoded fields.
        bcs_padding: vector<u8>,
    }

    /// Holds funds to be refunded to users.
    public struct RefundVault has key, store {
        id: UID,
        /// The type of the token being refunded.
        token: TypeName,
        /// The total supply of shares in the vault.
        share_supply: u64,
        /// Padding for additional u64 fields.
        u64_padding: vector<u64>,
        /// Padding for additional BCS-encoded fields.
        bcs_padding: vector<u8>,
    }

    /// Represents a user's shares in the `DepositVault`.
    public struct DepositShare has copy, store {
        /// The address of the user's receipt NFT.
        receipt: address,
        /// The user's share in the active sub-vault.
        active_share: u64,
        /// The user's share in the deactivating sub-vault.
        deactivating_share: u64,
        /// The user's share in the inactive sub-vault.
        inactive_share: u64,
        /// The user's share in the warmup sub-vault.
        warmup_share: u64,
        /// The user's share in the premium sub-vault.
        premium_share: u64,
        /// The user's share in the incentive sub-vault.
        incentive_share: u64,
        /// Padding for additional u64 fields.
        u64_padding: vector<u64>,
    }

    /// An NFT that represents a user's deposit.
    public struct TypusDepositReceipt has key, store {
        id: UID,
        /// The ID of the `DepositVault`.
        vid: ID,
        /// The index of the vault.
        index: u64,
        /// Metadata for display purposes.
        metadata: String,
        /// Padding for additional u64 fields.
        u64_padding: vector<u64>,
    }

    /// Represents a bidder's shares in the `BidVault`.
    public struct BidShare has copy, store {
        /// The address of the bidder's receipt NFT.
        receipt: address,
        /// The bidder's share.
        share: u64,
        /// Padding for additional u64 fields.
        u64_padding: vector<u64>,
    }

    /// An NFT that represents a bid.
    public struct TypusBidReceipt has key, store {
        id: UID,
        /// The ID of the `BidVault`.
        vid: ID,
        /// The index of the vault.
        index: u64,
        /// Metadata for display purposes.
        metadata: String,
        /// Padding for additional u64 fields.
        u64_padding: vector<u64>,
    }

    /// Represents a user's share in the `RefundVault`.
    public struct RefundShare has copy, store {
        /// The address of the user.
        user: address,
        /// The user's share.
        share: u64,
        /// Padding for additional u64 fields.
        u64_padding: vector<u64>,
    }


    /// Withdraws funds from the active and deactivating sub-vaults for lending.
    /// WARNING: mut inputs without authority check inside
    public fun withdraw_for_lending<TOKEN>(
        deposit_vault: &mut DepositVault,
    ): (Balance<TOKEN>, vector<u64>) {
        abort 0
    }
    /// Deposits funds from a lending protocol back into the vault.
    /// It handles the distribution of principal and rewards, and charges fees.
    /// WARNING: mut inputs without authority check inside
    public fun deposit_from_lending<D_TOKEN, R_TOKEN>(
        fee_pool: &mut BalancePool,
        deposit_vault: &mut DepositVault,
        incentive: &mut Balance<D_TOKEN>,
        mut balance: Balance<D_TOKEN>,
        mut reward: Balance<R_TOKEN>,
        distribute: bool,
    ): vector<u64> {
        abort 0
    }
    /// Deposits rewards from a lending protocol into the vault.
    /// WARNING: mut inputs without authority check inside
    public fun reward_from_lending<TOKEN>(
        fee_pool: &mut BalancePool,
        deposit_vault: &mut DepositVault,
        mut reward: Balance<TOKEN>,
        distribute: bool,
    ): vector<u64> {
        abort 0
    }
}
