#!/usr/bin/env Rscript

# Load packages
    packages = c("tidyverse", "ggspatial", "sf", "rnaturalearth", 
                 "rnaturalearthdata", "rgeos", "cowplot", "optparse", "ggtext",
                 "lubridate", "scales")

    pack_check <- lapply(packages,
                           FUN = function(x) {
                                                if (!require(x, character.only = TRUE)) {
                                                  install.packages(x, dependencies = TRUE)
                                                  library(x, character.only = TRUE)
                                                }
                                              }
                        )
