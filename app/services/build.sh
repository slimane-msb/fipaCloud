# FIleCLoud
# docker run -d \
#     --name filebrowser \
#     --user $(id -u):$(id -g) \
#     -p 8080:8080 \
#     -v ./data:/data \
#     -e FB_BASEURL=/filebrowser \
#     hurlenko/filebrowser

# Next cloud 
docker run -d -p 8080:80 nextcloud


# vscode
 docker run -d \
  --name=openvscode-server \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e CONNECTION_TOKEN= `#optional` \
  -e CONNECTION_SECRET= `#optional` \
  -e SUDO_PASSWORD=password `#optional` \
  -e SUDO_PASSWORD_HASH= `#optional` \
  -p 3000:3000 \
  -v  .:/config \
  --restart unless-stopped \
  lscr.io/linuxserver/openvscode-server:latest


# gitlab
# requires 3GB RAM

# mattermost 
docker run --name mattermost-preview -d --publish 8065:8065 mattermost/mattermost-preview

# focalboard 
docker run -it -p 80:8000 mattermost/focalboard






# jupyter lab 
docker run -p 10000:8888 quay.io/jupyter/scipy-notebook:2024-03-14


# mongoDB
## installation 
sudo apt-get install gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor

sudo apt-get install -y mongodb-org

echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-mongosh hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

## run session 
sudo systemctl start mongod

# APK
npm install

npm run devStart

open localhost::3030


