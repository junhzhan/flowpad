
import OracleInterface from "../contracts/oracle/OracleInterface.cdc"
import OracleConfig from "../contracts/oracle/OracleConfig.cdc"

transaction {
    prepare(account: AuthAccount) {
        /// Flow/USD address is 0xcbdb5a7b89c3c844
        let oracleAddr: Address = 0x045a1763c93006ca
        /// Oracle contract's interface
        let oracleRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
                ?? panic("Lost oracle public capability")
        /// mint PriceReader resource
        let priceReader <- oracleRef.mintPriceReader()
        /// Recommended storage path for PriceReader resource
        let priceReaderSuggestedPath = oracleRef.getPriceReaderStoragePath()
        /// Save PriceReader resource in local storage
        account.save(<- priceReader, to: priceReaderSuggestedPath)
    }
}