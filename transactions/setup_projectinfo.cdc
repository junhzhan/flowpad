import RaisePool from "../contracts/RaisePool.cdc"

transaction(cvsdTokenAddress: String) {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
        admin.setProjectInfo(projectName: "Cat VS Dog", tokenKey: "A.".concat(cvsdTokenAddress).concat(".CVSDToken"), tokenAmount: 10_0000.0, tokenPrice: 0.005)
        admin.setStartTimestamp(startTimestamp: 1677229200.0)
        admin.setEndTimestamp(endTimestamp: 1677254400.0)

        admin.setTokenPath(tokenStoragePath: /storage/cvsdTokenVault, receiverPath: /public/cvsdReceiver, balancePath: /public/cvsdBalance)
    }
}
 