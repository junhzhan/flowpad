import SwapFactory from 0xcbed4c301441ded2
pub fun main(token0Key:String ,token1Key:String): AnyStruct? {
        return SwapFactory.getPairInfo(token0Key: token0Key, token1Key: token1Key)
}