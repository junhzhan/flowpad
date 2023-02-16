import ErrorCode from "./ErrorCode.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import StrUtility from "./StrUtility.cdc"

pub contract RaisePool {

    access(self) let typeArray: [Type]
    pub let vaultTypeInfos: [TokenVaultInfo]
    pub event DebugEvent(msg: String)

    pub struct TokenVaultInfo {
        pub let typeStr: String
        pub let storagePathStr: String

        init(typeStr: String, storagePath: String) {
            self.typeStr = typeStr
            self.storagePathStr = storagePath
        }
    }

    init(typeStr: String, pathStr: String, raiseValue: UFix64) {
        log(typeStr)
        log(pathStr)
        let typeStrArray = StrUtility.splitStr(str: typeStr, delimiter: "&")
        log(typeStrArray)
        let pathStrArray = StrUtility.splitStr(str: pathStr, delimiter: "&")
        log(pathStrArray)
        self.typeArray = []
        self.vaultTypeInfos = []
        assert(typeStrArray.length == pathStrArray.length, message: "typeStr array length is not equal to storagePath array")
        for index, typeStrItem in typeStrArray {
            let vaultStoragePath: StoragePath = StoragePath(identifier: pathStrArray[index])!
            log(vaultStoragePath)
            log(self.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType().identifier)
            assert(self.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType().identifier == typeStrItem, message: ErrorCode.encode(code: ErrorCode.Code.VAULT_TYPE_MISMATCH))
            self.vaultTypeInfos.append(TokenVaultInfo(typeStr: typeStrItem, storagePath: pathStrArray[index]))
        }

    }
}
 