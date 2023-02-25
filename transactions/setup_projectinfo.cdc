import RaisePool from "../contracts/RaisePool.cdc"

transaction(cvsdTokenAddress: String) {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
<<<<<<< HEAD
        admin.setProjectInfo(projectName: "Cat VS Dog", tokenKey: "A.".concat(cvsdTokenAddress).concat(".CVSDTokenV2"), tokenAmount: 10_0000.0, tokenPrice: 0.005)
        admin.setStartTimestamp(startTimestamp: 1677308400.0)
        admin.setEndTimestamp(endTimestamp: 1677340800.0)
=======
        admin.setProjectInfo(projectName: "Cat VS Dog", tokenKey: "A.".concat(cvsdTokenAddress).concat(".CVSDToken"), tokenAmount: 10_0000.0, tokenPrice: 0.005)
        admin.setStartTimestamp(startTimestamp: 1677229200.0)
        admin.setEndTimestamp(endTimestamp: 1677254400.0)
>>>>>>> 0bf6be378f034dacdc74596e8b24b7c5b4de66c1

        admin.setTokenPath(tokenStoragePath: /storage/cvsdTokenVault, receiverPath: /public/cvsdReceiver, balancePath: /public/cvsdBalance)
    }
}
 