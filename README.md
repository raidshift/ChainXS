# ChainXS

ChainXS is a macOS application built in Swift which facilitates derivation of secp256k1 elliptic curve public / private keys and addresses from a private mnemonic or an public / private extended Key.

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
* Using strong authenticated encryption and password-based key derivation from https://github.com/raidshift/noxs

### Download precompiled App 
* https://github.com/raidshift/ChainXS/releases

### Build from source
    git clone https://github.com/raidshift/ChainXS.git
    cd ChainXS
    ./1_build
* Swift Package Manager (>= v5.9) is required.
* Build target folder: ChainXS/product
