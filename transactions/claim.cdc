
import RaisePool from "../contracts/RaisePool.cdc"
import RaisePoolInterface from "../contracts/RaisePoolInterface.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import StrUtility from "../contracts/StrUtility.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let claimedToken <- RaisePool.claim(certificateCap: signer.getCapability<&{RaisePoolInterface.Certificate}>(/private/flowpad_certificate))
        let poolTokenInfos = RaisePool.tokenInfos
        let projecTTokenToClaim <- claimedToken.remove(key: RaisePool.projectTokenKey)
        if signer.borrow<&FungibleToken.Vault>(from: RaisePool.projectTokenStoragePath!) == nil {
            let strParts = StrUtility.splitStr(str: RaisePool.projectTokenKey, delimiter: ".")
            let tokenAccount = strParts[1]
            let tokenAddress = StrUtility.toAddress(from: tokenAccount)
            signer.save(<- getAccount(tokenAddress).contracts.borrow<&FungibleToken>(name: strParts[2])!.createEmptyVault(), to: RaisePool.projectTokenStoragePath!)
            signer.link<&{FungibleToken.Receiver}>(RaisePool.projectTokenReceiverPath!, target: RaisePool.projectTokenStoragePath!)
            signer.link<&{FungibleToken.Balance}>(RaisePool.projectTokenBalancePath!, target: RaisePool.projectTokenStoragePath!)
        }
        signer.borrow<&FungibleToken.Vault>(from: RaisePool.projectTokenStoragePath!)!.deposit(from: <- projecTTokenToClaim!)
        
        for tokenKey in claimedToken.keys {
            let vault <- claimedToken.remove(key: tokenKey)
            let tokenInfo = poolTokenInfos[tokenKey]!
            signer.borrow<&FungibleToken.Vault>(from: tokenInfo.getStoragePath())!.deposit(from: <- vault!)
        }
        destroy claimedToken
    }
}