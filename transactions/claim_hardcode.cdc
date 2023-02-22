
import RaisePool from "../contracts/RaisePool.cdc"
import RaisePoolInterface from "../contracts/RaisePoolInterface.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import StrUtility from "../contracts/StrUtility.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let tokenInfo = {"A.7e60df042a9c0868.FlowToken": "flowTokenVault", 
        "A.a983fecbed621163.FiatToken": "USDCVault", 
        "A.f4a4c2b1fdfcb72f.CVSDToken": "cvsdTokenVault"}
        let claimedToken <- RaisePool.claim(certificateCap: signer.getCapability<&{RaisePoolInterface.Certificate}>(/private/flowpad_certificate))
        for tokenKey in claimedToken.keys {
            let vault <- claimedToken.remove(key: tokenKey)
            let vaultStoragePath = StoragePath(identifier: tokenInfo[tokenKey]!)!
            if signer.borrow<&FungibleToken.Vault>(from: StoragePath(identifier: tokenInfo[tokenKey]!)!) == nil {
                let strParts = StrUtility.splitStr(str: tokenKey, delimiter: ".")
                let tokenAccount = strParts[1]
                let tokenAddress = StrUtility.toAddress(from: tokenAccount)
                signer.save(<- getAccount(tokenAddress).contracts.borrow<&FungibleToken>(name: strParts[2])!.createEmptyVault(), to: vaultStoragePath)
            }
            signer.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.deposit(from: <- vault!)
        }
        destroy claimedToken
    }
}