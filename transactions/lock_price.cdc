import RaisePool from "../contracts/RaisePool.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
        admin.finalizeTokenPrice()
    }
}
 