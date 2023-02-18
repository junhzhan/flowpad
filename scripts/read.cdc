
import RaisePool from "../contracts/RaisePool.cdc"
pub fun main(): [{String: AnyStruct}]{
    return RaisePool.getUserCommitDetail(userAccount: 0xf8d6e0586b0a20c7)

}