import FungibleToken from "../contracts/standard/FungibleToken.cdc"
transaction() {
    prepare(auth: AuthAccount) {
        let vaultRef = auth.borrow<&FungibleToken.Vault>(from: /storage/fusdVault)!
    }
}