

import RaisePool from "../contracts/RaisePool.cdc"
pub fun main(userAccount: Address): [{String: AnyStruct}] {
    return RaisePool.getUserCommitDetail(userAccount: userAccount)
}