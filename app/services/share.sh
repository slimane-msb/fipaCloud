#!/bin/bash

# Fonction pour vérifier si un utilisateur existe
user_exists() {
    local username=$1
    id "$username" &>/dev/null
}

file_belongs_to_user() {
    local file_path=$1
    local username=$2

    # Obtenir le propriétaire du fichier
    file_owner=$(stat -c '%U' "$file_path")

    # Vérifier si le propriétaire correspond à l'utilisateur spécifié
    if [ "$file_owner" == "$username" ]; then
        return 0
    else
        return 1
    fi
}

allow_access_to_path() {
    local path=$1
    local user=$2

    IFS='/' read -r -a path_parts <<< "$path"

    local current_path=""
    for part in "${path_parts[@]}"; do
        
        #iterer pour chaque partie du repertoire jusqu'a l'acces au fichier
        if [ -n "$part" ]; then
            current_path="$current_path$part"


            if [ "$current_path" == "$path" ]; then
              # Terminer la fonction avec succès
                return 0
            fi
    
            setfacl -m u:"$user":--x "$current_path"

            if [ $? -ne 0 ]; then
                return 1
            fi
        fi
            current_path="$current_path/"
    done
}

allow_access_to_file() {
    local file_path=$1
    local dest_user=$2
    local permission=$3

    setfacl -m user:"$dest_user":"$permission" "$file_path"
    

    return $?
}

allow_access_to_folder(){
    local file_path=$1
    local dest_user=$2
    local source_user=$3
    local permission=$4

# Appliquer les permissions spécifiées sur le répertoire
    setfacl -R -m u:$dest_user:$permissions $file_path

    if [ $? -ne 0 ]; then
        return 1
    fi


# Appliquer les permissions spécifiées par défaut sur le répertoire
    setfacl -R -d -m user:"$dest_user":"$permission",user:"$source_user":"rwx" "$file_path"



    return $?
}


transform_permissions() {
    local perms=$1
    local full_perms="---"

    [[ $perms == *"r"* ]] && full_perms="r${full_perms:1}"
    [[ $perms == *"w"* ]] && full_perms="${full_perms:0:1}w${full_perms:2}"
    [[ $perms == *"x"* ]] && full_perms="${full_perms:0:2}x"

    echo "$full_perms"
}


# Fonction pour partager un fichier entre utilisateurs en créant un lien symbolique
create_symlink() {
    
    local source_file=$1
    local dest_file=$2

    ln -sT "$source_file" "$dest_file" #2>/dev/null

    return $?
}



share_file(){
    local source_file=$1
    local source_user=$2
    local dest_user=$3
    local permissions=$4  

    # Chemin du répertoire personnel de l'utilisateur de destination
    local dest_home=$(eval echo "~$dest_user")
    local dest_file=$dest_home/share_with_me/$(basename "$source_file") 

    # Chemin du repertoire shared de l'ulisateur source
    local source_home=$(eval echo "~$source_user")
    local shared_folder=$source_home/shared/$(basename "$source_file") 


    #mise en formes du format des permission
    full_permissions=$(transform_permissions "$permissions")


    # Vérifier que les utilisateurs existent
    if ! user_exists "$source_user"; then
        echo "L'utilisateur source $source_user n'existe pas."
        exit 1
    fi

    if ! user_exists "$dest_user"; then
        echo "L'utilisateur de destination $dest_user n'existe pas."
        exit 1
    fi

    # Vérifier que le fichier source existe
    if [ ! -f "$source_file" ]; then
        echo "Le fichier $source_file n'existe pas."
        exit 1
    fi

    # Vérifier la non existance du lien ou fichier ayant le meme nom que le fichier partage dans le répertoire personnel de utilisateur destination
    if [ -f "$dest_file" ]; then
        echo "Le fichier $source_file existes deja chez $dest_user."
        exit 1
    fi


    # Verifier si le fichier appartient bien a l'ulisateur
    file_belongs_to_user "$source_file" "$source_user"
    if [ $? -ne 0 ]; then
        echo "le fichier $(basename "$source_file") n'appartient pas a l'utilisateur $source_user. Arrêt du script."
        exit 1
    fi

    # autorisation d'acces au chemin vers le fichier ou repertoire
    allow_access_to_path "$source_file" "$dest_user"
    if [ $? -ne 0 ]; then
        echo "L'attribution du droit du chemin $source_file a l'utilisateur $dest_user. Arrêt du script."
        exit 1
    fi
    echo "l'autorisation d'acces du chemin : $source_file reussi"

    # autorisation d'acces au fichier elle meme
    allow_access_to_file "$source_file" "$dest_user" "$full_permissions" 
    if [ $? -ne 0 ]; then
        echo "L'attribution du droit d'acces au fichier : $(basename "$source_file") a $dest_user echoue. Arrêt du script."
        exit 1
    fi
    echo "l'atribution du droit au fichier: $(basename "$source_file") réussi"


    # Créer le lien symbolique dans le répertoire de destination

    create_symlink "$source_file" "$dest_file"
    if [ $? -eq 0 ]; then
        echo "Le fichier $source_file a été partagé avec succès avec $dest_user via un lien symbolique."
    else
        echo "Échec de la création du lien symbolique."
        exit 1
    fi

    create_symlink "$source_file" "$shared_folder"
    if [ $? -eq 0 ]; then
        echo "Le fichier $(basename "$source_file") deposer dans le repertoire shared de $source_user."
        exit 0
    else
        echo "le fichier $(basename "$source_file") est auparavent partager"
        exit 0
    fi


}

share_folder(){
    local source_folder=$1
    local source_user=$2
    local dest_user=$3
    local permissions=$4  

    # Chemin du répertoire personnel de l'utilisateur de destination
    local dest_home=$(eval echo "~$dest_user")
    local dest_folder=$dest_home/share_with_me/$(basename "$source_folder") 

    # Chemin du du repertoire shared de l'ulisateur source
    local source_home=$(eval echo "~$source_user")
    local shared_folder=$source_home/shared/$(basename "$source_folder") 

    #mise en formes du format des permission
    full_permissions=$(transform_permissions "$permissions")

    # Vérifier que les utilisateurs existent
    if ! user_exists "$source_user"; then
        echo "L'utilisateur source $source_user n'existe pas."
        exit 1
    fi

    if ! user_exists "$dest_user"; then
        echo "L'utilisateur de destination $dest_user n'existe pas."
        exit 1
    fi

    # Vérifier que le repertoire source existe
    if [ ! -d "$source_folder" ]; then
        echo "Le repertoire $source_folder n'existe pas."
        exit 1
    fi

    # Verifier si le fichier appartient bien a l'ulisateur
    file_belongs_to_user "$source_folder" "$source_user"
    if [ $? -ne 0 ]; then
        echo "le repertoire $(basename "$source_folder") n'appartient pas a l'utilisateur $source_user. Arrêt du script."
        exit 1
    fi

    # Vérifier la non existance du lien ou fichier ayant le meme nom que le fichier partage dans le répertoire personnel de utilisateur destination
    if [ -d "$dest_folder" ]; then
        echo "Le repertoire $(basename "$source_folder") existes deja chez $dest_user."
        exit 1
    fi

    # autorisation d'acces au chemin vers le fichier ou repertoire
    allow_access_to_path "$source_folder" "$dest_user"
    if [ $? -ne 0 ]; then
        echo "L'attribution du droit du chemin $source_folder a l'utilisateur $dest_user. Arrêt du script."
        exit 1
    fi
    echo "l'autorisation d'acces du chemin : $source_folder reussi"

    # autorisation d'acces au fichier elle meme
    allow_access_to_folder "$source_folder" "$dest_user" "$source_user" "$full_permissions" 
    if [ $? -ne 0 ]; then
        echo "L'attribution du droit d'acces au repertoire : $(basename "$source_folder") a $dest_user echoué. Arrêt du script."
        exit 1
    fi
    echo "l'atribution du droit au repertoire: $source_folder réussi"



    # Créer le lien symbolique dans le répertoire de destination

    create_symlink "$source_folder" "$dest_folder"

    if [ $? -eq 0 ]; then
        echo "Le repertoire $source_folder a été partagé avec succès avec $dest_user via un lien symbolique."
    else
        echo "Échec de la création du lien symbolique."
    fi

    # Créer un lien symbolique dans le repertoire share de utilisateur source

    create_symlink "$source_folder" "$shared_folder"
    if [ $? -eq 0 ]; then
        echo "Le repertoire $(basename "$source_folder") deposer dans le repertoire shared de $source_user."
        exit 0
    else
        echo "le repertoire $(basename "$source_folder") est auparavent partager"
        exit 0
    fi

}


main() {
    local type=$1
    local source_path=$2
    local source_user=$3
    local dest_user=$4
    local permissions=$5

    if [ "$type" == "file" ]; then
        share_file "$source_path" "$source_user" "$dest_user" "$permissions"
    elif [ "$type" == "folder" ]; then
        share_folder "$source_path" "$source_user" "$dest_user" "$permissions"
    else
        echo "Type inconnu: $type. Utilisez 'file' ou 'folder'."
        exit 1
    fi
}


# Vérifier si les arguments nécessaires sont fournis
if [ $# -ne 5 ]; then
    echo "Usage: $0 <file|folder> <source_path> <source_user> <dest_user> <permissions>"
    exit 1
fi

# Appeler la fonction avec les arguments fournis
main "$1" "$2" "$3" "$4" "$5"