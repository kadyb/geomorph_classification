### THIS SCRIPT REQUIRES SAGA GIS AND GDAL TO BE INSTALLED ### 

## the extent of original DEM is much greater than the borders of Poland
## DEM must be in "tmp" subfolder (it will be cut to the borders later)
output = file.path("data", "variables", "tmp")
DEM = file.path(output, "01_ELEVATION.tif")

  
## SLOPE
system(
  paste(
    "saga_cmd ta_morphometry 0",
    "-ELEVATION", DEM,
    "-SLOPE", file.path(output, "02_SLOPE.sdat"),
    "-UNIT_SLOPE", "degree"
  )
)

## STANDARD DEVIATION 1000 m
system(
  paste(
    "saga_cmd statistics_grid 1",
    "-GRID", DEM,
    "-STDDEV", file.path(output, "03_STDEV.sdat"),
    "-RADIUS", "16" # "-KERNEL_RADIUS"
  )
)

### MULTI-SCALE TPI
system(
  paste(
    "saga_cmd ta_morphometry 28",
    "-DEM", DEM,
    "-TPI", file.path(output, "04_MULTITPI.sdat")
  )
)

### TERRAIN SURFACE CONVEXITY
system(
  paste(
    "saga_cmd ta_morphometry 21",
    "-DEM", DEM,
    "-CONVEXITY", file.path(output, "05_CONVEXITY.sdat"),
    "-DW_WEIGHTING", "0"
  )
)

### LOCAL STATISTICAL MEASURES (ENTROPY)
system(
  paste(
    "saga_cmd imagery_tools 12",
    "-GRID", DEM,
    "-ENTROPY", file.path(output, "06_ENTROPY.sdat"),
    "-RADIUS", "16"
  )
)

### TOPOGRAPHIC OPENNESS
system(
  paste(
    "saga_cmd ta_lighting 5",
    "-DEM", DEM,
    "-POS", file.path(output, "07_OPENNESS.sdat")
  )
)

### MEDIAN ELEVATION 500 m
tmp = tempfile(fileext = ".tif")
system(
  paste(
    "gdalwarp", DEM, tmp, "-tr 500 500", "-r med"
  )
)
system(
  paste(
    "gdalwarp", DEM, file.path(output, "08_MEDIAN500.tif"), "-tr 30 30", "-r near"
  )
)

### MEDIAN ELEVATION 1000 m
tmp = tempfile(fileext = ".tif")
system(
  paste(
    "gdalwarp", DEM, tmp, "-tr 1000 1000", "-r med"
  )
)
system(
  paste(
    "gdalwarp", DEM, file.path(output, "09_MEDIAN1000.tif"), "-tr 30 30", "-r near"
  )
)

### POSTPROCESSING ###
output = file.path("data", "variables", "tmp")
DEM = file.path(output, "01_ELEVATION.tif")

files = list.files(output, pattern = "\\.tif|sdat$", full.names = TRUE)

output = file.path("data", "variables")
fnames = sub("\\..*$", "", basename(files)) # remove file extension
fnames = paste0(fnames, ".tif")
output = file.path(output, fnames)

mask = file.path("data", "vector", "Poland.gpkg")

## gdalwarp parameters
target_EPSG = paste("-t_srs", "EPSG:2180")
multithreads = "-multi"
vector = paste("-cutline", mask)
crop = "-crop_to_cutline"
nodata = paste("-dstnodata", "-999")

for (i in seq_along(files)) {
  system(
    paste("gdalwarp", files[i], output[i], target_EPSG, vector, crop,
          nodata, multithreads)
    )
}

## remove unnecessary variables
# unlink(file.path("data", "variables", "tmp"))