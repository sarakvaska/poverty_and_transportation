#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# Import these libraries in order to use app properly
library(shiny)
library(tidyverse)
library(dplyr)
library(tools)
library(tidyr)
library(ggplot2)
library(ggmap)
library(scales)
library(data.table)
library(ggrepel)
library(maptools)
library(leaflet)
library(plotly)
library(rgdal)
library(leaflet.extras)
library(sp)
library(shinythemes)

    
# bus routes is geojson data downloaded from Miami's Open Data Hub. More specifically, it 
# contains the geojson data needed to map all the bus routes in Miami
bus_routes <- "https://opendata.arcgis.com/datasets/a33afaedf9264a97844080839a6f5ec9_0.geojson"

# res_routes uses readOGR so that R can read the geojson data properly so that it can be made 
# of use
res_routes <- readOGR(dsn = bus_routes, layer = "OGRGeoJSON")

# routes is a dataframe of the geojson bus_routes data
routes <- jsonlite::fromJSON(bus_routes)

# bus_stops is geojson data downloaded from Miami's Open Data Hub. More specifically, it 
# contains the geojson data needed to map all the bus stop locations in Miami
bus_stops <- "https://opendata.arcgis.com/datasets/021adadcf6854f59852ff4652ad90c11_0.geojson"

# res_stops uses readOGR so that R can read the geojson data properly so that it can be made 
# of use
res_stops <- readOGR(dsn = bus_stops, layer = "OGRGeoJSON")

# zip_code is geojson data downloaded from Miami's Open Data Hub. More specifically, it 
# contains the geojson data needed to map all the zip code boundaries in Miami
zip_code <- "https://opendata.arcgis.com/datasets/fee863cb3da0417fa8b5aaf6b671f8a7_0.geojson"

# zip_boundary uses readOGR so that R can read the geojson data properly so that it can be made 
# of use
zip_boundary <- readOGR(dsn = zip_code, layer = "OGRGeoJSON")


# zip_csv is a dataframe containing all the data from the Zip_Code.csv file 
# in my data I added the bus_stop column and counted all the bus stops by using the geom_cluster 
# function so that I could create my scatterplots 
zip_csv <- read_csv("Zip_Code.csv")

# This line of code turns the numeric ZIP column of the zip_csv file 
# into a character column -- I did this so that the numbers on the scatterplots 
# would appear correctly on the axii (as ascending instead of individually)
zip_csv$ZIP <- as.character(as.numeric(zip_csv$ZIP))

# options is a list of all the user can choose to visualize in the shiny app scatterplots
options <- c("Median Income" = "median_income", 
             "Median Population" = "median_population",
             "Total Zip Code Area" = "Shape__Area")

# Define UI for application that draws shiny app
ui <- fluidPage(theme = shinytheme("cerulean"),
                
                # Navbar title
                navbarPage("What Influences Public Transportation Coverage in Miami?",
                           
                # tabPanel adds a Summary tab to my app. This is where I explain my project and what tools I used to 
                # build my project
                tabPanel("Summary", HTML('<center><img src = "https://pbs.twimg.com/media/DrcR_P9WsAAnMAG.jpg:large"
                                        width = "100%" height = "100%"></center>'), tags$br(), tags$br(), 
                p("In high school, I took the public bus almost everyday. I noticed -- or thought I noticed -- that 
                  the rate of people getting on and off would increase or decrease depending on the wealthier areas of Miami. I also thought that the 
                  coverage of bus stops fluctuated between areas of wealth. This struck my interest, so I created this app with the 
                  intention of exploring what factors (median income, median population, or area) impact
                  the coverage of Miami's public transportation."), 
                p("To explore this topic, I used data from", tags$a(href = "http://gis-mdc.opendata.arcgis.com/", "Miami's Open Data Hub."), 
                  "The links to the exact data I used are ", tags$a(href = "http://gis-mdc.opendata.arcgis.com/datasets/bus-route", "Bus Routes"), 
                  "and ", tags$a(href = "http://gis-mdc.opendata.arcgis.com/datasets/bus-stop", "Bus Stops."), 
                  "Using this data, I mapped Miami's bus routes and bus stops. In my bus stop map, I added the layer of zip code boundaries so that
                  the count of stops per zip code is distinguishable. I then graphed the relationship between median income, median population, and zip code area 
                  with the number of bus stops in all of Miami's zip codes. The goal of this project was to determine whether 
                  there exists a correlation between public transportation and poverty levels or population levels in Miami’s neighborhoods."),
                p("The other sources I used to create this project came from: ", tags$br(),
                tags$a(href = "http://www.miamidadematters.org/demographicdata/index/view?id=1469&localeTypeId=3", 
                       "Miami Dade Matters - Population Data per Zip Code"),
                tags$br(),
                tags$a(href = "http://www.miamidadematters.org/?module=demographicdata&controller=index&action=view&localeId=0&localeTypeId=3&tagFilter=0&id=2419", 
                       "Miami Dade Matters - Income Data per Zip Code"), tags$br(),
                tags$a(href = "https://twitter.com/volvoshine/status/1060336025661259776", 
                       "Image of Miami")),
                p("View the code I wrote to create this project on ", tags$a(href = "https://github.com/sarakvaska/poverty_and_transportation", "Github!"))),
                
                # this tabPanel creates the routes tab. In this panel, I explain how to use the routes map as well as the purpose of looking at the routes
                tabPanel("Routes", h2("Miami Bus Route Coverage"), p("This map is designed so that you can take a look at all of the bus routes in the Miami area. In total, there 
                         are 112 bus routes. As the hint in the map says, if you hover over the routes, you can see the route number. If if you click on the route, you can see its name. 
                         The names of the routes, for the most part, say what where the route begins and ends."), 
                       mainPanel(leafletOutput("map", height = 500))),
                
                # this tabPanel creates the bus stops/zip code boundaries map. Here, I explain how users can poke around to see how many stops are 
                # in a zipcode, in a region, or in all of Miami
                tabPanel("Bus Stops and Zip Code Boundaries", h2("Bus Stops in Miami Zip Codes"), 
                p("This map is designed so that you can take a look at all of the bus stops in Miami, and using the zip code boundaries, 
                   poke around to see where there are a large amount of stops or where there are none. As the hint in the map says, 
                   every zip code in Miami starts with a 3, so you can enter 3 in the search bar to see a list of all zip codes. You can also
                   search any city!"), 
                       mainPanel(leafletOutput("zipcodes", height = 500))), 
                
                # this tabPanel created my visualized data tab where I placed the scatterplots with the information I found and 
                # the correlation between variables
                tabPanel("Visualized Data", h2("Exploring Factors Impacting Miami's Transportation Coverage"), 
                         sidebarLayout(
                           sidebarPanel(
                             selectInput("x", label = "View by Factor:", choices = c(options), 
                                         selected = "Median Income"),
                             checkboxInput("line", label = "Show Best Fit Line", value = FALSE), 
                             htmlOutput("correlation_statement"),
                             htmlOutput("correlation"),
                             htmlOutput("note_and_summary")), 
                           mainPanel(plotlyOutput("plots"))), tags$br(),
                         
                       # I used the space underneath the plots to explains what I saw in each plot and then what I found 
                       # overall from visualizing the data collected
                       p("Using these plots, I found that median population has the strongest correlation to bus stop count. Therefore, 
                         this is probably how the city of Miami decides where to place the most bus stops and routes covering the area."),
                       p("I came to this conclusion by visualizing factors of the data that I felt played the most role in 
                         impacting the count of bus stops for certain zip codes in Miami: Income, Population, and Area.
                         When viewing by the Median Income factor, we can see that there seems to be a trend for a
                         higher bus stop count in areas with a less median income. To confirm whether a relationship exists 
                         between stop count and median income, I found the correlation: -0.29. Because this correlation 
                         is negative, it signifies that for stop count and income, an increase in stop count is correlated with a
                         decrease in median income for an area. Because the correlation is -0.29, this indicates the relationship 
                         between these variables is moderately negatively correlated."),
                       p("The next factor is median population. Looking at this graph and the correlation we see between the bus stop count 
                         and the median population, we can see that it's very strong - stronger than that of median income. The correlation gives
                         us one, meaning that this relationship is perfectly positively correlated, so as the population increases, the bus stop
                         count in an area increases."), 
                       p("The total zip code area scatterplot intends to see whether area is a factor in the amount of bus stops. It aims to look at 
                        the correlation between area coverage of a zip code and the corresponding number of stop in that area. The correlation between 
                        these variables is 0.03, which is very small, so they are only correlated by a small amount - an amount too 
                        insignificant to draw any conclusions from.")
                       )))

# read geojson bus route data through readlines and put into variable called geojson so that I am able
# to use it in addGeoJSONv2, which will map it in my Shiny app
geojson <- reactive({
  readLines("https://opendata.arcgis.com/datasets/a33afaedf9264a97844080839a6f5ec9_0.geojson") %>% 
  paste(collapse = "\n")
})

# server outputs my functions in my app 
server <- function(input, output) {
  
  # output$map renders my leaflet map for routes and my UI (above) reads in the leafletOutput("map") from 
  # how I've defined it here so that it can be displayed in its repsective tab 
  output$map <- renderLeaflet({
    
    # I am using leaflet in order to display my map widget 
    leaflet() %>%
      
    # addProviderTiles displays the background of the map. providers$Esri.WorldImagery adds the OpenStreetMap
    # tiles so that it looks like users are viewing a satelite image
    addProviderTiles(providers$Esri.WorldImagery) %>%
    
    # adds a full screen button to the map widget
    addFullscreenControl() %>%
      
    # setView is set on the lng and lat of Miami and zoomed into 10 so that users can 
    # see it from a place where it's viewable enough and information on the map isn't missing
    setView(lng=-80.191788, lat=25.761681, zoom = 10) %>%
    
    # addGeoJSONv2 displays the routes onto my map. I set the lines of the routes to a weight of 3 so that they were
    # not too thick. I set fill equal to FALSE so that the spaces in between the routes were not filled, because 
    # leaflet was trying to fill them in as shapes versus lines. The labelProperty makes it so that users can move
    # the mouse around and, when they crossover a line, the route name pops up. I set the popupProperty to LINENAME so
    # that users can see the LINENAME (where each route begins and ends) when they click on the route they're looking at.
    # The highlightOptions make it so that when a user is hovering on a line, it is highlighted white so they know 
    # exactly which route they're looking at
    addGeoJSONv2(geojson(), weight = 3, color = "#00a1e4", opacity = 1, 
                 fill = FALSE, labelProperty = "RTNAME", popupProperty = "LINENAME",
                 highlightOptions = highlightOptions(weight = 2, color='white', 
                                                     fillOpacity = 1, opacity = 1,
                                                     bringToFront = TRUE, sendToBack = TRUE)) %>%
      addControl("<P><B>Hint:</B> Hovering on a route gives its number; clicking on a route gives the location it covers!</P>",
                 position='bottomright')
  })
  
  # output$zipcodes takes in the leaflet map I've made and my UI (above) is able to identify it and display it 
  # in my tab panel "Bus Stops and Zip Code Boundaries"
  output$zipcodes <- renderLeaflet({
    
    # I am using leaflet to make this map widget 
    leaflet() %>%
      
      # like in the previous map, addProviderTiles(providers$Esri.WorldImagery) adds the OpenStreetMap
      # tiles, so that it looks like users are viewing a satelite image
      addProviderTiles(providers$Esri.WorldImagery) %>%
      
      # this adds a full screen button to the map widget
      addFullscreenControl() %>%
      
      # Like in the previous map, setView is set on the lng and lat of Miami and zoomed into 10 so that users can 
      # see it from a place where it's viewable enough and information on the map isn't missing
      setView(lng=-80.191788, lat=25.761681, zoom = 10) %>%
      
      # addCircleMarkers adds the bus stops to my map. I have set them to be white with blue dots filled in and 
      # to be small enough so that they do no appear as an overwhelming amount on the map 
      addCircleMarkers(data = res_stops, radius = 5, fillColor = "#00a1e4",
                       color = "white", fillOpacity = 10, opacity = .5,
                       stroke = TRUE, 
                       
                       # clusterOptions clusters my markers -- stops -- together 
                       # this makes it so that as the user zooms out, the bus stops cluster and 
                       # numbers appear at the center of each marker cluster, showing how many stops
                       # are in one cluster. If you zoom out all the way, there are 8,000 stops in one
                       # cluster. The more you zoom in, the more you can tell how many bus stops are in 
                       # a certain area. If you zoom in all the way, you can see the individual bus stops. 
                       clusterOptions = markerClusterOptions(iconCreateFunction =
                                              JS("
                                                 function(cluster) {
                                                 return new L.DivIcon({
                                                 html: '<div style=\"background-color:rgba(255, 255, 255, 1)\"><span>' + cluster.getChildCount() + '</div><span>',
                                                 className: 'marker-cluster'
                                                 });
                                                 }"), maxClusterRadius = 100)) %>%
      
      # addPolygons adds the boundaries of each zip code onto the map and colors them so 
      # that users can tell they are boundaries but that the map and the markers are still visible 
      # within the boundaries
      addPolygons(data=zip_boundary, opacity = 1, fillColor = "#00a1e4", 
                  weight = 3, color = "#2ab7ca ", fillOpacity = .25,
                  
                  # I used highlightOptions so that when a user is hovering within/on a zip code boundary, 
                  # the zip code is highlighted
                  highlightOptions = highlightOptions(color = "white", weight = 2,
                                                      bringToFront = TRUE),
                  # this label makes it so that if a user is hovering within/on a zip code boundary, the name 
                  # of the zip code and the cities it bounds are seen. Since the json data does not have the 
                  # city names in zipcodes, i added this in using paste0
                  label = paste0(zip_boundary@data[["ZIPCODE"]], c(": Homestead, Florida City", ": Hialeah", 
                                                                   ": Bay Harbor Islands, Bal Harbour, Surfside, North Miami, Indian Creek", 
                                                                   ": Key Largo, North Key Largo", ": Miami", ": Miami", ": Miami Shores", ": Kendall", 
                                                                   ": Miami, Miami Beach", ": Miami", ": Miami, Miami Beach, Fisher Island", ": Miami, Hialeah, 
                                                                   West Little River, Gladeview, Pinewood, Westview", ": Doral, Sweetwater", 
                                                                   ": Hialeah, Hialeah Gardens, Miami Lakes", ": Flordia City", ": Palm Springs North, 
                                                                   Country Club", ": Hialeah, Miami Lakes, Hialeah Gardens", ": South Miami, West Miami, Westchester, 
                                                                   Glenvar Heights, Olympia Heights, Coral Terrace", ": Miami, Coral Gables", 
                                                                   ": North Miami, North Miami Beach, Golden Glades", ": Homestead Base", ": Doral, Medley", 
                                                                   ": Miami", ": Cutler Bay", ": Miami Gardens, North Miami Beach, Golden Glades, Andover, Norland", 
                                                                   ": Miami", ": Kendall West", ": Miami", ": Miami", ": Doral", ": Coral Gables, Kendall, South Miami, 
                                                                   Glenvar Heights, Olympia Heights", ": Miami", ": Doral, Miami Springs, Virginia Gardens, Medley", 
                                                                   ": Miami", ": Westchester, Olympia Heights, Westwood Lakes, University Park, Sunset", ": Redland", 
                                                                   ": North Miami, Miami Shores, Biscayne Park, Sweetwater, Golden Glades", ": North Miami Beach, Golden Glades, Ojus", 
                                                                   ": North Miami Beach, Miami Gardens, Ives Estates, Ojus", ": North Miami, Golden Glades, Pinewood, Westview", 
                                                                   ": Kendall, Palmetto Bay, Richmond Heights", ": Sunny Isles Beach, Aventura, North Miami Beach, North Miami, Golden Beach, Ojus", 
                                                                   ": The Hammocks, Country Walk", ": Miami Beach, North Bay Village", ": Aventura, Ojus", ": Kendall West", 
                                                                   ": Miami Gardens,  Lake Lucerne", ": Miami Gardens", ": Kendall, The Hammocks, Country Walk, Kendale Lakes, 
                                                                   Richmond Heights, The Crossings, Three Lakes", ": Opa-locka, Miami Gardens, Bunche Park", 
                                                                   ": Miami", ": Miami", ": Miami, Hialeah, Miami Springs, Liberty Square", ": Cutler Bay, South Miami Heights, 
                                                                   Lakes by the Bay, Goulds", ": Palmetto Bay, Coral Gables", ": Miami", ": Richmond West", ": Miami", 
                                                                   ": Miami", ": Miami, Miami Beach", ": Miami", ": Miami", ": Miami, Coral Gables", ": Miami, Miami Shores, El Portal", 
                                                                   ": Miami, Coral Gables", ": Miami, Miami Shores, El Portal, West Little River, Gladeview, Pinewood", 
                                                                   ": Kendall, Coral Gables, Pinecrest", ": Miami, Key Biscayne", ": Kendall, Sunset", ": Goulds, Princeton, Silver Palm", 
                                                                   ": Hialeah", ": Hialeah, Miami Lakes, Miami Gardens", ": North Miami, Miami Shores, Golden Glades, Pinewood", 
                                                                   ": Kendall, Kendall Lakes", ": Tamiami", ": Westchester, Sweetwater, University Park, Fountainbleau", 
                                                                   ": Doral, Fountainbleau, Sweetwater", ": Tamiami, Kendale Lakes, University Park", ": Homestead", 
                                                                   ": Hialeah, Opa-locka,  West Little River", ": Miami", ": South Miami Heights, Richmond West, Goulds, Quail Heights",
                                                                   ": Palmetto Bay, Cutler Bay, West Perrine, South Miami Heights, Palmetto Estates, Cutler",
                                                                   ": Homestead, Leisure City, Homestead Base", ": Homestead Base, Princeton, Naranja", 
                                                                   ": Miami, Coral Gables, West Miami, Westchester, Coral Terrace, Fountainbleau", ": Miami, Doral, Fountainbleau")),
                  group = 'zips') %>%
      
      # addSearchFeatures is added to the map so that users can search a specific zip code from the map widget 
      # and the map will take you to whichever one you've searched
      addSearchFeatures(targetGroups = 'zips', options = searchFeaturesOptions(zoom = 13, hideMarkerOnCollapse = TRUE)) %>%
      
      # addControl adds a hint to the bottom of the map so that users know that all Miami zipcodes begin with the number 
      # 3 and can start their search from there
      addControl("<P><B>Hint:</B> Search any zip code or city in Miami! All zip codes start with 3.</P>",
                 position='bottomright')
  })
  
  # output$plots takes in the scatterplot plotly graphs that I've created and my UI (above) 
  # can display them in the tab panel "Visualized Data"
  output$plots <- renderLeaflet({
    
    # this graph will display if the checkbox for line of best fit is not clicked
    if(input$line == FALSE) {
        if(input$x == "median_income" || input$x == "median_population") {
          # In my scatterplots, the bus stop count is on the y axis and the user's chosen input
          # for the factor on the graph is on the x axis. The graph is colored by zip code so that 
          # they all show up individually 
          ggplotly(ggplot(data = zip_csv, 
                          aes_string(y = "bus_stops", x = input$x, color = "ZIP")) +
                     
                     # if user chooses to see median income on their scatterplot, the tooltip 
                     # of the plot will display relevant, formatted information
                     # (such as zip code, bus stop count, median income, and median pop. 
                     # when they hover over points 
                     # i included median population and median income so that users could explore if there
                     # exists a relationship between the two and their coverage of transportation
                     geom_point(if(input$x == "median_income") {
                       aes(text = paste0("Zip Code: ", ZIP, "<br>Bus Stops: ", bus_stops, 
                                         "<br>Median Income: $", 
                                         format(((zip_csv$median_income)), 
                                                nsmall=1, big.mark=","), 
                                         "<br>Median Population: ", 
                                         format(((zip_csv$median_population)), 
                                                nsmall=1, big.mark=",")))
                     }
                     
                     # if user chooses to see median population on their scatterplot, the tooltip 
                     # of the plot will display relevant, formatted information (the same as in 
                     # the median income scatterplot when they hover over points 
                     else if (input$x == "median_population") {
                       aes(text = paste0("Zip Code: ", ZIP, "<br>Bus Stops: ", bus_stops, 
                                         "<br>Median Population: ", 
                                         format(((zip_csv$median_population)), 
                                                nsmall=1, big.mark=","), 
                                         "<br>Median Income: $", 
                                         format(((zip_csv$median_income)), 
                                                nsmall=1, big.mark=",")))
                     }) +
                  
                     # the labels of the scatterplots
                     # the axis will be labeled according to the variable the user visualizes 
                     # the y axis will be labeled total bus stops, since this variable does not change 
                     # the color legend is labeled Zipcodes 
                     labs(x = names(options[which(options == input$x)]), 
                          y = "Total Bus Stops", 
                          color = "Zip Codes") + 
                     
                     # the scale of the x axis is fitted according to the variable
                     # the median income appears as the dollar scale
                     # the median population appears as thousands with a comma 
                     # the zip area appears as a log because the numbers are so large
                     if (input$x == "median_income") {
                       scale_x_continuous(labels = scales::dollar)
                     } else if (input$x == "median_population") {
                       scale_x_continuous(labels = scales::comma)
                     } else {
                       scale_x_log10()
                     }, tooltip = "text")
        }
        else {
          ggplotly(ggplot(data = zip_csv, 
                          aes_string(y = input$x, x = "bus_stops", color = "ZIP")) + 
                     geom_point(aes(text = paste0("Zip Code: ", ZIP, "<br>Bus Stops: ", bus_stops, 
                                         "<br>Zip Code Area: ", 
                                         format((zip_csv$Shape__Area),
                                         nsmall = 1, big.mark=",")))) +
            # the labels of the scatterplots
            # the axis will be labeled according to the variable the user visualizes 
            # the y axis will be labeled total bus stops, since this variable does not change 
            # the color legend is labeled Zipcodes 
            labs(x = "Total Bus Stops", 
                 y = names(options[which(options == input$x)]), 
                 color = "Zip Codes") + scale_y_log10(), tooltip = "text") 
        }
      
      }
    # if the user chooses to add a line of best fit and they have chosen to visualize
    # population, income or area, this does it for them 
    # all of this code is the same as the above code, except for geom_smooth, 
    # which adds the best fit line 
    else {
      if(input$x == "median_income" || input$x == "median_population") {
        ggplotly(ggplot(data = zip_csv, 
                        aes_string(y = "bus_stops", x = input$x, color = "ZIP")) +
                   geom_point(if(input$x == "median_income") {
                     aes(text = paste0("Zip Code: ", ZIP, "<br>Bus Stops: ", bus_stops, 
                                       "<br>Median Income: $", 
                                       format(((zip_csv$median_income)), 
                                              nsmall=1, big.mark=","), 
                                       "<br>Median Population: ", 
                                       format(((zip_csv$median_population)), 
                                              nsmall=1, big.mark=",")))
                   }
                   else if (input$x == "median_population") {
                     aes(text = paste0("Zip Code: ", ZIP, "<br>Bus Stops: ", bus_stops, 
                                       "<br>Median Population: ", 
                                       format(((zip_csv$median_population)), 
                                              nsmall=1, big.mark=","), 
                                       "<br>Median Income: $", 
                                       format(((zip_csv$median_income)), 
                                              nsmall=1, big.mark=",")))
                   }) +
                   # geom_smooth is line of best fit, labs adds labels to the axii of 
                   # the graphs, and scale x scales the x axis depending on the 
                   # variable being looked at
                   geom_smooth(aes(group = "ZIP"), se = FALSE, method = "lm") + 
                     labs(x = names(options[which(options == input$x)]), 
                          y = "Total Bus Stops", 
                          color = "Zip Codes") + if (input$x == "median_income") {
                            scale_x_continuous(labels = scales::dollar)
                          } else if (input$x == "median_population") {
                            scale_x_continuous(labels = scales::comma)
                          }, tooltip = "text")
      }
      else {
        ggplotly(ggplot(data = zip_csv, 
                        aes_string(y = input$x, x = "bus_stops", color = "ZIP")) +
                   geom_point(aes(text = paste0("Zip Code: ", ZIP, "<br>Bus Stops: ", bus_stops, 
                            "<br>Zip Code Area: ", format(((zip_csv$Shape__Area)), 
                                                          nsmall=1, big.mark=",")))) +
                   # geom_smooth is line of best fit, labs adds labels to the axii of 
                   # the graphs, and scale x scales the x axis depending on the 
                   # variable being looked at
                   geom_smooth(aes(group = "ZIP"), se = FALSE, method = "lm") + 
                   labs(x = "Total Bus Stops", 
                        y = names(options[which(options == input$x)]), 
                        color = "Zip Codes") + scale_y_log10(), tooltip = "text")
      }
    }
  })
  
  # add line below checkbox for line of best input that says what the correlation between 
  # the variables is 
  output$correlation_statement <- renderUI ({
    if(input$line == TRUE) {
      correlation <- round(cor(zip_csv[["median_population"]], zip_csv[[input$x]], use = "complete.obs"), 2)
      h5(tags$em("Variable Correlation:"))
    }
  })
  
  # output the correlation between the variables 
  output$correlation <- renderUI({
    if(input$line == TRUE) {
      correlation <- round(cor(zip_csv[["median_population"]], zip_csv[[input$x]], use = "complete.obs"), 2)
      as.character(correlation)
      }
  })
  
  # this note goes under where I've added the correlation value so that 
  # people can understand what the number they're looking at means in regards to 
  # how the variables impact each other 
  output$note_and_summary <- renderUI({
    if(input$line == TRUE) {
      h6("Note: The correlation coefficient is a measure that determines how closely related the measurements
       of two variables are. When the correlation is greater than zero, it signifies that both variables 
         move in the same direction or are correlated. When the correlation is 1, it signifies 
         that when one variable moves higher or lower, the other variable moves in the same direction 
         with the same magnitude. The closer the value of the correlation to 1, the stronger the linear relationship;
         the farther the value of the correlation to 1, the weaker the linear relationship." %>%
      tags$br() %>% tags$br() %>%
      h6("Read more on ", tags$a(href = "https://www.investopedia.com/ask/answers/032515/what-does-it-mean-if-correlation-coefficient-positive-negative-or-zero.asp", "correlation")))
    }
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

