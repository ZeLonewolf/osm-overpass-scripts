[out:csv(::lat,::lon, ::count; false; ",")]#BBOX[timeout:3600];
nwr[#TAG];
out qt ids center;
out count;