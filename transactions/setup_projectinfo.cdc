import RaisePool from "../contracts/RaisePool.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
        admin.setStartTimestamp(startTimestamp: 1677499200.0)
        admin.setEndTimestamp(endTimestamp: 1677513600.0)
    }
}
 