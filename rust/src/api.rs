use flutter_rust_bridge::*;
pub use std::sync::RwLock;
use std::ops::Deref;
pub use std::vec::Vec;
pub use vodozemac::{
    megolm::{
        GroupSession, GroupSessionPickle, InboundGroupSession, InboundGroupSessionPickle,
        SessionConfig as MegolmSessionConfig,
    },
    olm::{
        Account, AccountPickle, IdentityKeys, OlmMessage, Session,
        SessionConfig as OlmSessionConfig, SessionPickle,
    },
    Curve25519PublicKey, Ed25519PublicKey, Ed25519Signature,
};

//#[frb(mirror(IdentityKeys))]
//pub struct _IdentityKeys {
//    /// The ed25519 key, used for signing.
//    pub ed25519: Ed25519PublicKey,
//    /// The curve25519 key, used for to establish shared secrets.
//    pub curve25519: Curve25519PublicKey,
//}
pub struct VodozemacMegolmSessionConfig {
    pub config: RustOpaque<MegolmSessionConfig>,
}

impl From<MegolmSessionConfig> for VodozemacMegolmSessionConfig {
    fn from(config: MegolmSessionConfig) -> Self {
        VodozemacMegolmSessionConfig {
            config: RustOpaque::new(config),
        }
    }
}

impl VodozemacMegolmSessionConfig {
    pub fn version(&self) -> u8 {
        self.config.version()
    }

    pub fn version_1() -> VodozemacMegolmSessionConfig {
        MegolmSessionConfig::version_1().into()
    }

    pub fn version_2() -> VodozemacMegolmSessionConfig {
        MegolmSessionConfig::version_2().into()
    }

    // can't name this default, because that is a dart keyword and the generator also strips my
    // suffixes!
    pub fn def() -> VodozemacMegolmSessionConfig {
        MegolmSessionConfig::default().into()
    }
}

pub struct VodozemacGroupSession {
    pub session: RustOpaque<RwLock<GroupSession>>,
}

impl From<GroupSession> for VodozemacGroupSession {
    fn from(session: GroupSession) -> Self {
        VodozemacGroupSession {
            session: RustOpaque::new(RwLock::new(session)),
        }
    }
}

impl VodozemacGroupSession {
    pub fn new(config: VodozemacMegolmSessionConfig) -> VodozemacGroupSession {
        GroupSession::new(*config.config).into()
    }

    pub fn session_id(&self) -> String {
        self.session
            .read()
            .expect("Failed to read session")
            .session_id()
    }

    pub fn message_index(&self) -> u32 {
        self.session
            .read()
            .expect("Failed to read session")
            .message_index()
    }

    pub fn session_config(&self) -> VodozemacMegolmSessionConfig {
        self.session
            .read()
            .expect("Failed to read session")
            .session_config()
            .into()
    }

    // In theory we could return more info, but the old olm API does not and currently we don't
    // need it.
    pub fn encrypt(&self, plaintext: String) -> String {
        self.session
            .write()
            .expect("Failed to write session")
            .encrypt(plaintext)
            .to_base64()
    }

    pub fn session_key(&self) -> String {
        self.session
            .read()
            .expect("Failed to read session")
            .session_key()
            .to_base64()
    }

    pub fn pickle_encrypted(&self, pickle_key: [u8; 32usize]) -> String {
        self.session
            .read()
            .expect("Failed to read session")
            .pickle()
            .encrypt(&pickle_key)
    }

    pub fn from_pickle_encrypted(
        pickle: String,
        pickle_key: [u8; 32usize],
    ) -> anyhow::Result<VodozemacGroupSession> {
        Ok(VodozemacGroupSession {
            session: RustOpaque::new(RwLock::new(GroupSession::from(
                GroupSessionPickle::from_encrypted(&pickle, &pickle_key)?,
            ))),
        })
    }

    pub fn from_olm_pickle_encrypted(
        pickle: String,
        pickle_key: Vec<u8>,
    ) -> anyhow::Result<VodozemacGroupSession> {
        Ok(VodozemacGroupSession {
            session: RustOpaque::new(RwLock::new(GroupSession::from_libolm_pickle(
                &pickle,
                &pickle_key,
            )?)),
        })
    }

    pub fn to_inbound(&self) -> VodozemacInboundGroupSession {
        let session = self.session
            .read()
            .expect("Failed to read session");
        InboundGroupSession::from(session.deref()).into()
    }
}

pub struct VodozemacInboundGroupSession {
    pub session: RustOpaque<RwLock<InboundGroupSession>>,
}

impl From<InboundGroupSession> for VodozemacInboundGroupSession {
    fn from(session: InboundGroupSession) -> Self {
        VodozemacInboundGroupSession {
            session: RustOpaque::new(RwLock::new(session)),
        }
    }
}

impl VodozemacInboundGroupSession {
    pub fn new(
        session_key: String,
        config: VodozemacMegolmSessionConfig,
    ) -> anyhow::Result<VodozemacInboundGroupSession> {
        Ok(InboundGroupSession::new(
            &vodozemac::megolm::SessionKey::from_base64(&session_key)?,
            *config.config,
        )
        .into())
    }

    pub fn session_id(&self) -> String {
        self.session
            .read()
            .expect("Failed to read session")
            .session_id()
    }

    pub fn first_known_index(&self) -> u32 {
        self.session
            .read()
            .expect("Failed to read session")
            .first_known_index()
    }

    // In theory we could return more info, but the old olm API does not and currently we don't
    // need it.
    pub fn decrypt(&self, encrypted: String) -> anyhow::Result<String> {
        Ok(String::from_utf8(
            self.session
                .write()
                .expect("Failed to write session")
                .decrypt(&(vodozemac::megolm::MegolmMessage::from_base64(&encrypted)?))?
                .plaintext,
        )?)
    }

    pub fn pickle_encrypted(&self, pickle_key: [u8; 32usize]) -> String {
        self.session
            .read()
            .expect("Failed to read session")
            .pickle()
            .encrypt(&pickle_key)
    }

    pub fn from_pickle_encrypted(
        pickle: String,
        pickle_key: [u8; 32usize],
    ) -> anyhow::Result<VodozemacInboundGroupSession> {
        Ok(VodozemacInboundGroupSession {
            session: RustOpaque::new(RwLock::new(InboundGroupSession::from(
                InboundGroupSessionPickle::from_encrypted(&pickle, &pickle_key)?,
            ))),
        })
    }

    pub fn from_olm_pickle_encrypted(
        pickle: String,
        pickle_key: Vec<u8>,
    ) -> anyhow::Result<VodozemacInboundGroupSession> {
        Ok(VodozemacInboundGroupSession {
            session: RustOpaque::new(RwLock::new(InboundGroupSession::from_libolm_pickle(
                &pickle,
                &pickle_key,
            )?)),
        })
    }

    // TODO(Nico): Reconsider if ExportedSessionKey isn't the better type for the API boundary
    pub fn import(
        session_key: String,
        config: VodozemacMegolmSessionConfig,
    ) -> anyhow::Result<VodozemacInboundGroupSession> {
        Ok(InboundGroupSession::import(
            &vodozemac::megolm::ExportedSessionKey::from_base64(&session_key)?,
            *config.config,
        )
        .into())
    }

    pub fn export_at_first_known_index(&self) -> String {
        self.session
            .read()
            .expect("Failed to read session")
            .export_at_first_known_index()
            .to_base64()
    }

    pub fn export_at(&self, index: u32) -> Option<String> {
        self.session
            .write()
            .expect("Failed to write session")
            .export_at(index)
            .map(|s| s.to_base64())
    }
}

pub struct VodozemacOlmSessionConfig {
    pub config: RustOpaque<OlmSessionConfig>,
}

impl From<OlmSessionConfig> for VodozemacOlmSessionConfig {
    fn from(config: OlmSessionConfig) -> Self {
        VodozemacOlmSessionConfig {
            config: RustOpaque::new(config),
        }
    }
}

impl VodozemacOlmSessionConfig {
    pub fn version(&self) -> u8 {
        self.config.version()
    }

    pub fn version_1() -> VodozemacOlmSessionConfig {
        OlmSessionConfig::version_1().into()
    }

    pub fn version_2() -> VodozemacOlmSessionConfig {
        OlmSessionConfig::version_2().into()
    }

    // can't name this default, because that is a dart keyword and the generator also strips my
    // suffixes!
    pub fn def() -> VodozemacOlmSessionConfig {
        OlmSessionConfig::default().into()
    }
}

pub struct VodozemacEd25519Signature {
    pub signature: RustOpaque<Ed25519Signature>,
}

impl From<Ed25519Signature> for VodozemacEd25519Signature {
    fn from(signature: Ed25519Signature) -> Self {
        VodozemacEd25519Signature {
            signature: RustOpaque::new(signature),
        }
    }
}

impl VodozemacEd25519Signature {
    pub const LENGTH: usize = 64usize;

    pub fn from_slice(bytes: [u8; 64usize]) -> anyhow::Result<VodozemacEd25519Signature> {
        let key = Ed25519Signature::from_slice(&bytes)?;
        Ok(key.into())
    }

    pub fn from_base64(signature: String) -> anyhow::Result<VodozemacEd25519Signature> {
        let key = Ed25519Signature::from_base64(&signature)?;
        Ok(key.into())
    }

    pub fn to_base64(&self) -> String {
        self.signature.to_base64()
    }

    pub fn to_bytes(&self) -> [u8; 64usize] {
        self.signature.to_bytes()
    }
}

pub struct VodozemacEd25519PublicKey {
    pub key: RustOpaque<Ed25519PublicKey>,
}

impl VodozemacEd25519PublicKey {
    pub const LENGTH: usize = 32usize;

    pub fn from_slice(bytes: [u8; 32usize]) -> anyhow::Result<VodozemacEd25519PublicKey> {
        let key = Ed25519PublicKey::from_slice(&bytes)?;
        Ok(key.into())
    }

    pub fn as_bytes(&self) -> [u8; 32usize] {
        self.key.as_bytes().clone()
    }

    pub fn from_base64(base64_key: String) -> anyhow::Result<VodozemacEd25519PublicKey> {
        let key = Ed25519PublicKey::from_base64(&base64_key)?;
        Ok(key.into())
    }

    pub fn to_base64(&self) -> String {
        self.key.to_base64()
    }

    /// Throws on mismatched signatures
    pub fn verify(
        &self,
        message: String,
        signature: VodozemacEd25519Signature,
    ) -> anyhow::Result<()> {
        self.key.verify(&message.as_bytes(), &signature.signature)?;
        Ok(())
    }
}

impl From<Ed25519PublicKey> for VodozemacEd25519PublicKey {
    fn from(key: Ed25519PublicKey) -> Self {
        VodozemacEd25519PublicKey {
            key: RustOpaque::new(key),
        }
    }
}

pub struct VodozemacCurve25519PublicKey {
    pub key: RustOpaque<Curve25519PublicKey>,
}

impl From<Curve25519PublicKey> for VodozemacCurve25519PublicKey {
    fn from(key: Curve25519PublicKey) -> Self {
        VodozemacCurve25519PublicKey {
            key: RustOpaque::new(key),
        }
    }
}

impl VodozemacCurve25519PublicKey {
    pub const LENGTH: usize = 32usize;

    pub fn from_slice(bytes: [u8; 32usize]) -> anyhow::Result<VodozemacCurve25519PublicKey> {
        let key = Curve25519PublicKey::from_slice(&bytes)?;
        Ok(key.into())
    }

    pub fn as_bytes(&self) -> [u8; 32usize] {
        self.key.to_bytes()
    }

    pub fn from_base64(base64_key: String) -> anyhow::Result<VodozemacCurve25519PublicKey> {
        let key = Curve25519PublicKey::from_base64(&base64_key)?;
        Ok(key.into())
    }

    pub fn to_base64(&self) -> String {
        self.key.to_base64()
    }
}

pub struct VodozemacIdentityKeys {
    pub ed25519: VodozemacEd25519PublicKey,
    pub curve25519: VodozemacCurve25519PublicKey,
}
impl From<IdentityKeys> for VodozemacIdentityKeys {
    fn from(key: IdentityKeys) -> Self {
        VodozemacIdentityKeys {
            ed25519: key.ed25519.into(),
            curve25519: key.curve25519.into(),
        }
    }
}

// TODO(Nico)
// - sas
// - OKB

pub struct VodozemacOlmMessage {
    pub msg: RustOpaque<OlmMessage>,
}

impl From<OlmMessage> for VodozemacOlmMessage {
    fn from(msg: OlmMessage) -> Self {
        VodozemacOlmMessage {
            msg: RustOpaque::new(msg),
        }
    }
}

impl VodozemacOlmMessage {
    pub fn message_type(&self) -> usize {
        self.msg.message_type().into()
    }

    pub fn message(&self) -> String {
        match &*self.msg {
            OlmMessage::Normal(m) => m.to_base64(),
            OlmMessage::PreKey(m) => m.to_base64(),
        }
    }

    pub fn from_parts(
        message_type: usize,
        ciphertext: String,
    ) -> anyhow::Result<VodozemacOlmMessage> {
        Ok(OlmMessage::from_parts(message_type, &ciphertext)?.into())
    }
}

pub struct VodozemacSession {
    pub session: RustOpaque<RwLock<Session>>,
}

impl From<Session> for VodozemacSession {
    fn from(key: Session) -> Self {
        VodozemacSession {
            session: RustOpaque::new(RwLock::new(key)),
        }
    }
}

impl VodozemacSession {
    pub fn session_id(&self) -> String {
        self.session
            .read()
            .expect("Failed to read session")
            .session_id()
    }

    pub fn has_received_message(&self) -> bool {
        self.session
            .read()
            .expect("Failed to read session")
            .has_received_message()
    }

    pub fn encrypt(&self, plaintext: String) -> VodozemacOlmMessage {
        self.session
            .write()
            .expect("Failed to write session")
            .encrypt(plaintext)
            .into()
    }

    pub fn decrypt(&self, message: VodozemacOlmMessage) -> anyhow::Result<String> {
        Ok(String::from_utf8(
            self.session
                .write()
                .expect("Failed to write session")
                .decrypt(&message.msg)?,
        )?)
    }

    pub fn pickle_encrypted(&self, pickle_key: [u8; 32usize]) -> String {
        self.session
            .read()
            .expect("Failed to read session")
            .pickle()
            .encrypt(&pickle_key)
    }

    pub fn from_pickle_encrypted(
        pickle: String,
        pickle_key: [u8; 32usize],
    ) -> anyhow::Result<VodozemacSession> {
        Ok(VodozemacSession {
            session: RustOpaque::new(RwLock::new(Session::from(SessionPickle::from_encrypted(
                &pickle,
                &pickle_key,
            )?))),
        })
    }

    pub fn from_olm_pickle_encrypted(
        pickle: String,
        pickle_key: Vec<u8>,
    ) -> anyhow::Result<VodozemacSession> {
        Ok(VodozemacSession {
            session: RustOpaque::new(RwLock::new(Session::from_libolm_pickle(
                &pickle,
                &pickle_key,
            )?)),
        })
    }

    pub fn session_config(&self) -> VodozemacOlmSessionConfig {
        self.session
            .read()
            .expect("Failed to read session")
            .session_config()
            .into()
    }
    // pub fn session_keys(&self) -> SessionKeys
}

pub struct VodozemacOneTimeKey {
    pub keyid: String,
    pub key: VodozemacCurve25519PublicKey,
}

pub struct VodozemacOlmSessionCreationResult {
    pub session: VodozemacSession,
    pub plaintext: String,
}

pub struct VodozemacAccount {
    pub account: RustOpaque<std::sync::RwLock<Account>>,
}

impl VodozemacAccount {
    pub fn new() -> VodozemacAccount {
        Self {
            account: RustOpaque::new(RwLock::new(Account::new())),
        }
    }

    pub fn max_number_of_one_time_keys(&self) -> usize {
        self.account
            .read()
            .expect("Failed to read account")
            .max_number_of_one_time_keys()
    }

    pub fn generate_fallback_key(&self) {
        self.account
            .write()
            .expect("Failed to read account")
            .generate_fallback_key()
    }

    pub fn forget_fallback_key(&self) -> bool {
        self.account
            .write()
            .expect("Failed to read account")
            .forget_fallback_key()
    }

    pub fn generate_one_time_keys(&self, count: usize) {
        self.account
            .write()
            .expect("Failed to write account")
            .generate_one_time_keys(count)
    }

    pub fn mark_keys_as_published(&self) {
        self.account
            .write()
            .expect("Failed to write account")
            .mark_keys_as_published()
    }

    pub fn ed25519_key(&self) -> VodozemacEd25519PublicKey {
        self.account
            .read()
            .expect("Failed to read account")
            .ed25519_key()
            .into()
    }

    pub fn curve25519_key(&self) -> VodozemacCurve25519PublicKey {
        self.account
            .read()
            .expect("Failed to read account")
            .curve25519_key()
            .into()
    }

    pub fn identity_keys(&self) -> VodozemacIdentityKeys {
        self.account
            .read()
            .expect("Failed to read account")
            .identity_keys()
            .into()
    }

    pub fn one_time_keys(&self) -> Vec<VodozemacOneTimeKey> {
        self.account
            .read()
            .expect("Failed to read account")
            .one_time_keys()
            .into_iter()
            .map(|(k, v)| VodozemacOneTimeKey {
                keyid: k.to_base64(),
                key: v.into(),
            })
            .collect::<Vec<VodozemacOneTimeKey>>()
    }

    pub fn fallback_key(&self) -> Vec<VodozemacOneTimeKey> {
        self.account
            .read()
            .expect("Failed to read account")
            .fallback_key()
            .into_iter()
            .map(|(k, v)| VodozemacOneTimeKey {
                keyid: k.to_base64(),
                key: v.into(),
            })
            .collect::<Vec<VodozemacOneTimeKey>>()
    }

    pub fn sign(&self, message: String) -> VodozemacEd25519Signature {
        self.account
            .read()
            .expect("Failed to read account")
            .sign(&message)
            .into()
    }

    pub fn create_outbound_session(
        &self,
        config: VodozemacOlmSessionConfig,
        identity_key: VodozemacCurve25519PublicKey,
        one_time_key: VodozemacCurve25519PublicKey,
    ) -> VodozemacSession {
        self.account
            .read()
            .expect("Failed to read account")
            .create_outbound_session(*config.config, *identity_key.key, *one_time_key.key)
            .into()
    }

    pub fn create_inbound_session(
        &self,
        their_identity_key: VodozemacCurve25519PublicKey,
        pre_key_message_base64: String,
    ) -> anyhow::Result<VodozemacOlmSessionCreationResult> {
        let res = self
            .account
            .write()
            .expect("Failed to write account")
            .create_inbound_session(
                *their_identity_key.key,
                &vodozemac::olm::PreKeyMessage::from_base64(&pre_key_message_base64)?,
            )?;
        Ok(VodozemacOlmSessionCreationResult {
            session: res.session.into(),
            plaintext: String::from_utf8(res.plaintext)?,
        })
    }

    pub fn pickle_encrypted(&self, pickle_key: [u8; 32usize]) -> String {
        self.account
            .read()
            .expect("Failed to read account")
            .pickle()
            .encrypt(&pickle_key)
    }

    pub fn from_pickle_encrypted(
        pickle: String,
        pickle_key: [u8; 32usize],
    ) -> anyhow::Result<VodozemacAccount> {
        Ok(VodozemacAccount {
            account: RustOpaque::new(RwLock::new(Account::from(AccountPickle::from_encrypted(
                &pickle,
                &pickle_key,
            )?))),
        })
    }

    pub fn from_olm_pickle_encrypted(
        pickle: String,
        pickle_key: Vec<u8>,
    ) -> anyhow::Result<VodozemacAccount> {
        Ok(VodozemacAccount {
            account: RustOpaque::new(RwLock::new(Account::from_libolm_pickle(
                &pickle,
                &pickle_key,
            )?)),
        })
    }
}
