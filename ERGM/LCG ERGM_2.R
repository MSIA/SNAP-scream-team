library(statnet)

###############################################################################
# Reading in data
###############################################################################

setwd('/Users/louisgenereux/Desktop/Term 4/Social_networks/Project')
list.files() # List the files in the current working directory to see if you're in the right directory

# Read in data on pairs of groups
# dat <- read.csv('group_pairs.csv')
dat <- read.csv('segment/SEGMENT_group_pairs_Christian_metal.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_deathcore.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_doom_metal.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_early.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_glam_metal_bands_and_a.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_grindcore.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_groove_metal.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_industrial_metal.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_metalcore.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_new_wave_of_British_heavy_metal.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_nu_metal.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_progressive_metal.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_speed_metal.csv')
# dat <- read.csv('segment/SEGMENT_group_pairs_symphonic_metal.csv')

# Read in summary by group (all group features)
# group_details <- read.csv("group_features_with_numbered_groups.csv", stringsAsFactors=FALSE)
group_details <-read.csv('segment/SEGMENT_group_features_Christian_metal.csv', stringsAsFactors=FALSE)
# group_details <-read.csv('segment/SEGMENT_group_features_deathcore.csv', stringsAsFactors=FALSE)
# group_details <-read.csv('segment/SEGMENT_group_features_doom_metal.csv', stringsAsFactors=FALSE)
# group_details <-read.csv('segment/SEGMENT_group_features_early.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_glam_metal_bands_and_a.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_grindcore.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_groove_metal.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_industrial_metal.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_metalcore.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_new_wave_of_British_heavy_metal.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_nu_metal.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_progressive_metal.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_speed_metal.csv', stringsAsFactors=FALSE )
# group_details <-read.csv('segment/SEGMENT_group_features_symphonic_metal.csv', stringsAsFactors=FALSE )

###############################################################################
# Creating network from group-group pairings
###############################################################################

colab <- as.network.matrix(dat, matrix.type="edgelist", directed=F)

###############################################################################
# Adding attributes (NEW)
###############################################################################

# Add vertex attributes - NUMERIC
set.vertex.attribute(colab, "Group_popularity", group_details$Group_popularity)
set.vertex.attribute(colab, "Group_follower", group_details$Group_followers)
set.vertex.attribute(colab, "count_albums", group_details$count_albums)
set.vertex.attribute(colab, "mean_tracks_per_album", group_details$mean_tracks_per_album)
set.vertex.attribute(colab, "total_tracks", group_details$total_tracks)
set.vertex.attribute(colab, "longevity", group_details$longevity)
set.vertex.attribute(colab, "mean_tracks_per_album", group_details$mean_tracks_per_album)
set.vertex.attribute(colab, "mean_song_length", group_details$mean_song_length)
set.vertex.attribute(colab, "min_song_popularity", group_details$min_song_popularity)
set.vertex.attribute(colab, "max_song_popularity", group_details$max_song_popularity)
set.vertex.attribute(colab, "song_popularity_range", group_details$song_popularity_range)
set.vertex.attribute(colab, "mean_song_danceability", group_details$mean_song_danceability)
set.vertex.attribute(colab, "mean_song_energy", group_details$mean_song_energy)

# Add vertex attributes - QUALITATIVE
set.vertex.attribute(colab, "genre",group_details$genre)
set.vertex.attribute(colab, "current_activity",group_details$attr)
set.vertex.attribute(colab, "origin",group_details$origin_clean)

get.vertex.attribute(colab,"origin")
get.vertex.attribute(colab,"Group_popularity")


###############################################################################
# Network information
###############################################################################

summary(colab)                
network.size(colab)                 # print out the network size
betweenness(colab)                  # calculate betweenness for the network
isolates(colab)                     # find the isolates in the network


###############################################################################
# Visualizing network
###############################################################################

plot(colab, 
     main="Music colab", 
     cex.main=0.8, 
     #label = network.vertex.names(colab)
     ) 

###############################################################################
# ERGM
###############################################################################

options(ergm.loglik.warn_dyads=FALSE)
# control.ergm(MCMLE.density.guard=20000)

# Simplest model
summary(colab ~ edges) 

# Model 1
model1 <- ergm(colab ~ edges)
summary(model1) 

# Model 2
model2 <- ergm(colab ~ 
                 edges +
                 diff('Group_popularity') + 
                 absdiff("Group_popularity")   +
                 nodecov('Group_popularity')) 
summary(model2) 


###############################################################################
# Comparing models
###############################################################################

# Easy side-by-side model comparison:
library(texreg)
screenreg(list("model1"=model1,"model2"=model2))


###############################################################################
# Goodness of fit
###############################################################################

# -------------------------------------------------------------------------------------------------
# Goodness of fit test
# Check how well the estimated model captures certain features of the observed network, for example triangles in the network.
# -------------------------------------------------------------------------------------------------
# This first command simulates 100 networks.
# These networks, if we use sufficient burnin steps in the markov chain used to generate them,
# may be thought of as random samples from the joint probability distribution that is our fitted ERGM.

model <- model2

sim <- simulate(model, burnin=100000, interval=100000, nsim=100, verbose=T)  # Uses the ergm model to simulate a null model


# Plot the first of the simulated networks
sim1_net <- igraph::graph.adjacency(as.matrix.network(sim[[1]]))
colab_igraph <- igraph::graph.adjacency(as.matrix.network(colab)) # make an igraph network object from statnet network object
net_layout <- igraph::layout_with_fr(colab_igraph) # spring-embedded layout

igraph::plot.igraph(sim1_net,layout=net_layout,edge.color="brown",  
                    vertex.color = 'grey',edge.arrow.size=.4)                                                               

# Plot the 10th simulated network
sim10_net <- igraph::graph.adjacency(as.matrix.network(sim[[10]]))
igraph::plot.igraph(sim10_net,layout=net_layout,edge.color="purple",  
                    vertex.color = 'grey',edge.arrow.size=.4)                                                                 

# -------------------------------------------------------------------------------------------------
# Extract the number of triangles from each of the 100 samples and
# compare the distribution of triangles in the sampled networks with the observed network
# -------------------------------------------------------------------------------------------------
model.tridist <- sapply(1:100, function(x) summary(sim[[x]] ~triangle)) # Extracts the tiangle data from the simulated networks
hist(model.tridist,xlim=c(0,1000),breaks=10)                             # Plots that triangle distribution as a histogram, change xlim to change the x-axis range if necessary
colab.tri <- summary(colab ~ triangle)                                  # Saves the CRIeq triangle data from the summary to the CRI.eq variable
colab.tri
arrows(colab.tri,20, colab.tri, 5, col="red", lwd=3)                    # Adds an arrow to the plotted histogram
c(obs=colab.tri,mean=mean(model.tridist),sd=sd(model.tridist),
  tstat=abs(mean(model.tridist)-colab.tri)/sd(model.tridist))

# -------------------------------------------------------------------------------------------------
# Test the goodness of fit of the model
# Compiles statistics for these simulations as well as the observed network, and calculates p-values 
# -------------------------------------------------------------------------------------------------
# This first command runs goodness of fit testing
# It may take a second for this command to run.
gof <- gof(model, verbose=T, burnin=1e+5, interval=1e+5, control = control.gof.ergm(nsim = 200))
# If you run below and then wouldn't see the plot, trypar(mar=c(2,2,2,2))
plot(gof)           # Plot the goodness of fit
# Note: this should produce five separate plots that you should look through.
gof                 # Display the goodness of fit info in the console



