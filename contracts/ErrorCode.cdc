

pub contract ErrorCode {
    pub enum Code: UInt8 {
        pub case VAULT_TYPE_MISMATCH
        pub case COMMIT_ADDRESS_NOT_EXIST
    }

    pub fun encode(code: Code): String {
        return "[Code: ".concat(code.rawValue.toString()).concat("]")
    }
    init() {
        log("ErrorCode deployed")
    }
}