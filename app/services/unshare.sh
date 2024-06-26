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

deny_access_to_file() {
    local file_path=$1
    local dest_user=$2

    setfacl -x user:"$dest_user" "$file_path"
    
    return $?
}

deny_access_to_folder(){
    local file_path=$1
    local dest_user=$2

    setfacl -R -x u:"$dest_user" "$file_path"

    if [ $? -ne 0 ]; then
        return 1
    fi

    setfacl -R -x d:u:"$dest_user" "$file_path"

    if [ $? -ne 0 ]; then
        return 1
    fi

    return $?

}

deny_access_to_path() {
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
    
            setfacl -x u:"$user" "$current_path"

            if [ $? -ne 0 ]; then
                return 1
            fi
        fi
            current_path="$current_path/"
    done
}


delete_symlink() {
    local symlink_path=$1

    if [ -L "$symlink_path" ]; then
        rm "$symlink_path"

        if [ $? -eq 0 ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}


unshare_file(){
    
    local source_file=$1
    local source_user=$2
    local dest_user=$3

    # Chemin du répertoire personnel de l'utilisateur de destination
    local dest_home=$(eval echo "~$dest_user")
    local dest_file=$dest_home/share_with_me/$(basename "$source_file") 

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

    # Verifier si le fichier appartient bien a l'ulisateur
    file_belongs_to_user "$source_file" "$source_user"
    if [ $? -ne 0 ]; then
        echo "le fichier $(basename "$source_file") n'appartient pas a l'utilisateur $source_user. Arrêt du script."
        exit 1
    fi

    if [ ! -f "$dest_file" ]; then
        echo "Le fichier $(basename "$source_file") n'existes pas chez $dest_user."
        exit 1
    fi

    # blocker l'acces au chemin vers le fichier ou repertoire
    deny_access_to_path "$source_file" "$dest_user"
    if [ $? -ne 0 ]; then
        echo "Le blockage du chemin $source_file a l'utilisateur $dest_user echoue. Arrêt du script."
        exit 1
    fi
    echo "Le blockage du chemin : $source_file reussi"

    # autorisation d'acces au fichier elle meme
    deny_access_to_file "$source_file" "$dest_user"
    if [ $? -ne 0 ]; then
        echo "La déattribution du droit d'acces au fichier : $(basename "$source_file") a $dest_user echoue. Arrêt du script."
        exit 1
    fi
    echo "La désattribution du droit au fichier: $dest_file réussi"


    # suprimer le lien symbolique dans le répertoire de destination

    delete_symlink "$dest_file"

    if [ $? -eq 0 ]; then
        echo "L'arret du partage du fichier $source_file a $dest_user "
    else
        echo "Échec de la supression du lien symbolique."
    fi
}

unshare_folder(){
    local source_folder=$1
    local source_user=$2
    local dest_user=$3


    # Chemin du répertoire personnel de l'utilisateur de destination
    local dest_home=$(eval echo "~$dest_user")
    local dest_folder=$dest_home/share_with_me/$(basename "$source_folder") 


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
    if [ ! -d "$dest_folder" ]; then
        echo "Le repertoire $(basename "$source_folder") n'existes pas chez $dest_user."
        exit 1
    fi

    # autorisation d'acces au chemin vers le fichier ou repertoire
    deny_access_to_path "$source_folder" "$dest_user"
    if [ $? -ne 0 ]; then
        echo "Le bloquage du droit du chemin $source_folder a l'utilisateur $dest_user echoue. Arrêt du script."
        exit 1
    fi
    echo "Le bloquage d'acces du chemin : $source_folder reussi"

    # autorisation d'acces au repertoire elle meme
    deny_access_to_folder "$source_folder" "$dest_user"
    if [ $? -ne 0 ]; then
        echo "La désattribution du droit d'acces au repertoire : $(basename "$source_folder") a $dest_user echoué. Arrêt du script."
        exit 1
    fi
    echo "La désattribution du droit au repertoire: $source_folder réussi"

    #suprimer le lien symbolique

    delete_symlink "$dest_folder"

    if [ $? -eq 0 ]; then
        echo "L'arret du partage du repertoire $source_folder à $dest_user réussie"
        exit 0
    else
        echo "Échec de la supression du lien symbolique."
        exit 1
    fi

}



# Fonction principale
main() {
    if [ "$#" -ne 4 ]; then
        echo "Usage: $0 <file|folder> <path> <source_user> <dest_user>"
        exit 1
    fi

    local type=$1
    local path=$2
    local source_user=$3
    local dest_user=$4
    

    if [ "$type" == "file" ]; then
        unshare_file "$path" "$source_user" "$dest_user"
    elif [ "$type" == "folder" ]; then
        unshare_folder "$path" "$source_user" "$dest_user"
    else
        echo "Type inconnu: $type. Utilisez 'file' ou 'folder'."
        exit 1
    fi
}

# Appeler la fonction principale avec tous les arguments
main "$@"