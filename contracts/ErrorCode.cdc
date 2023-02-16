

pub contract ErrorCode {
    pub enum Code: UInt8 {
        pub case VAULT_TYPE_MISMATCH
    }

    pub fun encode(code: Code): String {
        return "[Code: ".concat(code.rawValue.toString()).concat("]")
    }
    init() {
        log("ErrorCode deployed")
    }
}