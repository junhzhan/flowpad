import ErrorCode from "./ErrorCode.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import StrUtility from "./StrUtility.cdc"
import OracleInterface from "./oracle/OracleInterface.cdc"
import OracleConfig from "./oracle/OracleConfig.cdc"
import RaisePoolInterface from "./RaisePoolInterface.cdc"

pub contract RaisePool {


    pub var tokenInfos: {String: TokenInfo}

    pub let AdminStorage: StoragePath

    pub let userTokenBalance: {Address: {String: TokenBalance}}

    pub var startTimestamp: UFix64

    pub var endTimestamp: UFix64

    pub var projectTokenPrice: UFix64


    pub var totalProjectToken: UFix64

    pub var projectName: String

    pub var projectTokenKey: String

    pub var projectTokenStoragePath: StoragePath?
    pub var projectTokenReceiverPath: PublicPath?
    pub var projectTokenBalancePath: PublicPath?

    pub var claimedProjectToken: UFix64

    pub let userClaimedProjectToken: {Address: UFix64}

    pub enum Status: UInt8 {
        pub case COMING_SOON
        pub case ONGOING
        pub case END
    }

    pub let poolTokenBalance: {String: TokenBalance}

    pub struct TokenBalance {
        pub let tokenKey: String
        pub let balance: UFix64
        pub let oracleAccount: Address
        pub let account: Address
        pub var claimedAmount: UFix64

        init(tokenKey: String, balance: UFix64, oracleAccount: Address, account: Address) {
            self.tokenKey = tokenKey
            self.balance = balance
            self.oracleAccount = oracleAccount
            self.account = account
            self.claimedAmount = 0.0
        }

        access(contract) fun setClaimedAmount(amount: UFix64) {
            self.claimedAmount = amount
        }
    }
    pub struct TokenInfo {
        pub let tokenKey: String
        pub let typeStr: String
        pub let storagePathStr: String
        pub let oracleAccount: Address
        pub let finalPrice: UFix64?

        init(tokenKey: String, storagePath: String, oracleAccount: Address, finalPrice: UFix64?) {
            self.tokenKey = tokenKey
            self.typeStr = tokenKey.concat(".Vault")
            self.storagePathStr = storagePath
            self.oracleAccount = oracleAccount
            self.finalPrice = finalPrice
        }

        pub fun getVaultType(): Type {
            return CompositeType(self.typeStr)!
        }

        pub fun getStoragePath(): StoragePath {
            return StoragePath(identifier: self.storagePathStr)!
        }

        pub fun getTokenPrice(): UFix64 {
            if self.finalPrice != nil {
                return self.finalPrice!
            } else {
                return RaisePool.readTokenPrice(oracleAccount: self.oracleAccount)
            }
        }

    }


    pub fun getUserCommitDetail(userAccount: Address): {String:AnyStruct} {
        if !self.userTokenBalance.containsKey(userAccount) {
            return {}
        }
        let userTokenBalance = self.userTokenBalance[userAccount]!
        let tokenList: [{String: AnyStruct}]= []

        let tokenSpent = self.getTokenSpent(userAccount: userAccount)
        
        for tokenKey in userTokenBalance.keys {
            let tokenBalance = userTokenBalance[tokenKey]! 
            let tokenKey = tokenBalance.tokenKey
            let balance = tokenBalance.balance
            let oracleAccount = tokenBalance.oracleAccount
            /// Recommended storage path for PriceReader resource
            let price = self.readTokenPrice(oracleAccount: oracleAccount)
            tokenList.append({"tokenKey": tokenKey, "amount": balance, "price": price, "spent": tokenSpent[tokenKey]!})
        }

        let userDetail: {String: AnyStruct}= {}
        let tokenPurchased = self.getTokenPurchased(userAccount: userAccount)
        userDetail["tokenPurchased"] = tokenPurchased
        userDetail["tokenCommitted"] = tokenList
        userDetail["remainToClaim"] = tokenPurchased - (self.userClaimedProjectToken[userAccount] ?? 0.0)
        return userDetail

    }

    pub fun getTokenSpent(userAccount: Address): {String: UFix64} {
        let userTokenBalance = self.userTokenBalance[userAccount]!
        var userCommmitValue = self.caculateValue(tokenBalance: userTokenBalance)
        var totalCommitValue: UFix64 = self.caculateValue(tokenBalance: self.poolTokenBalance)
        let tokenSpent: {String: UFix64} = {}
        if totalCommitValue > (self.totalProjectToken * self.projectTokenPrice) {
            for tokenKey in userTokenBalance.keys {
                tokenSpent[tokenKey] = userTokenBalance[tokenKey]!.balance * self.totalProjectToken * self.projectTokenPrice / totalCommitValue
            }
        } else {
            for tokenKey in userTokenBalance.keys {
                tokenSpent[tokenKey] = userTokenBalance[tokenKey]!.balance
            }
        }
        return tokenSpent

    }

    pub fun getTokenPurchased(userAccount: Address): UFix64 {
        if !self.userTokenBalance.containsKey(userAccount) {
            return 0.0
        }
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

    access(self) fun caculateValue(tokenBalance: {String: TokenBalance}): UFix64 {
        var totalValue = 0.0
        let tokenPrice: {String: UFix64} = {}
        for tokenKey in self.tokenInfos.keys {
            if let finalPrice = self.tokenInfos[tokenKey]!.finalPrice {
                tokenPrice[tokenKey] = finalPrice
            } else {
                let price = self.readTokenPrice(oracleAccount: self.tokenInfos[tokenKey]!.oracleAccount)
                tokenPrice[tokenKey] = price
            }
        }
        for tokenKey in tokenBalance.keys {
            let tokenBalance = tokenBalance[tokenKey]!
            let tokenValue = tokenPrice[tokenBalance.tokenKey]! * tokenBalance.balance
            totalValue = totalValue + tokenValue

        }
        return totalValue
    }

    


    /** 
    user commits one of the supported tokens
    **/
    pub fun commit(commiterAddress: Address, token: @FungibleToken.Vault) {
        let timestamp = getCurrentBlock().timestamp 
        assert(timestamp > self.startTimestamp && timestamp < self.endTimestamp, message: ErrorCode.encode(code: ErrorCode.Code.CURRENT_STATUS_NOT_ONGOING))

        var poolVaultRef: &FungibleToken.Vault? = nil
        var tokenInfo: TokenInfo? = nil
        for tokenKey in self.tokenInfos.keys {
            if token.isInstance(self.tokenInfos[tokenKey]!.getVaultType()) {
                poolVaultRef = self.account.borrow<&FungibleToken.Vault>(from: self.tokenInfos[tokenKey]!.getStoragePath())!
                tokenInfo = self.tokenInfos[tokenKey]!
            }
        }
        if poolVaultRef != nil {
            self.depositToken(address: commiterAddress, token: <- token, tokenPool: poolVaultRef!, tokenKey: tokenInfo!.tokenKey, oracleAccount: tokenInfo!.oracleAccount)
        } else {
            panic(ErrorCode.encode(code: ErrorCode.Code.COMMITTED_TOKEN_NOT_SUPPORTED))
        }
    }

    pub fun claim(certificateCap: Capability<&{RaisePoolInterface.Certificate}>): @{String: FungibleToken.Vault} {
        assert(getCurrentBlock().timestamp > self.endTimestamp, message: "You can't claimed now")
        assert(certificateCap.check(), message: "invalid capbility")
        let userAccount = certificateCap.borrow()!.owner!.address
        /// first, claim project token purchased
        let tokenCollection: @{String: FungibleToken.Vault} <- {}
        if let projectTokenVault <- self.claimProjectToken(userAccount: userAccount) {
            let existValue <-tokenCollection.insert(key: self.projectTokenKey, <- projectTokenVault)
            destroy existValue
        } else {

        }
        
        ///second claim unused committed token
        if let userTokenBalance = self.userTokenBalance[userAccount] {
            let tokenSpent = self.getTokenSpent(userAccount: userAccount)
            for tokenKey in userTokenBalance.keys {
                let tokenBalance = userTokenBalance[tokenKey]!
                let toClaimAmount = tokenBalance.balance - tokenSpent[tokenKey]!
                if tokenBalance.claimedAmount > 0.0 || toClaimAmount <= 0.0 {
                    continue
                }
                let tokenInfo = self.tokenInfos[tokenKey]!
                let vault <- self.account.borrow<&FungibleToken.Vault>(from: tokenInfo.getStoragePath())!.withdraw(amount: toClaimAmount)
                let existValue <- tokenCollection.insert(key: tokenKey, <- vault)
                destroy existValue
                tokenBalance.setClaimedAmount(amount: toClaimAmount)
                userTokenBalance[tokenKey] = tokenBalance
                let poolTokenBalance = self.poolTokenBalance[tokenKey]!
                poolTokenBalance.setClaimedAmount(amount: poolTokenBalance.claimedAmount + toClaimAmount)
                self.poolTokenBalance[tokenKey] = poolTokenBalance
            }
            self.userTokenBalance[userAccount] = userTokenBalance
        } else {

        }

        return <- tokenCollection
    }

    access(self) fun claimProjectToken(userAccount: Address): @FungibleToken.Vault? {
        let tokenPurchased = self.getTokenPurchased(userAccount: userAccount)
        if self.userClaimedProjectToken.containsKey(userAccount) {
            return nil
        }
        if tokenPurchased > 0.0 {
            let vault <- self.account.borrow<&FungibleToken.Vault>(from: self.projectTokenStoragePath!)!.withdraw(amount: tokenPurchased)
            self.claimedProjectToken = self.claimedProjectToken + tokenPurchased
            self.userClaimedProjectToken[userAccount] = tokenPurchased
            return <- vault
        } else {
            return nil
        }

    }


    pub resource PoolAdmin {
        /// set vault related fields for tokens to be committed
        pub fun setTokenVaultInfo(tokenKeyList: [String], pathStrList:[String], oracleAccountList: [Address]) {
            RaisePool.tokenInfos = {}
            for index, tokenKey in tokenKeyList {
                let vaultStoragePath: StoragePath = StoragePath(identifier: pathStrList[index])!
                log(vaultStoragePath)
                log(RaisePool.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType().identifier)
                let tokenInfo = TokenInfo(tokenKey: tokenKey, storagePath: pathStrList[index], oracleAccount: oracleAccountList[index], finalPrice: nil)
                assert(RaisePool.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType() == tokenInfo.getVaultType(), message: ErrorCode.encode(code: ErrorCode.Code.VAULT_TYPE_MISMATCH))
                RaisePool.tokenInfos.insert(key: tokenKey, tokenInfo)
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

        pub fun setTokenPath(tokenStoragePath: StoragePath, receiverPath: PublicPath, balancePath: PublicPath) {
            let vaultRef = RaisePool.account.borrow<&FungibleToken.Vault>(from: tokenStoragePath)!
            assert(vaultRef.getType() == CompositeType(RaisePool.projectTokenKey.concat(".Vault")), message: ErrorCode.encode(code: ErrorCode.Code.VAULT_TYPE_MISMATCH))
            assert(vaultRef.balance >= RaisePool.totalProjectToken, message: "project token amount mismatch")
            RaisePool.projectTokenStoragePath = tokenStoragePath
            RaisePool.projectTokenReceiverPath = receiverPath
            RaisePool.projectTokenBalancePath = balancePath
        }

        pub fun finalizeTokenPrice() {
            let tokenInfos = RaisePool.tokenInfos
            for tokenKey in tokenInfos.keys {
                let price = RaisePool.readTokenPrice(oracleAccount: tokenInfos[tokenKey]!.oracleAccount)
                RaisePool.tokenInfos.insert(key: tokenKey, TokenInfo(tokenKey: tokenInfos[tokenKey]!.tokenKey, storagePath: tokenInfos[tokenKey]!.storagePathStr, oracleAccount: tokenInfos[tokenKey]!.oracleAccount, finalPrice: price))
            }
        }


    }

    access(self) fun depositToken(address: Address, token: @FungibleToken.Vault, tokenPool: &FungibleToken.Vault, tokenKey: String, oracleAccount: Address) {
        let addedBalance = token.balance
        tokenPool.deposit(from: <- token)
        let userTokenMap: {String: TokenBalance} = self.userTokenBalance[address] ?? {}
        if let userTokenBalance = userTokenMap[tokenKey] {
            userTokenMap[tokenKey] = TokenBalance(tokenKey: tokenKey, balance: userTokenBalance.balance + addedBalance, oracleAccount: oracleAccount, account: address)
        } else {
            userTokenMap[tokenKey] = TokenBalance(tokenKey: tokenKey, balance: addedBalance, oracleAccount: oracleAccount, account: address)
        }
        self.userTokenBalance[address] = userTokenMap

        ///adjust token balance of the whole pool
        if let poolTokenBalance = self.poolTokenBalance[tokenKey] {
            let updatePoolTokenBalance = TokenBalance(tokenKey: tokenKey, balance: poolTokenBalance.balance + addedBalance, oracleAccount: oracleAccount, account: 0x0)
            self.poolTokenBalance[tokenKey] = updatePoolTokenBalance
        } else {
            let updatePoolTokenBalance = TokenBalance(tokenKey: tokenKey, balance: addedBalance, oracleAccount: oracleAccount, account: 0x0)
            self.poolTokenBalance[tokenKey] = updatePoolTokenBalance
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
        self.tokenInfos = {}
        self.userTokenBalance = {}
        self.startTimestamp = UFix64.max
        self.endTimestamp = UFix64.max
        self.poolTokenBalance = {}
        self.projectName = ""
        self.projectTokenKey = ""
        self.totalProjectToken = 0.0
        self.projectTokenPrice = 0.0
        self.projectTokenStoragePath = nil
        self.projectTokenReceiverPath = nil
        self.projectTokenBalancePath = nil
        self.claimedProjectToken = 0.0
        self.userClaimedProjectToken = {}
        
        self.account.save(<- create PoolAdmin(), to: self.AdminStorage)

    }
}
 