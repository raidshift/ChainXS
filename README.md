# ChainXS

ChainXS is a macOS application built in Swift which facilitates derivation of secp256k1 elliptic curve public / private keys and addresses from a private mnemonic or an public / private extended Key.

<img width="1132" alt="image" src="https://github.com/user-attachments/assets/66d974ca-6273-4257-a692-bf72d307c921" />

### Input
* BIP39 mnemonic (12, 15, 18, 21 or 24 words) with optional passphrase
* BIP32, BIP49 or BIP84 extended public key (xpub, ypub, zpub)
* BIP32, BIP49 or BIP84 extended private key (xprv, yprv, zpprv)

### Derivation paths
* BIP32 private (starting with "m") and public (starting with "M") derivation path

### Derivable keys and addresses

Public
* Public key
* Bitcoin address (P2PKH)
* Bitcoin address (P2WPKH)
* Extended public key (xpub)
* Extended public key (ypub)
* Extended public key (zpub)
* Ethereum address
* Tron address
* Kaspa address
* Kaspa test address

Private
* Private key
* Private key (WIF)
* Extended private key (xprv)
* Extended private key (yprv)
* Extended private key (zprv)

### File export
* ChainXS allows encrypted file export and import of mnemonic or extended key and derivation path
* Using strong authenticated encryption (via XChaCha20Poly1305) and password-based key derivation (via Argon2id)

### Download precompiled App 
* https://github.com/raidshift/ChainXS/releases

### Build from source
    git clone https://github.com/raidshift/ChainXS.git
    cd ChainXS
    ./1_build
* Swift Package Manager (>= v5.9) is required.
* Build target folder: ChainXS/product
