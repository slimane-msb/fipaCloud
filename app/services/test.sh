

useradd() {
    echo "useradd called with args: $@"
    return 0
}

chown() {
    echo "chown called with args: $@"
    return 0
}

chmod() {
    echo "chmod called with args: $@"
    return 0
}

mkdir() {
    echo "mkdir called with args: $@"
    return 0
}

userdel() {
    echo "userdel called with args: $@"
    return 0
}

id() {
    echo "id called with args: $@"
    if [ "$1" == "existing_user" ]; then
        return 0
    else
        return 1
    fi
}

source ./create_user.sh

test_create_existing_user() {
    local output=$(create_user existing_user 2>&1)
    local expected="L'utilisateur existing_user existe déjà."
    if [[ "$output" == *"$expected"* ]]; then
        echo "Test create_existing_user passed."
    else
        echo "Test create_existing_user failed."
    fi
}

test_create_new_user() {
    local output=$(create_user new_user 2>&1)
    local expected="L'utilisateur new_user a été créé avec succès."
    if [[ "$output" == *"$expected"* ]]; then
        echo "Test create_new_user passed."
    else
        echo "Test create_new_user failed."
    fi
}

test_create_existing_user
test_create_new_user
