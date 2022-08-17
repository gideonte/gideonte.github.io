---
title: "Canadian Film Actors"
author: "Gideon Msambwa"
date: "4/7/2021"
output:
  html_document: default
  pdf_document: default
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Where do Canadian Film Actors and Actresses Come from?



## Introduction

- This report presents where the Canadian film casts are coming from.
- The word cast represents actors and actresses.
- This report will help individuals seeking to meet with different film actors for mentorship and learn from them. 


## Tools and Language

- RStudio
- R Programming Language


## Data Sources 
- Internet Movie Database (IMDB) for film casts (https://www.kaggle.com/stefanoleone992/imdb-extensive-dataset) 
- Canadian Geographical Names Database. (https://www.nrcan.gc.ca/earth-sciences/geography/download-geographical-names-data/9245).
- Natural Earth Data http://naciscdn.org/naturalearth/packages/natural_earth_vector.zip




## Obtaining  and Cleaning Data
First, we will obtain data of Casts Names and Locations.

```{r load libraries and obtain data, message=FALSE}
library(tidyverse)

IMDB_names <- read_csv("IMDb names.csv")
locations <- read_csv("cgn_canada_csv_eng.csv")
```


### Formatting the Cast and Location Data

The only columns I am interested in from the IMDB_names data frames are

* Cast Name
* Date of Birth
* Place of Birth

```{r Clean up and summarize data}
cast <- select(IMDB_names,
                name,
                date_of_birth,
                place_of_birth)
```

The goal is to have Canadian casts, so I will filter the _place_of_birth_ column to contain only Canada value.

```{r Filter for Canadian Cast}

canadian_cast <- filter(cast, str_detect(place_of_birth, "Canada")) %>%
  separate(place_of_birth, c("Geographical_Name", "Province", "Country"), ",")%>%
  mutate(Province = trimws(Province))%>%
  mutate(Province = gsub("C)","e",iconv(Province, 'ASCII//TRANSLIT'), fixed = TRUE))

```

Also, we will summarize the location data frame.

The column names are inconvenient, so I replace them here with names that are simpler and do not have spaces (which makes the syntax much simpler).

```{r change colnames, message=FALSE, results=FALSE, warning=FALSE}
colnames(locations) <- c("CGNDB_ID",
                      "Geographical_Name",
                      "Language",
                      "Syllabic_Form",
                      "Generic_Term",
                      "Generic_Category",
                      "Concise_Code",
                      "Toponymic",
                      "lat",
                      "long",
                      "Location",
                      "Province",
                      "Relevance_Scale",
                      "Decision_Date",
                      "Source")
```

The only columns I am interested in from the Canada_locations data frames are

* Geographical Name
* Latitude
* Longitude
* Province

```{r Clean up and summarize data of Canada Locations and Provinces}
canada_locations<- select(locations,
                Geographical_Name,
                lat,
                long,
                Province)

ca_provinces <- select(canada_locations,
                       Province,
                       long,
                       lat) %>%
  distinct(Province, .keep_all = TRUE)
```

Then Joining the _canadian_cast_ data with _canada_locations_ data

```{r final combination}
cast_and_location <- left_join(canadian_cast,
                                canada_locations,
                                by = c("Geographical_Name","Province"))%>%
  distinct(name, .keep_all = TRUE)%>%
  drop_na()
```

### Adding Province's Geographical Data

Next, we will create provinces with latitude and longitude data

```{r province hardcoded data}
provinces_locations <- tibble(
  lat = c(53.9333,53.7267,53.7609,46.5653,53.1355,44.6820,51.2538,46.5107,52.9399,52.9399,64.8255,70.2998,64.2823),
  long = c(-116.5765,-127.6476,-98.8139,-66.4619,-57.6604,-63.7443,-85.3232,-63.4168,-73.5491,-106.4509,-124.8457,-83.1076,-135.0000),
  province = c("Alberta", "British Columbia", "Manitoba", "New Brunswick", "Newfoundland and Labrador", "Nova Scotia", "Ontario", "Prince Edward Island", "Quebec", "Saskatchewan", "Northwest Territories", "Nunavut", "Yukon")
)

sum_by_province <- data.frame(table(cast_and_location$Province))
  colnames(sum_by_province) <- c("Province",
                      "no_of_cast")
  
sum_by_province = mutate(sum_by_province, 
                         percent = no_of_cast/sum(no_of_cast))

```




## Data Visualization

Now, let's load the shapefile

```{r load libraries and shape file, message=FALSE}
library(rgdal)
library(rgeos)
library(maptools)
library(mapproj)
library(broom)

world_map <- readOGR("natural_earth_vector/50m_cultural/ne_50m_admin_1_states_provinces.shp")
canada_map <- world_map[which(world_map$admin == "Canada"),]
```
Let's change data format

```{r fortify for ggplot mapping}
canada_fortified <- fortify(canada_map, region = "name")
```


### Join the plotting data

Let's join _canada_fortified_ and _sum_by_province_

```{r join the plotting data}
cast_combined <- left_join(canada_fortified,
                          sum_by_province,
                          by = c("id" = "Province"))
```


### Create a base map

Then let's create a base map.

```{r create base map}
canada_basemap <- ggplot(cast_combined,
                         aes(x = long,
                             y = lat)) +
  geom_polygon(aes(group = group,
                   fill = percent),
               colour = "grey") + 
  theme_void() +
  coord_map()
plot(canada_basemap)
```
![000010](https://user-images.githubusercontent.com/8546504/185061182-5d053116-7943-480d-8aab-96ea257321d0.png)


### Colour Scale

Let's add a colour scale.
```{r adding colour scale}
library(RColorBrewer)

blues <- brewer.pal(5, "Blues")

coloured_map <- canada_basemap +
  scale_fill_gradientn(colours = blues,
                      na.value = "#FFFFFF",
                      label = scales::percent)
plot(coloured_map)


```
![000011](https://user-images.githubusercontent.com/8546504/185061304-e6bc333f-a197-4613-a527-b239d3117f0d.png)


## Adding Data to the Map

Let's add _cast_and_location_ data to the map

```{r add data to the map}
castmap <- coloured_map +
  geom_point(data = cast_and_location,
             color = "gray50")
plot(castmap)
```
![000012](https://user-images.githubusercontent.com/8546504/185061324-c2518f80-9d50-4338-bd93-9eddfd9ce20f.png)


## Titles and Annotation
Let's finish off the plot by showing where the Canadian film casts come from.

```{r displaying final vizualization}
finalmap <- castmap +
  geom_text(data = provinces_locations,
            aes(x = long,
                 y = lat,
                 label = province),
            size = 2,
            hjust = 0,
            angle = 90) +
  labs(title = "Where does Canadian Film Cast Come From?",
       subtitle = "This graphic presents a visualization of the Canadian film cast\nlocated in each province and territory of Canada. Single dots represent\nindividual film casts. The percentage of casts in each province/territory\nbased on the country's total number of film cast. The word casts is\nused in this visualization to present actors and actresses.",
       caption = "Sources: Internet Movie Database,\nCanadian Geographical Names Database, and\nNatural Earth Data\nConcept & Design: Gideon Msambwa",
       fill = "Percent of Cast\nin each Province/Territory") +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14),    
    plot.subtitle = element_text(hjust = 0, colour = "gray50",size = 9),
    plot.caption = element_text(hjust = 0, colour = "gray50", size = 9)
  )
plot(finalmap)
```
<img width="1158" alt="Casts" src="https://user-images.githubusercontent.com/8546504/183376867-5cadfe8c-6bd5-4372-9a90-c3c17de66724.png">
