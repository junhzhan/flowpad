
import OracleInterface from "../contracts/oracle/OracleInterface.cdc"
import OracleConfig from "../contracts/oracle/OracleConfig.cdc"

transaction(typeStrList: [String], storagePathList: [String], oracleAccountList: [Address]) {
    prepare(account: AuthAccount) {
        /// Flow/USD address is 0xcbdb5a7b89c3c844
        /// Oracle contract's interface
        for oracleAddress in oracleAccountList {
            let oracleRef = getAccount(oracleAddress).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
                ?? panic("Lost oracle public capability")
                /// mint PriceReader resource
            let priceReader <- oracleRef.mintPriceReader()
            /// Recommended storage path for PriceReader resource
            let priceReaderSuggestedPath = oracleRef.getPriceReaderStoragePath()
            /// Save PriceReader resource in local storage
            account.save(<- priceReader, to: priceReaderSuggestedPath)
        }
    }
}