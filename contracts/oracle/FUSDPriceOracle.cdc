import OracleInterface from "./OracleInterface.cdc"
import OracleConfig from "./OracleConfig.cdc"

pub contract FUSDPriceOracle: OracleInterface {

    pub event MintPriceReader()
    pub event MintPriceFeeder()

    pub let _OraclePublicStoragePath: StoragePath

    pub resource PriceReader {
        /// Get the median price of all current feeds.
        ///
        /// @Return Median price, returns 0.0 if the current price is invalid
        ///
        pub fun getMedianPrice(): UFix64 {
            return 1.0
        }
    }

    pub resource PriceFeeder: OracleInterface.PriceFeederPublic {
        /// The feeder uses this function to offer price at the price panel
        ///
        /// Param price - price from off-chain
        ///
        pub fun publishPrice(price: UFix64) {

        }

        /// Set valid duration of price. If there is no update within the duration, the price will be expired.
        ///
        /// Param blockheightDuration by the block numbers
        ///
        pub fun setExpiredDuration(blockheightDuration: UInt64) {

        }

        pub fun fetchPrice(certificate: &OracleInterface.OracleCertificate): UFix64 {
            return 0.0
        }
        init() {}
    }

    pub resource OracleCertificate: OracleInterface.IdentityCertificate {}

    pub resource OraclePublic: OracleInterface.OraclePublicInterface_Reader, OracleInterface.OraclePublicInterface_Feeder {
        /// Users who need to read the oracle price should mint this resource and save locally.
        ///
        pub fun mintPriceReader(): @PriceReader {
            emit MintPriceReader()

            return <- create PriceReader()
        }

        /// Feeders need to mint their own price panels and expose the exact public path to oracle contract
        ///
        /// @Return Resource of price panel
        ///
        pub fun mintPriceFeeder(): @PriceFeeder {
            emit MintPriceFeeder()

            return <- create PriceFeeder()
        }

        /// Recommended path for PriceReader, users can manage resources by themselves
        ///
        pub fun getPriceReaderStoragePath(): StoragePath { return /storage/emulator_price_reader_fusd}

        /// The oracle contract will get the feeding-price based on this path
        /// Feeders need to expose their price panel capabilities at this public path
        pub fun getPriceFeederStoragePath(): StoragePath {
            return /storage/emulator_price_feeder
        }
        pub fun getPriceFeederPublicPath(): PublicPath {
            return /public/emulator_price_feeder
        }
    }

    init() {
        self._OraclePublicStoragePath = /storage/oralce_public
        self.account.save(<-create OraclePublic(), to: self._OraclePublicStoragePath)
        self.account.link<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath, target: self._OraclePublicStoragePath)
        self.account.link<&{OracleInterface.OraclePublicInterface_Feeder}>(OracleConfig.OraclePublicInterface_FeederPath, target: self._OraclePublicStoragePath)

    }
}