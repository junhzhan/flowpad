
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import CVSDToken from "../../contracts/CVSD/CVSDToken.cdc"

transaction {

    prepare(signer: AuthAccount) {

        // It's OK if the account already has a Vault, but we don't want to replace it
        if(signer.borrow<&CVSDToken.Vault>(from: /storage/cvsdTokenVault) != nil) {
            return
        }
        
        // Create a new FUSD Vault and put it in storage
        signer.save(<-CVSDToken.createEmptyVault(), to: /storage/cvsdTokenVault)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&CVSDToken.Vault{FungibleToken.Receiver}>(
            /public/cvsdReceiver,
            target: /storage/cvsdTokenVault
        )

    }
}