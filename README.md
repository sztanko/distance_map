# How far away is Russia from you?

Map of distance bands from Russia, measured in Ukraines as units.

![Map of distance bands from Russia, measured in Ukraines as units.](https://raw.githubusercontent.com/sztanko/distance_map/main/poster.png)

# Running the Code

## Requirements
- Docker
- Internet connection
- bash-compatible shell
- QGIS (optional)

## Instructions
1. Clone this repository.
2. Run `./load.sh` from the root directory of this repository. It will download the necessary data from Natural Earth, load it into a PostGIS database, and run the transformations. See (sql/run.sql)[sql/run.sql] for the SQL code that is run.
3. You can now open the `fat_russia.qgs` in QGIS.

## Input Data
1. **Countries (fair_world):** Excludes Greenland and African countries, includes only countries intersecting a specific geographic envelope.
2. **Cities (region_cities):** European cities and those in Reykjavik's timezone, within a specific geographic envelope.
3. **Crimea (crimea):** A subset of Countries, representing Crimea, intersecting a specific geographic envelope.

## Transformations
1. **Adjusting Territories:**
   - Crimea is separated from Russia and added to Ukraine.
   - Russia's geometry is updated to exclude Crimea.
2. **Generating Distance Points (distance_points):**
   - Points are generated in a grid covering a specific geographic area.
   - Each point's distance from Russia is calculated.
3. **Creating Expanded Russia Territories (fat_russia):**
   - Distances from Russia are used to create concentric zones around Russia.
   - These zones are used to create "concave hulls," representing expanded territories.
   - The hulls are adjusted to ensure they are within the world's geometry and don't overlap with each other.

## Final Output
- **fat_russia:** A table representing Russia's expanded tiers based on distances. Each record corresponds to a different expansion threshold, showing how Russia's influence or territory could hypothetically extend outward. Unit of measurement is "Ukraine", which is the furthest distance Ukraine to Russia (699km), then width of Ukraine (1316km)
