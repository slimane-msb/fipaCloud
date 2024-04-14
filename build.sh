docker stop $( docker ps -a --quiet --filter "name=fipacloud_container")
docker rm -f $( docker ps -a --quiet --filter "name=fipacloud_container")
docker rmi fipacloud_image
docker build -t fipacloud_image .
docker run -d -p 4000:4000 --name fipacloud_container fipacloud_image