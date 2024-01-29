cid=`docker ps | grep geo_postgres | awk '{print $1}'`
docker stop $cid
docker rm $cid