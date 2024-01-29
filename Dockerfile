# Use the latest PostGIS image as the base
FROM postgis/postgis:latest

# Set the environment variable to avoid interactive timezone configuration
ENV DEBIAN_FRONTEND=noninteractive

# Install PostGIS client
RUN apt update
RUN apt install -y postgis

# Install Python, GDAL (includes ogr2ogr), and Fiona
#RUN apt-get update && \
#    apt-get install -y python3 python3-pip && \
#    apt-get install -y gdal-bin python3-gdal


# Reset the environment variable
ENV DEBIAN_FRONTEND=dialog

ENV POSTGRES_HOST_AUTH_METHOD=trust

# Expose the PostgreSQL port
EXPOSE 5432

# Set the default command to run when starting the container
CMD ["postgres"]
