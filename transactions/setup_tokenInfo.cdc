import RaisePool from "../contracts/RaisePool.cdc"

transaction(typeStrList: [String], pathStrList: [String], oracleAccountList: [Address]) {
    prepare(signer: AuthAccount) {
        signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!.setTokenVaultInfo(typeStrList: typeStrList, pathStrList: pathStrList, oracleAccountList: oracleAccountList)
    }
}