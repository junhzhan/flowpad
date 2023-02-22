import RaisePool from "../contracts/RaisePool.cdc"

transaction(cvsdTokenAddress: String) {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
        admin.setProjectInfo(projectName: "Cat VS Dog", tokenKey: "A.".concat(cvsdTokenAddress).concat(".CVSDToken"), tokenAmount: 200_0000.0, tokenPrice: 0.005)
        admin.setStartTimestamp(startTimestamp: 1677045600.0)
        admin.setEndTimestamp(endTimestamp: 1676944800.0)
        admin.setTokenStoragePath(tokenStoragePath: /storage/cvsdTokenVault)
    }
}