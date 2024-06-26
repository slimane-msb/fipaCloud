#!/bin/bash

create_user(){
    local username=$1
    local homedir=/home/$1

    if id "$username" &>/dev/null; then
        echo "L'utilisateur $username existe déjà."
    else 
        useradd -m -d "$homedir" -s /bin/bash "$username"

        if [ $? -eq 0 ]; then
            chown "$username":"$username" "$homedir"
            status1=$?

            chmod 700 "$homedir"
            status2=$?

            # Création des répertoires shared et share_with_me
            mkdir -p "$homedir/shared"
            status3=$?
            mkdir -p "$homedir/share_with_me"
            status4=$?

            # Modification des permissions des répertoires shared et share_with_me
            chown "$username":"$username" "$homedir/shared"
            status5=$?
            chown "$username":"$username" "$homedir/share_with_me"
            status6=$?

            chmod 1770 "$homedir/shared"
            status7=$?
            chmod 1770 "$homedir/share_with_me"
            status8=$?


            if [ $status1 -eq 0 ] && [ $status2 -eq 0 ] && [ $status3 -eq 0 ] && [ $status4 -eq 0 ] && [ $status5 -eq 0 ] && [ $status6 -eq 0 ] && [ $status7 -eq 0 ] && [ $status8 -eq 0 ]; then
                echo "L'utilisateur $username a été créé avec succès."
                echo "La configuration de confidentialité a réussi."
                echo "Les répertoires shared et share_with_me ont été créés avec succès"
            else
                echo "Une erreur est survenue, suppression de l'utilisateur et de son répertoire personnel..."
                userdel -r "$username"

                if [ $? -eq 0 ]; then
                    echo "Suppression réussie."
                else
                    echo "Une erreur est survenue durant l'opération, veuillez supprimer l'utilisateur $username manuellement."
                fi
            fi        
        else
            echo "Échec de la création de l'utilisateur $username."
        fi
    fi
}

# Vérifier si les arguments nécessaires sont fournis
if [ $# -ne 1 ]; then
    echo "Usage: $0 <nom_utilisateur>"
    exit 1
fi

# Appeler la fonction avec les arguments fournis
create_user "$1"
