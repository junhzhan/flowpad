
pub contract ErrorCode {
    pub enum Code: UInt8 {
        pub case VAULT_TYPE_MISMATCH
        pub case COMMIT_ADDRESS_NOT_EXIST
        pub case COMMITTED_TOKEN_NOT_SUPPORTED
        pub case CURRENT_STATUS_NOT_ONGOING
    }

    pub fun encode(code: Code): String {
        return "[Code: ".concat(code.rawValue.toString()).concat("]")
    }
    init() {
        log("ErrorCode deployed")
    }
}