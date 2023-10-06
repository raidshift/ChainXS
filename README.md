# ChainXS

ChainXS is a macOS Application built in Swift which facilitates derivation of SECP256K1 Elliptic Curve public/private keys and addresses from a private Mnemonic or an public/private Extended Key.
![image](https://github.com/raidshift/ChainXS/assets/51262620/0148f0ed-b844-4280-b3bc-0dbc89b86c2a)

### Input
* BIP39 mnemonic (consisting of 12, 15, 18, 21 or 24 words) & optional passphrase
* BIP32, BIP49 or BIP84 extended public key (xpub, ypub, zpub)
* BIP32, BIP49 or BIP84 extended private key (xprv, yprv, zpprv)

### Derivation paths
* BIP32 private (starting with "m") and public (starting with "M") derivation path

### Derivable keys and addresses:

Public
* Public Key
* Bitcoin Address (P2PKH)
* Bitcoin Address (P2PKH-P2WPK)
* Bitcoin Address (P2WPKH)
* Extended Public Key (xpub)
* Extended Public Key (ypub)
* Extended Public Key (zpub)
* Ethereum Address
* Tron Address

Private
* Private Key
* Private Key (WIF)
* Extended Private Key (xprv)
* Extended Private Key (yprv)
* Extended Private Key (zprv)

### Export/Import
* ChainXS allows encrypted-file export/import of mnemonic & passphrase, extended public key and derivation path
* Using authenticated encryption with password-based key derivation from https://github.com/raidshift/noxs

### Install
Swift Package Manager (>= v5.9) is required.
The "build" script builds the project and creates a macOS App in the folder "product"

    git clone https://github.com/raidshift/ChainXS.git
    cd ChainXS
    ./build

### Download precompiled App 

   https://github.com/raidshift/ChainXS/releases
