

import RaisePool from "../contracts/RaisePool.cdc"
pub fun main(): {String: AnyStruct} {
    let projectInfo: {String: AnyStruct} = {}
    projectInfo["projectName"] = RaisePool.projectTokenName
    projectInfo["startTimestamp"] = RaisePool.startTimestamp
    projectInfo["endTimestamp"] = RaisePool.endTimestamp
    let blockTimestamp = getCurrentBlock().timestamp
    if blockTimestamp < RaisePool.startTimestamp {
        projectInfo["status"] = RaisePool.Status.COMING_SOON.rawValue
    } else if blockTimestamp > RaisePool.startTimestamp && blockTimestamp < RaisePool.endTimestamp {
        projectInfo["status"] = RaisePool.Status.ONGOING.rawValue
    } else {
        projectInfo["status"] = RaisePool.Status.END.rawValue
    }
    projectInfo["targetRaise"] = RaisePool.totalProjectToken
    projectInfo["tokenPrice"] = RaisePool.projectTokenPrice
    let poolTokenBalance = RaisePool.poolTokenBalance
    
    let totalRaise: [{String: AnyStruct}] = []
    for tokenType in poolTokenBalance.keys {
        let tokenBalance = poolTokenBalance[tokenType]!
        totalRaise.append({
            "tokenKey": tokenBalance.vaultType.identifier,
            "amount": tokenBalance.balance,
            "price": tokenBalance.getTokenPrice()
        })
    }
    return projectInfo

}