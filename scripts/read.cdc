import RaisePool from "../contracts/RaisePool.cdc"

pub fun main(): AnyStruct {
    // let addressList: [Address] = [0x1768d28ba059980c, 0x1ee2b5f2b0651aca, 0xf815b9a819d8ef4c]
    // let userDetailList: [AnyStruct] = []
    // for address in addressList {
    //     userDetailList.append(RaisePool.getUserCommitDetail(userAccount: address))
    // }
    // return userDetailList
    return RaisePool.totalProjectToken
}