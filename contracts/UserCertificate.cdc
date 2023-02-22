
import RaisePoolInterface from "./RaisePoolInterface.cdc"
pub contract UserCertificate {

    pub resource Certificate: RaisePoolInterface.Certificate {

    }

    pub fun issueCertificate(): @Certificate {
        return <- create Certificate()
    }

}