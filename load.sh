SHAPEFILES_DIR="shapefiles"
SHAPEFILES_INPUT_DIR="$SHAPEFILES_DIR/input"

SQL_DIR="sql"

# only run if shapefiles directory does not exist
if [ ! -d "$SHAPEFILES_DIR" ]; then
    mkdir -p $SHAPEFILES_DIR
    wget -c https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries.zip
    wget -c https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_populated_places.zip


    # unzip files into shapefiles/input directory if not unzipped yet
    unzip -n ne_50m_admin_0_countries.zip -d $SHAPEFILES_DIR
    unzip -n ne_50m_populated_places.zip -d $SHAPEFILES_DIR
fi


current_path=`pwd`


# Launch docker postgis if not launched yet:
is_running=`docker ps -a | grep geo_postgres | wc -l`
if [ $is_running -eq 0 ]; then
    echo "docker run --name geo_postgres -d -p 5433:5432 -e POSTGRES_HOST_AUTH_METHOD=trust -v $current_path/shapefiles:/shapefiles posstgres_ogr"
    docker run --name geo_postgres -d -p 5433:5432 -e POSTGRES_HOST_AUTH_METHOD=trust -v $current_path/shapefiles/:/shapefiles -v $current_path/sql/:/sql posstgres_ogr 
    sleep 5
fi


for shp in "$SHAPEFILES_INPUT_DIR"/*.shp; do
    # Get the base filename without the directory and extension
    filename=$(basename -- "$shp")
    tablename="${filename%.*}"

    echo "Loading $shp into $tablename"

    # Load shapefile into PostGIS using shp2pgsql and psql
    docker exec -i geo_postgres sh -c "shp2pgsql -d -I -s 4326 '$shp' public.$tablename | psql -U postgres"
done

# Run run.sql to create all the stuff
docker exec -i geo_postgres sh -c "psql -U postgres -d postgres -a -f /sql/run.sql"

docker exec -i geo_postgres sh -c "pgsql2shp -f /shapefiles/fair_world -u postgres postgres fair_world"
docker exec -i geo_postgres sh -c "pgsql2shp -f /shapefiles/fat_russia -u postgres postgres fat_russia"
docker exec -i geo_postgres sh -c "pgsql2shp -f /shapefiles/region_cities -u postgres postgres region_cities"







# docker run -p 5433:5432 -e POSTGRES_HOST_AUTH_METHOD=trust -v /Users/demeter.sztanko/workspace/geoprojects/ruzzia/:/shapefiles posstgres_ogr