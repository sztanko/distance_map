DROP TABLE IF EXISTS crimea;

DROP TABLE IF EXISTS fair_world;

drop table if EXISTS region_cities;

-- Give Crimea back to Ukraine
CREATE TABLE fair_world AS
SELECT gid, name, st_intersection(geom, ST_MakeEnvelope(-25.519867,33.660353,45.429352,72.158256, 4326)) AS geom
FROM ne_50m_admin_0_countries 
where 
-- Yes, this is one of those maps that ignores Greenland. Sorry, Greenland! 
-- And we also want to focus on Europe, so skip Africa.
name!='Greenland' AND 
continent!='Africa' AND
st_intersects(geom, ST_MakeEnvelope(-25.519867,33.660353,45.429352,72.158256, 4326));


CREATE TABLE region_cities AS
SELECT *
FROM ne_50m_populated_places
where 
--Only Europe cities will fit the map, and only european city that has non-european timezone is Reykjavik
(timezone like '%Europe%' or timezone like '%Reykjavik%') and
st_intersects(geom, ST_MakeEnvelope(-25.519867,35.660353,44.429352,72.158256, 4326))
;

-- Because Natural Earth counts Crimea as Russia, we need to restore justice here.
-- Give Crimea back to Ukraine in quick 3 steps

-- Step 1. Create a table with Crimea only. It actually cuts of a small chunk of Russia as well, but oh well.
CREATE TABLE crimea AS
SELECT gid, name, ST_Intersection(geom, ST_MakeEnvelope(32.053556, 44.298775, 36.656828, 46.326528, 4326)) AS geom
FROM fair_world
WHERE ST_Intersects(geom, ST_MakeEnvelope(32.053556, 44.298775, 36.656828, 46.326528, 4326)) AND name = 'Russia';

-- Step 2. Detach Crimea from Russia

UPDATE fair_world
SET geom = ST_Difference(geom::geometry, ST_MakeEnvelope(32.053556, 44.298775, 36.656828, 46.326528, 4326))
WHERE name = 'Russia';

WITH updated_crimea AS (
    SELECT ST_Union(geom::geometry) AS geom
    FROM crimea
)

-- Step 3. Give it back to Ukraine
UPDATE fair_world
SET geom = ST_Union(fair_world.geom, updated_crimea.geom)
FROM updated_crimea
WHERE fair_world.name = 'Ukraine';
CREATE INDEX ON fair_world USING GIST (geom);

-- Let's make a grid of points to and calculate distances from Russia to each of them
drop table if exists distance_points;
create table distance_points as 
WITH grid_points AS (
    SELECT ST_SetSRID(ST_MakePoint(lon::float+0.001 + random()*0.2, lat::float+0.001 + random()*0.2), 4326) AS geom
    -- this is already pretty much a button of dots, densing even more would crash postgres on defaul settings
    -- we already overengineered this excercise, so let's just leave it as it is
    FROM generate_series(-25, 45, 0.3) AS lon
    CROSS JOIN generate_series(33, 72, 0.3) AS lat
    
),
ruzzia as (select geom from fair_world where name = 'Russia'),
world as (select ST_BUFFER(ST_UNION(geom), 0.4) as geom from fair_world),
distances_from_ruzzia as (
    select 
        case 
            when ST_WITHIN(g.geom, r.geom) 
                then 0 
            else 
                ST_DistanceSpheroid(g.geom, r.geom) 
            end as distance,
        g.geom as geom
    from 
        grid_points g,
        ruzzia r,
        world w
    where st_within(g.geom, w.geom)
    
)
select * from distances_from_ruzzia;


CREATE INDEX ON distance_points USING GIST (geom);

DROP TABLE IF EXISTS fat_russia;

create table fat_russia as 
with distances_cumulative as (
    select 
        threshold,
        distance,
        geom
    from 
        distance_points
        -- ruzzia, ruzzia with smallest buffer covering Ukraine (696km), ruzzia with 1 full length ukraine buffer (1316km), and so on
        CROSS JOIN (values (0), (696), (1 * 1316), (2 * 1316), (3 * 1316) )as t(threshold)
    where distance <= threshold * 1000 and distance > (threshold - 1500 ) * 1000
),
world as (select ST_UNION(geom) as geom from fair_world),
ruzzia as (select geom from fair_world where name = 'Russia'),

concave_hull as (
    select
    threshold,
                ST_Intersection(
                    st_buffer(ST_ConcaveHull(ST_Collect(dc.geom), 0.99, false), 0.01),
                    -- Concave hull doesn't obey excalves like Kaliningrad, so we also calculate the buffer of the dots in each tier and intersect it with the concave hull
                    st_buffer(ST_UNION(dc.geom), 1)
                ) as geom
    from 
        distances_cumulative dc
        group by 1
),
hulls_with_russia as (
    select threshold,
    st_intersection(
        -- russia actually has borders.
        case when threshold=0 then ruzzia.geom
        
        when threshold=1 then st_difference(
            -- territories around russia are NOT russia. Repeat.
                st_union(ch.geom, lag(ch.geom) over (order by threshold)), 
                ruzzia.geom)
         else ch.geom end,
         w.geom)
        as geom

    from concave_hull ch,
        world as w,
        ruzzia as ruzzia
),

-- the remove the previous tier
hulls_without_previous as (
    select threshold as distance, 
    case 
        when threshold=0 then geom
        else
            st_difference(geom, lag(geom, 1, geom) over (order by threshold))
        end as geom
    FROM  hulls_with_russia
)


select * from hulls_without_previous;