#!/bin/bash 

# this was derived from here: https://bitcointalk.org/index.php?topic=23081.20
# I simply slimmed it down so it could be used by a script -RobKohr

base58=({1..9} {A..H} {J..N} {P..Z} {a..k} {m..z})
bitcoinregex="^[$(printf "%s" "${base58}")]{34}$"

decodeBase58() {
    local s=$1
    for i in {0..57}
    do s="${s//${base58}/ $i}"
    done
    dc <<< "16o0d${s// /+58*}+f" 
}

encodeBase58() {
    # 58 = 0x3A
    bc <<<"ibase=16; n=${1^^}; while(n>0) { n%3A ; n/=3A }" |
    tac |
    while read n
    do echo -n ${base58[n]}
    done
}

checksum() {
    xxd -p -r <<<"$1" |
    openssl dgst -sha256 -binary |
    openssl dgst -sha256 -binary |
    xxd -p -c 80 |
    head -c 8
}

checkBitcoinAddress() {
    if [[ "$1" =~ $bitcoinregex ]]
    then
        h=$(decodeBase58 "$1")
        checksum "00${h::${#h}-8}" |
        grep -qi "^${h: -8}$"
    else return 2
    fi
}

hash160() {
    openssl dgst -sha256 -binary |
    openssl dgst -rmd160 -binary |
    xxd -p -c 80
}

hash160ToAddress() {
    printf "%34s\n" "$(encodeBase58 "00$1$(checksum "00$1")")" |
    sed "y/ /1/"
}

hash256ToAddress() {	
	#printf "80$1$(checksum "80$1")"
    printf "%34s\n" "$(encodeBase58 "80$1$(checksum "80$1")")" |
    sed "y/ /1/"
}

publicKeyToAddress() {
    hash160ToAddress $(
    openssl ec -pubin -pubout -outform DER |
    tail -c 65 |
    hash160
    )
}

privateKeyToWIF() {
    hash256ToAddress $(openssl ec -text -noout -in data.pem | head -5 | tail -3 | fmt -120 | sed 's/[: ]//g')
}

openssl  ecparam -genkey -name secp256k1 | tee data.pem &>/dev/null
openssl ec -text -noout -in data.pem | head -5 | tail -3 | fmt -120 | sed 's/[: ]//g' 
echo "PrivateKey"
privateKeyToWIF
echo "PublicKey"
openssl ec -pubout < data.pem | publicKeyToAddress
rm data.pem
