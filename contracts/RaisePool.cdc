// import ErrorCode from 0xa7b34370a65fb516
// import FungibleToken from 0x9a0766d93b6608b7
// import StrUtility from 0xa7b34370a65fb516
// import OracleInterface from 0x2a9b59c3e2b72ee0
// import OracleConfig from 0x2a9b59c3e2b72ee0
// import RaisePoolInterface from 0xa7b34370a65fb516
// import SwapFactory from 0xcbed4c301441ded2
// import SwapError from 0xddb929038d45d4b3
// import SwapConfig from 0xddb929038d45d4b3
// import SwapInterfaces from 0xddb929038d45d4b3
import ErrorCode from "./ErrorCode.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import StrUtility from "./StrUtility.cdc"
import OracleInterface from "./oracle/OracleInterface.cdc"
import OracleConfig from "./oracle/OracleConfig.cdc"
import RaisePoolInterface from "./RaisePoolInterface.cdc"
import SwapFactory from "./incrementFi/SwapFactory.cdc"
import SwapInterfaces from "./incrementFi/SwapInterfaces.cdc"
import SwapConfig from "./incrementFi/SwapConfig.cdc"
import SwapError from "./incrementFi/SwapError.cdc"

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

    pub let projectOwnerAddress: Address

    pub let addLiquidityRatio: UFix64

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
            let price = self.tokenInfos[tokenKey]!.getTokenPrice()
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

    pub fun projectClaim(certificateCap: Capability<&{RaisePoolInterface.Certificate}>): @{String: FungibleToken.Vault} {
        assert(certificateCap.borrow()!.owner!.address == self.projectOwnerAddress, message: "You don't have the permission to claim raised tokens")
        var totalCommitValue: UFix64 = self.caculateValue(tokenBalance: self.poolTokenBalance)
        let targetRaiseValue = self.totalProjectToken * self.projectTokenPrice
        let projectClaimRatio = totalCommitValue <= targetRaiseValue ? 1.0 : targetRaiseValue / totalCommitValue
        let claimedTokenVaults: @{String: FungibleToken.Vault} <- {}
        for tokenKey in self.poolTokenBalance.keys {
            let tokenInfo = self.tokenInfos[tokenKey]!
            let tokenBalance = self.poolTokenBalance[tokenKey]!
            let strParts = StrUtility.splitStr(str: tokenKey, delimiter: ".")
            let tokenAddr = StrUtility.toAddress(from: strParts[1])
            let tokenName = strParts[2]
            var tokenClaimAmount = 0.0
            if tokenName == "FlowToken" {
                let projectTokenKeyParts = StrUtility.splitStr(str: self.projectTokenKey, delimiter: ".")
                let projectTokenName = projectTokenKeyParts[2]
                let projectTokenAddr = StrUtility.toAddress(from: projectTokenKeyParts[1])
                self.createSwapPair(token0Name: tokenName, token0Addr: tokenAddr, token1Name: projectTokenName, token1Addr: projectTokenAddr)
                let token0InAmount = tokenBalance.balance * projectClaimRatio * self.addLiquidityRatio
                let projectTokenInAmount = token0InAmount * tokenInfo.getTokenPrice() / self.projectTokenPrice
                self.addLiquidity(token0Key: tokenKey, token1Key: self.projectTokenKey, token0InDesired: token0InAmount, token1InDesired: projectTokenInAmount, token0InMin: 0.99 * token0InAmount, token1InMin: 0.99 * projectTokenInAmount, token0VaultPath: tokenInfo.getStoragePath(), token1VaultPath: self.projectTokenStoragePath!)
                tokenClaimAmount = tokenBalance.balance * projectClaimRatio * (1.0 - self.addLiquidityRatio)
            } else {
                tokenClaimAmount = tokenBalance.balance * projectClaimRatio
            }

            let existValue <- claimedTokenVaults.insert(key: tokenKey, <- self.account.borrow<&FungibleToken.Vault>(from: tokenInfo.getStoragePath())!.withdraw(amount: tokenClaimAmount))
            destroy existValue
        }
        return <- claimedTokenVaults
    }

    access(self) fun createSwapPair(token0Name: String, token0Addr: Address, token1Name: String, token1Addr: Address) {
        let flowVaultRef = self.account.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)!
        assert(flowVaultRef.balance >= 0.002, message: "Insufficient balance to create pair, minimum balance requirement: 0.002 flow")
        let accountCreationFeeVault <- flowVaultRef.withdraw(amount: 0.001)
        
        let token0Vault <- getAccount(token0Addr).contracts.borrow<&FungibleToken>(name: token0Name)!.createEmptyVault()
        let token1Vault <- getAccount(token1Addr).contracts.borrow<&FungibleToken>(name: token1Name)!.createEmptyVault()
        SwapFactory.createPair(token0Vault: <-token0Vault, token1Vault: <-token1Vault, accountCreationFee: <-accountCreationFeeVault)
    }

    access(self) fun addLiquidity(token0Key: String, token1Key: String, token0InDesired: UFix64, token1InDesired: UFix64, token0InMin: UFix64, token1InMin: UFix64, token0VaultPath: StoragePath, token1VaultPath: StoragePath) {
        let pairAddr = SwapFactory.getPairAddress(token0Key: token0Key, token1Key: token1Key)
            ?? panic("AddLiquidity: nonexistent pair ".concat(token0Key).concat(" <-> ").concat(token1Key).concat(", create pair first"))
        let pairPublicRef = getAccount(pairAddr).getCapability<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!
        /*
            pairInfo = [
                SwapPair.token0Key,
                SwapPair.token1Key,
                SwapPair.token0Vault.balance,
                SwapPair.token1Vault.balance,
                SwapPair.account.address,
                SwapPair.totalSupply
            ]
        */
        let pairInfo = pairPublicRef.getPairInfo()
        var token0In = 0.0
        var token1In = 0.0
        var token0Reserve = 0.0
        var token1Reserve = 0.0
        if token0Key == (pairInfo[0] as! String) {
            token0Reserve = (pairInfo[2] as! UFix64)
            token1Reserve = (pairInfo[3] as! UFix64)
        } else {
            token0Reserve = (pairInfo[3] as! UFix64)
            token1Reserve = (pairInfo[2] as! UFix64)
        }
        if token0Reserve == 0.0 && token1Reserve == 0.0 {
            token0In = token0InDesired
            token1In = token1InDesired
        } else {
            var amount1Optimal = SwapConfig.quote(amountA: token0InDesired, reserveA: token0Reserve, reserveB: token1Reserve)
            if (amount1Optimal <= token1InDesired) {
                assert(amount1Optimal >= token1InMin, message:
                    SwapError.ErrorEncode(
                        msg: "SLIPPAGE_OFFSET_TOO_LARGE expect min".concat(token1InMin.toString()).concat(" got ").concat(amount1Optimal.toString()),
                        err: SwapError.ErrorCode.SLIPPAGE_OFFSET_TOO_LARGE
                    )
                )
                token0In = token0InDesired
                token1In = amount1Optimal
            } else {
                var amount0Optimal = SwapConfig.quote(amountA: token1InDesired, reserveA: token1Reserve, reserveB: token0Reserve)
                assert(amount0Optimal <= token0InDesired)
                assert(amount0Optimal >= token0InMin, message:
                    SwapError.ErrorEncode(
                        msg: "SLIPPAGE_OFFSET_TOO_LARGE expect min".concat(token0InMin.toString()).concat(" got ").concat(amount0Optimal.toString()),
                        err: SwapError.ErrorCode.SLIPPAGE_OFFSET_TOO_LARGE
                    )
                )
                token0In = amount0Optimal
                token1In = token1InDesired
            }
        }
        
        let token0Vault <- self.account.borrow<&FungibleToken.Vault>(from: token0VaultPath)!.withdraw(amount: token0In)
        let token1Vault <- self.account.borrow<&FungibleToken.Vault>(from: token1VaultPath)!.withdraw(amount: token1In)
        let lpTokenVault <- pairPublicRef.addLiquidity(
            tokenAVault: <- token0Vault,
            tokenBVault: <- token1Vault
        )
        
        let lpTokenCollectionStoragePath = SwapConfig.LpTokenCollectionStoragePath
        let lpTokenCollectionPublicPath = SwapConfig.LpTokenCollectionPublicPath
        var lpTokenCollectionRef = self.account.borrow<&SwapFactory.LpTokenCollection>(from: lpTokenCollectionStoragePath)
        if lpTokenCollectionRef == nil {
            destroy <- self.account.load<@AnyResource>(from: lpTokenCollectionStoragePath)
            self.account.save(<-SwapFactory.createEmptyLpTokenCollection(), to: lpTokenCollectionStoragePath)
            self.account.link<&{SwapInterfaces.LpTokenCollectionPublic}>(lpTokenCollectionPublicPath, target: lpTokenCollectionStoragePath)
            lpTokenCollectionRef = self.account.borrow<&SwapFactory.LpTokenCollection>(from: lpTokenCollectionStoragePath)
        }
        lpTokenCollectionRef!.deposit(pairAddr: pairAddr, lpTokenVault: <- lpTokenVault)
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

        pub fun setStartTimestamp(startTimestamp: UFix64) {
            RaisePool.startTimestamp = startTimestamp
        }

        pub fun setEndTimestamp(endTimestamp: UFix64) {
            RaisePool.endTimestamp = endTimestamp
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

    ///read token price from price oracle
    access(self) fun readTokenPrice(oracleAccount: Address): UFix64 {
        let priceReaderSuggestedPath = getAccount(oracleAccount).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()!.getPriceReaderStoragePath()
        let priceReaderRef  = self.account.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
                      ?? panic("Lost local price reader")
        let price = priceReaderRef.getMedianPrice()
        return price
    }

    init(tokenKeyList: [String], 
        pathStrList:[String], 
        oracleAccountList: [Address], 
        projectName: String, 
        projectTokenKey: String, 
        tokenAmount: UFix64, 
        tokenPrice: UFix64, 
        tokenStoragePath: StoragePath, 
        receiverPath: PublicPath, 
        balancePath: PublicPath,
        projectOwnerAddress: Address,
        addLiquidityRatio: UFix64) {
        self.tokenInfos = {}
        for index, tokenKey in tokenKeyList {
            let vaultStoragePath: StoragePath = StoragePath(identifier: pathStrList[index])!
            log(vaultStoragePath)
            log(RaisePool.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType().identifier)
            let tokenInfo = TokenInfo(tokenKey: tokenKey, storagePath: pathStrList[index], oracleAccount: oracleAccountList[index], finalPrice: nil)
            assert(RaisePool.account.borrow<&FungibleToken.Vault>(from: vaultStoragePath)!.getType() == tokenInfo.getVaultType(), message: ErrorCode.encode(code: ErrorCode.Code.VAULT_TYPE_MISMATCH))
            self.tokenInfos.insert(key: tokenKey, tokenInfo)
        }

        let projectTokenVault = self.account.borrow<&FungibleToken.Vault>(from: tokenStoragePath)!
        assert(projectTokenVault.getType() == CompositeType(projectTokenKey.concat("Vault")), message: ErrorCode.encode(code: ErrorCode.Code.VAULT_TYPE_MISMATCH))
        assert(projectTokenVault.balance >= tokenAmount * (1.0 + addLiquidityRatio), message: "Project token amount is not enough")
        self.AdminStorage = /storage/flowpadAdmin
        self.userTokenBalance = {}
        self.startTimestamp = UFix64.max
        self.endTimestamp = UFix64.max
        self.poolTokenBalance = {}
        self.projectName = projectName
        self.projectTokenKey = projectTokenKey
        self.totalProjectToken = tokenAmount
        self.projectTokenPrice = tokenPrice
        self.projectTokenStoragePath = tokenStoragePath
        self.projectTokenReceiverPath = receiverPath
        self.projectTokenBalancePath = balancePath
        self.claimedProjectToken = 0.0
        self.userClaimedProjectToken = {}
        self.projectOwnerAddress = projectOwnerAddress
        self.addLiquidityRatio = addLiquidityRatio
        
        self.account.save(<- create PoolAdmin(), to: self.AdminStorage)

    }
}
 