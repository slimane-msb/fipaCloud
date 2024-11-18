sudo systemctl start mongod
npm run devStart

docker run -d -p 8080:80 nextcloud

docker run -it -p 8081:8000 mattermost/focalboard

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
  
  
git clone https://github.com/mattermost/docker
cd docker
cp env.example .env

mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
sudo chown -R 2000:2000 ./volumes/app/mattermost

sudo docker-compose -f docker-compose.yml -f docker-compose.without-nginx.yml up -d
 


# ports 
http://localhost:4000/
http://localhost:8080
http://localhost:8081
http://localhost:3000 
http://localhost:8065