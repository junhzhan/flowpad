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

    pub var startTimestamp: UFix64

    pub var endTimestamp: UFix64

    pub var projectTokenPrice: UFix64


    pub var totalProjectToken: UFix64

    pub var projectTokenName: String

    pub enum Status: UInt8 {
        pub case COMING_SOON
        pub case ONGOING
        pub case END
    }

    pub let poolTokenBalance: {Type: TokenBalance}

    pub struct TokenBalance {
        pub let vaultType: Type
        pub let balance: UFix64
        pub let oracleAccount: Address
        pub let account: Address

        init(balance: UFix64, vaultType: Type, oracleAccount: Address, account: Address) {
            self.vaultType = vaultType
            self.balance = balance
            self.oracleAccount = oracleAccount
            self.account = account
        }

        pub fun getTokenPrice(): UFix64 {
            let priceReaderSuggestedPath = getAccount(self.oracleAccount).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()!.getPriceReaderStoragePath()
            /// local PriceReader reference
            let priceReaderRef  = RaisePool.account.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
                      ?? panic("Lost local price reader")
            let price = priceReaderRef.getMedianPrice()
            return price
        }
    }


    pub fun getUserCommitDetail(userAccount: Address): [{String: AnyStruct}] {
        assert(self.userTokenBalance.containsKey(userAccount), message: ErrorCode.encode(code: ErrorCode.Code.COMMIT_ADDRESS_NOT_EXIST))
        let userTokenBalance = self.userTokenBalance[userAccount]!
        let tokenList: [{String: AnyStruct}]= []
        for tokenType in userTokenBalance.keys {
            let tokenBalance = userTokenBalance[tokenType]! 
            let tokenKey = tokenBalance.vaultType.identifier
            let balance = tokenBalance.balance
            let oracleAccount = tokenBalance.oracleAccount
            /// Recommended storage path for PriceReader resource
            let priceReaderSuggestedPath = getAccount(oracleAccount).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()!.getPriceReaderStoragePath()
            /// local PriceReader reference
            let priceReaderRef  = self.account.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
                      ?? panic("Lost local price reader")
            let price = priceReaderRef.getMedianPrice()
            tokenList.append({"tokenKey": tokenKey, "amount": balance, "price": price})
        }
        return tokenList

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
    pub fun commit(commiterAddress: Address, token: @FungibleToken.Vault) {
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
        } else {
            panic(ErrorCode.encode(code: ErrorCode.Code.COMMITTED_TOKEN_NOT_SUPPORTED))
        }
    }

    pub resource PoolAdmin {
        /// set vault related fields for tokens to be committed
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

        pub fun setStartTimestamp(startTimestamp: UFix64) {
            RaisePool.startTimestamp = startTimestamp
        }

        pub fun setEndTimestamp(endTimestamp: UFix64) {
            RaisePool.endTimestamp = endTimestamp
        }

        pub fun setProjectInfo(tokenName: String, tokenAmount: UFix64, tokenPrice: UFix64) {
            RaisePool.projectTokenName = tokenName
            RaisePool.totalProjectToken = tokenAmount
            RaisePool.projectTokenPrice = tokenPrice
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

        ///adjust token balance of the whole pool
        if let poolTokenBalance = self.poolTokenBalance[type] {
            let updatePoolTokenBalance = TokenBalance(balance: poolTokenBalance.balance + addedBalance, vaultType: type, oracleAccount: oracleAccount, account: 0x0)
            self.poolTokenBalance[type] = updatePoolTokenBalance
        } else {
            let updatePoolTokenBalance = TokenBalance(balance: addedBalance, vaultType: type, oracleAccount: oracleAccount, account: 0x0)
            self.poolTokenBalance[type] = updatePoolTokenBalance
        }
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
        self.startTimestamp = UFix64.max
        self.endTimestamp = UFix64.max
        self.poolTokenBalance = {}
        self.projectTokenName = ""
        self.totalProjectToken = 0.0
        self.projectTokenPrice = 0.0
        
        self.account.save(<- create PoolAdmin(), to: self.AdminStorage)

    }
}
 