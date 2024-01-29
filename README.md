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

# Tech details

The main challenge faced is the fact that Europe is large, and it is not possible to draw it on a plane without distorting the distances. 
Therefore typical planar buffer operations are not suitable for this task. PostGIS has a `Geography` type that can be used to perform calculations on a sphere, but it seems like it doesn't work on large shapes like Russia - it will just come up with some mid point, use projection that minimizes distortion on that point, but then the disstances on the rest of the shape won't be proportional.
Solution is almost brute-force like - generate a ton of dots, calculate their distances from Russia, and then use those distances to create concentric zones around Russia. 

I use concave hulls to create the zones, but because it will create a single concave hull for mainland russia and the exclave (Kaliningrad). So I also calculate the buffers around each dot, union them and intersect with concave hull. I also make sure that the concave hulls don't overlap with each other, so I subtract the smaller tiers from each larger tier. See (sql code)[sql/run.sql] for more details.

Additional challenge is that the source data (Natural Earth) displays Crimea as part of Russia. So I have to surgically remove it from Russia and add it to Ukraine.

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
