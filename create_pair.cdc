import FlowToken from "../../contracts/tokens/FlowToken.cdc"
import FungibleToken from "../../contracts/tokens/FungibleToken.cdc"
import SwapFactory from "../../contracts/SwapFactory.cdc"

/// deploy code copied by a deployed contract
transaction(Token0Name: String, Token0Addr: Address, Token1Name: String, Token1Addr: Address) {
    prepare(userAccount: AuthAccount) {
        let flowVaultRef = userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        assert(flowVaultRef.balance >= 0.002, message: "Insufficient balance to create pair, minimum balance requirement: 0.002 flow")
        let accountCreationFeeVault <- flowVaultRef.withdraw(amount: 0.001)
        
        let token0Vault <- getAccount(Token0Addr).contracts.borrow<&FungibleToken>(name: Token0Name)!.createEmptyVault()
        let token1Vault <- getAccount(Token1Addr).contracts.borrow<&FungibleToken>(name: Token1Name)!.createEmptyVault()
        SwapFactory.createPair(token0Vault: <-token0Vault, token1Vault: <-token1Vault, accountCreationFee: <-accountCreationFeeVault)
    }
}