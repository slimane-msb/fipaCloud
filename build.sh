docker stop $( docker ps -a --quiet --filter "name=fipacloud")
docker rm -f $( docker ps -a --quiet --filter "name=fipacloud")
docker rmi fipacloud-app
docker compose up