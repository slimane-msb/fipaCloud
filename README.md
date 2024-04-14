# fipaCloud

# add env variables 
- ajust them to your use case 
```
MONGODB_USER=root
MONGODB_PASSWORD=123456
MONGODB_DATABASE=subscribers
MONGODB_LOCAL_PORT=7017
MONGODB_DOCKER_PORT=27017

NODE_LOCAL_PORT=6868
NODE_DOCKER_PORT=4000

SESSION_SECRET=secret
DATABASE_URL=mongodb://127.0.0.1:27017/subscribers
```

# To test in local host : 
- create a .env file containing while replace secret and url and production in app directory
```
SESSION_SECRET=secret
DATABASE_URL=mongodb://127.0.0.1:27017/subscribers
PRODUCTION=false
```

- Run services/build.sh
```
./services/build.sh
```
