
import RaisePool from "../contracts/RaisePool.cdc"
transaction {
    prepare(signer: AuthAccount) {
        let admin = signer.borrow<&RaisePool.PoolAdmin>(from: RaisePool.AdminStorage)!
        admin.setEndTimestamp(endTimestamp: getCurrentBlock().timestamp - 3600.0)
        admin.finalizeTokenPrice()
    }
}