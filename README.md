# ChainXS

ChainXS is a macOS Application built in Swift which facilitates derivation of SECP256K1 Elliptic Curve public/private keys and addresses from a private Mnemonic or an public/private Extended Key.

### Input
* BIP39 Mnemonic (consisting of 12, 15, 18, 21 or 24 words)
* BIP32, BIP49 or BIP84 Extended Public Key (xpub, ypub, zpub)
* BIP32, BIP49 or BIP84 Extended Private Key (xprv, yprv, zpprv)

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

### Install
Swift Package Manager (>= v5.7) is required.
The "build" script builds the project and creates a macOS App in the folder "product"

    git clone https://github.com/raidshift/ChainXS.git
    cd ChainXS
    ./build

### Download precompiled App 

   https://github.com/raidshift/ChainXS/releases