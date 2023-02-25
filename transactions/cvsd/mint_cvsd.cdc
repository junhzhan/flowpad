import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import CVSDTokenV2 from "../../contracts/CVSD/CVSDTokenV2.cdc"

transaction(receiver: Address) {
    prepare(signer: AuthAccount) {
        let minter <- signer.borrow<&CVSDTokenV2.Administrator>(from: CVSDTokenV2.AdminStoragePath)!.createNewMinter()
        let vault <- minter.mintTokens(amount: 200_0000.0)
        getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(/public/cvsdReceiver).borrow()!.deposit(from: <- vault)
        destroy minter
        
    }
}