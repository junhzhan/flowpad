import ErrorCode from "./ErrorCode.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import StrUtility from "./StrUtility.cdc"

pub contract RaisePool {

    access(self) let typeArray: [Type]
    access(self) var vaultTypeInfos: [TokenVaultInfo]

    pub let userTokenBalance: {Address: {Type: UserTokenBalance}}

    pub struct UserTokenBalance {
        pub let vaultType: Type
        pub(set) var balance: UFix64
        pub(set) var balanceInUSDC: UFix64

        init(vaultType: Type) {
            self.vaultType = vaultType
            self.balance = 0.0
            self.balanceInUSDC = 0.0
        }
    }

    pub struct TokenVaultInfo {
        pub let typeStr: String
        pub let storagePathStr: String
        pub let oracleAccount: Address

        init(typeStr: String, storagePath: String, oracleAccount: Address) {
            self.typeStr = typeStr
            self.storagePathStr = storagePath
            self.oracleAccount = oracleAccount
        }

        pub fun getVaultType(): Type {
            return CompositeType(self.typeStr)!
        }

        pub fun getStoragePath(): StoragePath {
            return StoragePath(identifier: self.storagePathStr)!
        }

        pub fun getOracleAccount(): Address {
            return self.oracleAccount
        }

    
    }

    /** 
    user commits one of the supported tokens
    **/
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

    pub resource PoolAdmin {
        pub fun setTokenVaultInfo(typeStrList: [String], pathStrList:[String], oracleAccountList: [Address]) {
            RaisePool.vaultTypeInfos = []
            for index, typeStrItem in typeStrList {
                let vaultStoragePath: StoragePath = StoragePath(identifier: pathStrList[index])!
                log(vaultStoragePath)
                log(RaisePool.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType().identifier)
                assert(RaisePool.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType().identifier == typeStrItem, message: ErrorCode.encode(code: ErrorCode.Code.VAULT_TYPE_MISMATCH))
                RaisePool.vaultTypeInfos.append(TokenVaultInfo(typeStr: typeStrItem, storagePath: pathStrList[index], oracleAccount: oracleAccountList[index]))
            }
        }
    }

    access(self) fun depositToken(address: Address, token: @FungibleToken.Vault, tokenPool: &FungibleToken.Vault) {
        let type = token.getType()
        let balance = token.balance
        tokenPool.deposit(from: <- token)
        let userTokenMap: {Type: UserTokenBalance} = self.userTokenBalance[address] ?? {}
        let userTokenBalance: UserTokenBalance = userTokenMap[type] ?? UserTokenBalance(vaultType: type)
        userTokenBalance.balance = userTokenBalance.balance + balance
        userTokenBalance.balanceInUSDC = userTokenBalance.balanceInUSDC + balance
        userTokenMap[type] = userTokenBalance
        self.userTokenBalance[address] = userTokenMap
    }

    init(typeStr: String, pathStr: String, oracleAccount: String) {
        log(typeStr)
        log(pathStr)
        let typeStrArray = StrUtility.splitStr(str: typeStr, delimiter: "&")
        log(typeStrArray)
        let pathStrArray = StrUtility.splitStr(str: pathStr, delimiter: "&")
        log(pathStrArray)
        self.typeArray = []
        self.vaultTypeInfos = []
        self.userTokenBalance = {}
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
 