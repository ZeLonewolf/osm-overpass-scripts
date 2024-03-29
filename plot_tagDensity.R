#!/usr/bin/env Rscript
# R-script to process and plot tag usage data world-wide
# usage: ./plot_tagDensity.R [-i input.csv] [-o output.png|.jpg|.pdf] [--tag tag_name] [-w <num>] [-b <lat,lon,lat,lon>] [-c <yes|no>]
#        -i|--input          - input file in csv format with header and two columns containing lat, lon coordinates [default or -: stdin]
#        -o|--output         - output picture file formats: png, jpg, pdf (default: .png with autogenerated name)
#        -t|--tag            - name of tag to displey in plot title
#        -w|--binwidth       - size of square for object counting in degrees. 1 means 1˚x1˚ square (defalut: 1)
#        -b|--bbox           - plot only area within bbox. Four coordinates seprated by , [lat,lon,lat,lon] (defalut: NULL)
#        -c|--countries      - plot countries' borders [yes|no] (default: no)
#        -a|--adminlevel     - plot bondaries of admin_level [int] (default: no)

#
# pipe: ./csv_compare_tags.sh | ./plot_tagDensity.R 

args = commandArgs(trailingOnly = TRUE)

# Load packages
    packages = c("tidyverse", "ggspatial", "sf", "rnaturalearth", 
                 "rnaturalearthdata", "rgeos", "cowplot", "optparse", "ggtext", "osmdata")

    pack_check <- lapply(packages,
                           FUN = function(x) {
                                                if (!require(x, character.only = TRUE)) {
                                                  install.packages(x, dependencies = TRUE)
                                                  library(x, character.only = TRUE)
                                                }
                                              }
                        )

# Read options
    option_list <- list(
                        make_option(c("-i", "--input", type="character"),
                                        default = NULL, help = 'Input CSV file lat, lon coordinates',
                                        metavar = 'character'),
                        make_option(c("-o", "--output", type="character"),
                                        default = paste0("plot_", format(Sys.time(), "%y%m%d_%H%M%S"), ".png"),
                                        help = 'Outputfile for plot (.png, ,jpg, .pdf)',
                                        metavar = 'character'),
                        make_option(c("-t", "--tag", type="character"),
                                        default = "tag density", help = 'tag name',
                                        metavar = 'character'),
                        make_option(c("-w", "--binwidth", type="double"),
                                        default = 1, help = 'size of square for object counting in degrees',
                                        metavar = 'real'),
                        make_option(c("-b", "--bbox", type="character"),
                                        default = "", help = 'four coordinates separeatd by comma ',
                                        metavar = 'character'),
                        make_option(c("-c", "--countries", type="character"),
                                        default = "no", help = 'whether to plot borders [yes, no] (default: no)',
                                        metavar = 'character'),
                        make_option(c("-a", "--adminlevel", type="integer"),
                                        default = 0, help = 'plot administrative boundaries at admin_level [int] (default: no)',
                                        metavar = 'integer'))

    opt_parser <- OptionParser(option_list = option_list)
    opt <- parse_args(opt_parser)
    

# Get countours data
    if (opt$countries == "yes"){
        world <- ne_countries(scale = "medium", returnclass = "sf")
    } else {
        world <- ne_coastline(scale = "medium", returnclass = "sf")
    }

# Load overpass data
    if (opt$input == "-" || is.null(opt$input)) {
        overpass <- read_csv(file("stdin"), na = "")
    } else {
        overpass <- read_csv(opt$input, na = "")
    }

# Get names of the tags
    lat <- names(overpass)[1]
    lon <- names(overpass)[2]
    lat <- rlang::sym(lat)
    lon <- rlang::sym(lon)

# Get BBOX coordinates [minlat,minlon,maxlat,maxlon]
    bbox <- str_split_fixed(opt$bbox, ",", n=4) %>% as.numeric()

# Get admin boundaries from overpass
    if (opt$adminlevel != 0) {
        # border <- opq(bbox = c(bbox[1], bbox[2], bbox[3], bbox[4])) %>%
        border <- opq(bbox = c(bbox[2], bbox[1], bbox[4], bbox[3])) %>%
                add_osm_feature(key="boundary", value="administrative") %>%
                add_osm_feature(key="admin_level", value=opt$adminlevel) %>%
                osmdata_sf()
    }


# Plot object density over world map
    plot <- world %>% 
                ggplot() +
                    geom_bin2d(data = overpass, 
                               aes(x = !!lon, 
                                   y = !!lat, 
                                   fill = after_stat(log10(count))), 
                               binwidth = opt$binwidth) +
                    scale_fill_viridis_c(name = paste0("<span style = 'font-size:8pt'>log<sub>10</sub></span>"),
                                         option = "plasma") +
                    geom_sf(color = "grey70", size = 0.1, fill = "transparent") +
                    theme_bw() +
                    labs(title = paste0("**", opt$tag, "**"),
                         caption = Sys.Date()) +
                    theme(panel.background = element_rect(fill = "black"),
                          panel.grid = element_blank(),
                          axis.title = element_blank(),
                          plot.title.position = "plot",
                          plot.title = element_markdown(),
                          legend.title = element_markdown())

    # Plot administrative boundaries    
    if (opt$adminlevel != 0) {
        plot <- plot +
            geom_sf(data = border$osm_multipolygon, color = "turquoise", size = 0.2, fill = "transparent")
    }

    if (anyNA(bbox)) {
        print("No bbox set. Plotting for whole world. (If bbox was set check the format lat,lon,lat,lon)")
        plot <- plot +
                    coord_sf(expand = FALSE, ylim = c(-55, 90)) +
                    scale_y_continuous(breaks = c(-50, 0 , 50))
    } else {
        plot <- plot +
                    coord_sf(expand = FALSE, xlim = c(bbox[2], bbox[4]), ylim = c(bbox[1], bbox[3]))
    }

        
# Save output figure
    #save_plot(opt$output, plot)
    ggsave(opt$output, plot, height = 3.71, width = 6)
    
    
