# Ransomware emulation script
_Attention! Be careful with the script. It can encrypt all your files._

This script emulates ransomware activity and can encrypt/decrypt all files in the specified folder and sub-folders. It works on Linux and depends on OpenSSL tools. 
The script has three modes: encrypt (default), decrypt and attacker's view

### Encrypt mode
The script encrypts the specified (current by default) folder and sub-folders:
Usage: `./ransom.sh [-v] [starting_folder]`
Where params: `-v` - be verbose (optional)
`starting_folder` - where to start, `./` by default

During this mode the script 
  * randomly generates a symmetric key, 
  * encrypts it with the pre-populated attacker's public key and stores this info in the `ransom-key.txt` file,
  * uses the symmetric key to encrypt files in all sub-folders,
  * informs the user at the end about next steps ("request a ransom").

### Decrypt mode
The script decrypts the specified (current by default) folder and sub-folders using the symmetric key as a parameter:
Usage: `./ransom.sh [-v] -d symm_key [starting_folder]`
Where params: `-v` - be verbose (optional)
`-d symm_key` - the key to decrypt (i.e. XwBaVttI6qwwY22t9G2MDQUYX3C0ppQBzZ9/kd5bA48=)
`starting_folder` - where to start, `./` by default
During this mode the script uses the key to decrypt files in the folder and sub-folders. The script does not verify quality of the key. Thus, all encrypted files **could be lost with the wrong key**.

### Attacker's mode
The script decrypts and outputs the symmetric key using attacker's private key.
Usage: `./ransom.sh [-v] -p private_key [ranson-key.txt]`
Where params: `-v` - be verbose (optional)
`-d private_key` - the private key related to the public key (see preparation steps below)
`ransom-key.txt` - location and file name of the file with the encrypted symmetric key, `./ransom-key.txt` by default
During this mode the script uses the private key to decrypt the symmetric key and output it.

### Preparation Steps
An attacker has to create RSA private-public keys as a preparation to run encrypt/decrypt modes.
Generate the private key: `openssl genrsa -out $KEY_PRIV 2048`
Generate the public key: `openssl rsa -in $KEY_PRIV -outform PEM -pubout -out $KEY_PUB`
An attacker needs to replace the public key inside the script.
