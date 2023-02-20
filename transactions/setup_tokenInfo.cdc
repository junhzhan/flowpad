import RaisePool from "../contracts/RaisePool.cdc"

transaction(tokenKeyList: [String], pathStrList: [String], oracleAccountList: [Address]) {
    prepare(signer: AuthAccount) {
        signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!.setTokenVaultInfo(tokenKeyList: tokenKeyList, pathStrList: pathStrList, oracleAccountList: oracleAccountList)
    }
}