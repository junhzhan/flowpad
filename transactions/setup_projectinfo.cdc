import RaisePool from "../contracts/RaisePool.cdc"

transaction(typeStrList: [String], pathStrList: [String], oracleAccountList: [Address]) {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
        admin.setProjectInfo(tokenName: "CVSD", tokenAmount: 200_0000.0, tokenPrice: 0.005)
        admin.setStartTimestamp(startTimestamp: 1676881278.0)
        admin.setEndTimestamp(endTimestamp: 1676884878.0)
    }
}