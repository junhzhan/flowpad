import ErrorCode from "./ErrorCode.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import StrUtility from "./StrUtility.cdc"

pub contract RaisePool {

    access(self) let typeArray: [Type]
    access(self) let vaultTypeInfos: [TokenVaultInfo]

    access(self) let tokenAmount: {Address: {Type: UFix64}}

    pub struct TokenVaultInfo {
        pub let typeStr: String
        pub let storagePathStr: String

        init(typeStr: String, storagePath: String) {
            self.typeStr = typeStr
            self.storagePathStr = storagePath
        }

        pub fun getVaultType(): Type {
            return CompositeType(self.typeStr)!
        }

        pub fun getStoragePath(): StoragePath {
            return StoragePath(identifier: self.storagePathStr)!
        }
    }

    pub fun commit(commiterAddress: Address, token: @FungibleToken.Vault): @FungibleToken.Vault? {
        var poolVaultRef: &FungibleToken.Vault? = nil
        for element in self.vaultTypeInfos {
            if token.isInstance(element.getVaultType()) {
                poolVaultRef = self.account.borrow<&FungibleToken.Vault>(from: element.getStoragePath())!
            }
        }
        if poolVaultRef != nil {
            self.depositToken(address: commiterAddress, token: <- token, tokenPool: poolVaultRef!)
            return nil
        } else {
            return <- token
        }
    }

    access(self) fun depositToken(address: Address, token: @FungibleToken.Vault, tokenPool: &FungibleToken.Vault) {

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
        self.tokenAmount = {}
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
 