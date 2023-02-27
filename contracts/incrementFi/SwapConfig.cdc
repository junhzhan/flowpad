pub contract SwapConfig {
    pub var PairPublicPath: PublicPath
;    pub var LpTokenCollectionStoragePath: StoragePath
;    pub var LpTokenCollectionPublicPath: PublicPath
;    pub let scaleFactor: UInt256
;    pub let ufixScale: UFix64
;    pub let ufix64NonZeroMin: UFix64
;    access(self) let _reservedFields: {String: AnyStruct}
;    pub fun UFix64ToScaledUInt256(_ f: UFix64): UInt256 {
        let integral = UInt256(f)
;        let fractional = f % 1.0
;        let ufixScaledInteger =  integral * UInt256(self.ufixScale) + UInt256(fractional * self.ufixScale)
;        return ufixScaledInteger * self.scaleFactor / UInt256(self.ufixScale)
    }
;    pub fun ScaledUInt256ToUFix64(_ scaled: UInt256): UFix64 {
        let integral = scaled / self.scaleFactor
;        let ufixScaledFractional = (scaled % self.scaleFactor) * UInt256(self.ufixScale) / self.scaleFactor
;        return UFix64(integral) + (UFix64(ufixScaledFractional) / self.ufixScale)
    }
;    pub fun SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: String): String {
        return vaultTypeIdentifier.slice(
            from: 0,
            upTo: vaultTypeIdentifier.length - 6
        )
    }
;    pub fun sqrt(_ x: UInt256): UInt256 {
        var res: UInt256 = 0
;        var one: UInt256 = self.scaleFactor
;        if (x > 0) {
            var x0 = x
;            var mid = (x + one) / 2
;            while ((x0 > mid + 1) || (mid > x0 + 1)) {
                x0 = mid

                mid = (x0 + x * self.scaleFactor / x0) / 2
            }

            res = mid
        } else {
            res = 0
        }        
;        return res
    }
;    pub fun getAmountOut(amountIn: UFix64, reserveIn: UFix64, reserveOut: UFix64): UFix64 {
        pre {
            amountIn > 0.0: "SwapPair: insufficient input amount"

            reserveIn > 0.0 && reserveOut > 0.0: "SwapPair: insufficient liquidity"
        }
;        let amountInScaled = SwapConfig.UFix64ToScaledUInt256(amountIn)
;        let reserveInScaled = SwapConfig.UFix64ToScaledUInt256(reserveIn)
;        let reserveOutScaled = SwapConfig.UFix64ToScaledUInt256(reserveOut)
;        let amountInWithFeeScaled = SwapConfig.UFix64ToScaledUInt256(0.997) * amountInScaled / SwapConfig.scaleFactor
;        let amountOutScaled = amountInWithFeeScaled * reserveOutScaled / (reserveInScaled + amountInWithFeeScaled)
;        return SwapConfig.ScaledUInt256ToUFix64(amountOutScaled)
    }
;    pub fun getAmountIn(amountOut: UFix64, reserveIn: UFix64, reserveOut: UFix64): UFix64 {
        pre {
            amountOut < reserveOut: "SwapPair: insufficient output amount"

            reserveIn > 0.0 && reserveOut > 0.0: "SwapPair: insufficient liquidity"
        }
;        let amountOutScaled = SwapConfig.UFix64ToScaledUInt256(amountOut)
;        let reserveInScaled = SwapConfig.UFix64ToScaledUInt256(reserveIn)
;        let reserveOutScaled = SwapConfig.UFix64ToScaledUInt256(reserveOut)
;        let amountInScaled = amountOutScaled * reserveInScaled / (reserveOutScaled - amountOutScaled) * SwapConfig.scaleFactor / SwapConfig.UFix64ToScaledUInt256(0.997)
;        return SwapConfig.ScaledUInt256ToUFix64(amountInScaled) + SwapConfig.ufix64NonZeroMin
    }
;    pub fun quote(amountA: UFix64, reserveA: UFix64, reserveB: UFix64): UFix64 {
        pre {
            amountA > 0.0: "SwapPair: insufficient input amount"

            reserveB > 0.0 && reserveB > 0.0: "SwapPair: insufficient liquidity"
        }
;        let amountAScaled = SwapConfig.UFix64ToScaledUInt256(amountA)
;        let reserveAScaled = SwapConfig.UFix64ToScaledUInt256(reserveA)
;        let reserveBScaled = SwapConfig.UFix64ToScaledUInt256(reserveB)
;        var amountBScaled = amountAScaled * reserveBScaled / reserveAScaled
;        return SwapConfig.ScaledUInt256ToUFix64(amountBScaled)
    }
;    init() {
        self.PairPublicPath = /public/increment_swap_pair
;        self.LpTokenCollectionStoragePath = /storage/increment_swap_lptoken_collection1
;        self.LpTokenCollectionPublicPath  = /public/increment_swap_lptoken_collection1
;        self.scaleFactor = 1_000_000_000_000_000_000
;        self.ufixScale = 100_000_000.0
;        self.ufix64NonZeroMin = 0.00000001
;        self._reservedFields = {}
    }
}