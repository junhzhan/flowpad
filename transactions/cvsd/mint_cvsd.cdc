import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import CVSDToken from "../../contracts/CVSD/CVSDToken.cdc"

transaction(receiver: Address) {
    prepare(signer: AuthAccount) {
        let minter <- signer.borrow<&CVSDToken.Administrator>(from: CVSDToken.AdminStoragePath)!.createNewMinter()
        let vault <- minter.mintTokens(amount: 200_0000.0)
        getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(/public/cvsdReceiver).borrow()!.deposit(from: <- vault)
        destroy minter
        
    }
}