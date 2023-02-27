
import RaisePool from "../contracts/RaisePool.cdc"
import UserCertificate from "../contracts/UserCertificate.cdc"
import RaisePoolInterface from "../contracts/RaisePoolInterface.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"


transaction {
    prepare(signer: AuthAccount) {
        if signer.borrow<&{RaisePoolInterface.Certificate}>(from: /storage/flowpad_certificate) == nil {
            signer.save(<- UserCertificate.issueCertificate(), to: /storage/flowpad_certificate)
            signer.link<&{RaisePoolInterface.Certificate}>(/private/flowpad_certificate, target: /storage/flowpad_certificate)
        }
        let certificateCap = signer.getCapability<&{RaisePoolInterface.Certificate}>(/private/flowpad_certificate)
        let claimedTokens <- RaisePool.projectClaim(certificateCap: certificateCap)
        let poolTokenInfos = RaisePool.tokenInfos
        for tokenKey in claimedTokens.keys {
            let vault <- claimedTokens.remove(key: tokenKey)
            let tokenInfo = poolTokenInfos[tokenKey]!
            signer.borrow<&FungibleToken.Vault>(from: tokenInfo.getStoragePath())!.deposit(from: <- vault!)
        }
        destroy claimedTokens
    }
}