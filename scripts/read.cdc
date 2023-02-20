
import RaisePool from "../contracts/RaisePool.cdc"
pub fun main(): [{String: AnyStruct}]{
    return RaisePool.getUserCommitDetail(userAccount: 0x1768d28ba059980c)

}