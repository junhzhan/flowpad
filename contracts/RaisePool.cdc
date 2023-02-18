import ErrorCode from "./ErrorCode.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import StrUtility from "./StrUtility.cdc"
import OracleInterface from "./oracle/OracleInterface.cdc"
import OracleConfig from "./oracle/OracleConfig.cdc"

pub contract RaisePool {

    access(self) let typeArray: [Type]
    access(self) var vaultTypeInfos: [TokenVaultInfo]

    pub let AdminStorage: StoragePath

    pub let userTokenBalance: {Address: {Type: TokenBalance}}

    pub struct TokenBalance {
        pub let vaultType: Type
        pub let balance: UFix64
        pub let oracleAccount: Address
        pub let account: Address

        init(balance: UFix64, vaultType: Type, oracleAccount: Address, account: Address) {
            self.vaultType = vaultType
            self.balance = 0.0
            self.oracleAccount = oracleAccount
            self.account = account
        }
    }

    pub fun getUserTokenBalance(userAccount: Address): [{String: AnyStruct}] {
        assert(self.userTokenBalance.containsKey(userAccount), message: ErrorCode.encode(code: ErrorCode.Code.COMMIT_ADDRESS_NOT_EXIST))
        let userTokenBalance = self.userTokenBalance[userAccount]!
        let tokenList: [{String: AnyStruct}]= []
        for tokenType in userTokenBalance.keys {
            let tokenBalance = userTokenBalance[tokenType]! 
            let tokenKey = tokenBalance.vaultType.identifier
            let balance = tokenBalance.balance
            
            tokenList
        }
        return []

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
        var oracleAccount: Address? = nil
        for element in self.vaultTypeInfos {
            if token.isInstance(element.getVaultType()) {
                poolVaultRef = self.account.borrow<&FungibleToken.Vault>(from: element.getStoragePath())!
                oracleAccount = element.getOracleAccount()
            }
        }
        if poolVaultRef != nil {
            self.depositToken(address: commiterAddress, token: <- token, tokenPool: poolVaultRef!, oracleAccount: oracleAccount!)
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

    access(self) fun depositToken(address: Address, token: @FungibleToken.Vault, tokenPool: &FungibleToken.Vault, oracleAccount: Address) {
        let type = token.getType()
        let addedBalance = token.balance
        tokenPool.deposit(from: <- token)
        let userTokenMap: {Type: TokenBalance} = self.userTokenBalance[address] ?? {}
        if let userTokenBalance = userTokenMap[type] {
            userTokenMap[type] = TokenBalance(balance: userTokenBalance.balance + addedBalance, vaultType: type, oracleAccount: oracleAccount, account: address)
        } else {
            userTokenMap[type] = TokenBalance(balance: addedBalance, vaultType: type, oracleAccount: oracleAccount, account: address)
        }
        self.userTokenBalance[address] = userTokenMap
    }

    access(self) fun readTokenPrice(oracleAccount: Address): UFix64 {
        let priceReaderSuggestedPath = getAccount(oracleAccount).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()!.getPriceReaderStoragePath()
        let priceReaderRef  = self.account.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
                      ?? panic("Lost local price reader")
        let price = priceReaderRef.getMedianPrice()
        return price
    }

    init() {
        self.AdminStorage = /storage/flowpadAdmin
        self.typeArray = []
        self.vaultTypeInfos = []
        self.userTokenBalance = {}
        self.account.save(<- create PoolAdmin(), to: self.AdminStorage)

    }
}
 