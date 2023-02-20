import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import StrUtility from "../contracts/StrUtility.cdc"

transaction(tokenKeyList: [String], storagePathList: [String], oracleAccountList: [Address]) {
    prepare(signer: AuthAccount) {
        for index, tokenKey in tokenKeyList {
            let subStr = StrUtility.splitStr(str: tokenKey, delimiter: ".")
            let tokenAccount = subStr[1]
            let tokenName = subStr[2]
            let vaultStoragePath = StoragePath(identifier: storagePathList[index])!
            if signer.borrow<&FungibleToken.Vault>(from: vaultStoragePath) == nil {
                let tokenVault <- getAccount(StrUtility.toAddress(from: tokenAccount)).contracts.borrow<&FungibleToken>(name: tokenName)!.createEmptyVault()
                signer.save(<- tokenVault,to: vaultStoragePath)
            }
        }
    }
}