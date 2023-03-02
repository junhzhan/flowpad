
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

import CVSDTokenV2 from "../../contracts/CVSD/CVSDTokenV2.cdc"


transaction {

    prepare(signer: AuthAccount) {

        // It's OK if the account already has a Vault, but we don't want to replace it
        if(signer.borrow<&CVSDTokenV2.Vault>(from: /storage/cvsdTokenVaultV2) == nil) {
            signer.save(<-CVSDTokenV2.createEmptyVault(), to: /storage/cvsdTokenVaultV2)
        }
        
        // Create a new FUSD Vault and put it in storage

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&CVSDTokenV2.Vault{FungibleToken.Receiver}>(
            /public/cvsdReceiverV2,
            target: /storage/cvsdTokenVaultV2
        )

        signer.link<&{FungibleToken.Balance}>(/public/cvsdBalanceV2, target: /storage/cvsdTokenVaultV2)
    }
}