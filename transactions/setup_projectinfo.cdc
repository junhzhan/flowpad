import RaisePool from "../contracts/RaisePool.cdc"

transaction(tokenKeyList: [String], pathStrList: [String], oracleAccountList: [Address]) {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
        admin.setProjectInfo(projectName: "Cat VS Dog", tokenKey: "A.0xe03daebed8ca0615.CVSDToken", tokenAmount: 200_0000.0, tokenPrice: 0.005)
        admin.setStartTimestamp(startTimestamp: 1677045600.0)
        admin.setEndTimestamp(endTimestamp: 1677067200.0)
    }
}