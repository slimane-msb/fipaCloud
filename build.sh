docker stop $( docker ps -a --quiet --filter "name=fipacloudwebsite")
docker rm -f $( docker ps -a --quiet --filter "name=fipacloudwebsite")
docker rmi fipacloudwebsite-app
docker compose up