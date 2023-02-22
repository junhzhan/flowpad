
import RaisePool from "../contracts/RaisePool.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import UserCertificate from "../contracts/UserCertificate.cdc"
import RaisePoolInterface from "../contracts/RaisePoolInterface.cdc"


transaction(amount: UFix64) {
    prepare(signer: AuthAccount) {
        
        if signer.borrow<&{RaisePoolInterface.Certificate}>(from: /storage/flowpad_certificate) == nil {
            signer.save(<- UserCertificate.issueCertificate(), to: /storage/flowpad_certificate)
            signer.link<&{RaisePoolInterface.Certificate}>(/private/flowpad_certificate, target: /storage/flowpad_certificate)
        }
        let flowToken <- signer.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)!.withdraw(amount: amount)
        RaisePool.commit(commiterAddress: signer.address, token: <- flowToken)
    }
}