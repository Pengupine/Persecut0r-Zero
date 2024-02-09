if ! command -v openssl &> /dev/null
then
    if ! command -v gpg &> /dev/null
    then
        echo "GPG could not be found and OpenSSL neither. Aborting."
        exit 1
    fi
fi
