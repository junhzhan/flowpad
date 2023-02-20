import RaisePool from "../contracts/RaisePool.cdc"

transaction(tokenKeyList: [String], pathStrList: [String], oracleAccountList: [Address]) {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
        admin.setProjectInfo(projectName: "Cat VS Dog", tokenKey: "A.f4a4c2b1fdfcb72f.CVSDToken", tokenAmount: 200_0000.0, tokenPrice: 0.005)
        admin.setStartTimestamp(startTimestamp: 1676901600.0)
        admin.setEndTimestamp(endTimestamp: 1676908800.0)
    }
}