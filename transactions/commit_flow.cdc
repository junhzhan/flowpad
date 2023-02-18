
import RaisePool from "../contracts/RaisePool.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"


transaction {
    prepare(signer: AuthAccount) {
        let flowToken <- signer.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)!.withdraw(amount: 2.5)
        RaisePool.commit(commiterAddress: signer.address, token: <- flowToken)
    }
}