import ErrorCode from "./ErrorCode.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import StrUtility from "./StrUtility.cdc"
import OracleInterface from "./oracle/OracleInterface.cdc"
import OracleConfig from "./oracle/OracleConfig.cdc"

pub contract RaisePool {

    access(self) let typeArray: [Type]
    access(self) var tokenInfos: [TokenInfo]

    pub let AdminStorage: StoragePath

    pub let userTokenBalance: {Address: {Type: TokenBalance}}

    pub var startTimestamp: UFix64

    pub var endTimestamp: UFix64

    pub var projectTokenPrice: UFix64


    pub var totalProjectToken: UFix64

    pub var projectName: String

    pub var projectTokenKey: String

    pub enum Status: UInt8 {
        pub case COMING_SOON
        pub case ONGOING
        pub case END
    }

    pub let poolTokenBalance: {Type: TokenBalance}

    pub struct TokenBalance {
        pub let tokenKey: String
        pub let balance: UFix64
        pub let oracleAccount: Address
        pub let account: Address

        init(tokenKey: String, balance: UFix64, oracleAccount: Address, account: Address) {
            self.tokenKey = tokenKey
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
            let tokenKey = tokenBalance.tokenKey
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

    pub fun getTokenPurchased(userAccount: Address): UFix64 {
        let userTokenBalance = self.userTokenBalance[userAccount]!
        var userCommitValue: UFix64 = self.caculateValue(tokenBalance: userTokenBalance)
        var totalCommitValue: UFix64 = self.caculateValue(tokenBalance: self.poolTokenBalance)
        var tokenPurchased: UFix64 = 0.0
        if totalCommitValue > (self.totalProjectToken * self.projectTokenPrice) {
            tokenPurchased = userCommitValue / totalCommitValue * self.totalProjectToken
        } else {
            tokenPurchased = userCommitValue / self.projectTokenPrice
        }
        return tokenPurchased
    }

    access(self) fun caculateValue(tokenBalance: {Type: TokenBalance}): UFix64 {
        var totalValue = 0.0
        let tokenPrice: {String: UFix64} = {}
        for tokenInfo in self.tokenInfos {
            if tokenInfo.price > 0.0 {
                tokenPrice[tokenInfo.tokenKey] = tokenInfo.price
            } else {
                let priceReaderSuggestedPath = getAccount(tokenInfo.oracleAccount).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()!.getPriceReaderStoragePath()
                /// local PriceReader reference
                let priceReaderRef  = RaisePool.account.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
                      ?? panic("Lost local price reader")
                let price = priceReaderRef.getMedianPrice()
                tokenPrice[tokenInfo.tokenKey] = tokenInfo.price
            }
        }
        for tokenType in tokenBalance.keys {
            let tokenBalance = tokenBalance[tokenType]!
            let tokenValue = tokenPrice[tokenBalance.tokenKey]! * tokenBalance.balance
            totalValue = totalValue + tokenValue

        }
        return totalValue
    }

    pub struct TokenInfo {
        pub let tokenKey: String
        access(self) let typeStr: String
        access(self) let storagePathStr: String
        pub let oracleAccount: Address
        pub let price: UFix64

        init(tokenKey: String, storagePath: String, oracleAccount: Address) {
            self.tokenKey = tokenKey
            self.typeStr = tokenKey.concat(".Vault")
            self.storagePathStr = storagePath
            self.oracleAccount = oracleAccount
            self.price = 0.0
        }

        pub fun getVaultType(): Type {
            return CompositeType(self.typeStr)!
        }

        pub fun getStoragePath(): StoragePath {
            return StoragePath(identifier: self.storagePathStr)!
        }

    }


    /** 
    user commits one of the supported tokens
    **/
    pub fun commit(commiterAddress: Address, token: @FungibleToken.Vault) {
        var poolVaultRef: &FungibleToken.Vault? = nil
        var tokenInfo: TokenInfo? = nil
        for element in self.tokenInfos {
            if token.isInstance(element.getVaultType()) {
                poolVaultRef = self.account.borrow<&FungibleToken.Vault>(from: element.getStoragePath())!
                tokenInfo = element
            }
        }
        if poolVaultRef != nil {
            self.depositToken(address: commiterAddress, token: <- token, tokenPool: poolVaultRef!, tokenKey: tokenInfo!.tokenKey, oracleAccount: tokenInfo!.oracleAccount)
        } else {
            panic(ErrorCode.encode(code: ErrorCode.Code.COMMITTED_TOKEN_NOT_SUPPORTED))
        }
    }

    pub resource PoolAdmin {
        /// set vault related fields for tokens to be committed
        pub fun setTokenVaultInfo(tokenKeyList: [String], pathStrList:[String], oracleAccountList: [Address]) {
            RaisePool.tokenInfos = []
            for index, tokenKey in tokenKeyList {
                let vaultStoragePath: StoragePath = StoragePath(identifier: pathStrList[index])!
                log(vaultStoragePath)
                log(RaisePool.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType().identifier)
                let tokenVaultInfo = TokenInfo(tokenKey: tokenKey, storagePath: pathStrList[index], oracleAccount: oracleAccountList[index])
                assert(RaisePool.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType().identifier == tokenVaultInfo.typeStr, message: ErrorCode.encode(code: ErrorCode.Code.VAULT_TYPE_MISMATCH))
                RaisePool.tokenInfos.append(tokenVaultInfo)
            }
        }

        pub fun setStartTimestamp(startTimestamp: UFix64) {
            RaisePool.startTimestamp = startTimestamp
        }

        pub fun setEndTimestamp(endTimestamp: UFix64) {
            RaisePool.endTimestamp = endTimestamp
        }

        pub fun setProjectInfo(projectName: String, tokenKey: String, tokenAmount: UFix64, tokenPrice: UFix64) {
            RaisePool.projectName = projectName
            RaisePool.projectTokenKey = tokenKey
            RaisePool.totalProjectToken = tokenAmount
            RaisePool.projectTokenPrice = tokenPrice
        }


    }

    access(self) fun depositToken(address: Address, token: @FungibleToken.Vault, tokenPool: &FungibleToken.Vault, tokenKey: String, oracleAccount: Address) {
        let type = token.getType()
        let addedBalance = token.balance
        tokenPool.deposit(from: <- token)
        let userTokenMap: {Type: TokenBalance} = self.userTokenBalance[address] ?? {}
        if let userTokenBalance = userTokenMap[type] {
            userTokenMap[type] = TokenBalance(tokenKey: tokenKey, balance: userTokenBalance.balance + addedBalance, oracleAccount: oracleAccount, account: address)
        } else {
            userTokenMap[type] = TokenBalance(tokenKey: tokenKey, balance: addedBalance, oracleAccount: oracleAccount, account: address)
        }
        self.userTokenBalance[address] = userTokenMap

        ///adjust token balance of the whole pool
        if let poolTokenBalance = self.poolTokenBalance[type] {
            let updatePoolTokenBalance = TokenBalance(tokenKey: tokenKey, balance: poolTokenBalance.balance + addedBalance, oracleAccount: oracleAccount, account: 0x0)
            self.poolTokenBalance[type] = updatePoolTokenBalance
        } else {
            let updatePoolTokenBalance = TokenBalance(tokenKey: tokenKey, balance: addedBalance, oracleAccount: oracleAccount, account: 0x0)
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
        self.tokenInfos = []
        self.userTokenBalance = {}
        self.startTimestamp = UFix64.max
        self.endTimestamp = UFix64.max
        self.poolTokenBalance = {}
        self.projectName = ""
        self.projectTokenKey = ""
        self.totalProjectToken = 0.0
        self.projectTokenPrice = 0.0
        
        self.account.save(<- create PoolAdmin(), to: self.AdminStorage)

    }
}
 