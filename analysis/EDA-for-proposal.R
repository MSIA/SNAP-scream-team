library(igraph)
library(jsonlite)
library(rjson)
library(data.table)

df <- read.csv('all_data.csv')

# create attribute df in order to color the nodes
attr_df <- stack(df[c('member', 'band')])
attr_df <- attr_df[!duplicated(attr_df$values), ] # remove duplicate bands

network <- graph.data.frame(df[c('member', 'band')], vertices=attr_df, directed=F)
g <- simplify(network, remove.multiple=T, remove.loops=T)

vcount(g) ## the number of nodes/actors/users
ecount(g) ## the number of edges

# the node with max degrees
V(g)$name[degree(g)==max(degree(g))]

# Take out a giant component from the graph (gg for 'giant graph')
comp <- components(g)
gg <- g %>% 
  induced.subgraph(., which(comp$membership == which.max(comp$csize)))
vcount(gg) ## the number of nodes/actors/users
ecount(gg) ## the number of edges

nodes <- c()
edges <- c()
maxdegree <- c()

# analyze each genre as its own network
genres <- unique(df$genre)
for(gen in genres){
  print(paste('\n', gen))
  subgenre <- setDT(df)[genre == gen, .(member, band)]
  subnetwork <- graph.data.frame(subgenre, directed=F)

  subg <- simplify(subnetwork, remove.multiple=T, remove.loops=T)
  nodes <- c(nodes, vcount(subg))
  edges <- c(edges, ecount(subg))
  maxdegree <- c(maxdegree, V(subg)$name[degree(subg)==max(degree(subg))])
}

# create visualizations for doom metal bands, as an example
subgenre <- setDT(df)[genre == '/wiki/List_of_doom_metal_bands', .(member, band)]

# create attribute df in order to color the nodes
attr_df <- stack(df[genre == '/wiki/List_of_doom_metal_bands', c('member', 'band')])
attr_df <- attr_df[!duplicated(attr_df$values), ] # remove duplicate bands

subnetwork <- graph.data.frame(subgenre, vertices=attr_df, directed=F)
subg <- simplify(subnetwork, remove.multiple=T, remove.loops=T)
V(subg)$color <- ifelse(V(subg)$ind == 'member', "aquamarine3", "blueviolet")

subg %>%
  plot(.,
       vertex.size = 2.5,
       vertex.frame.color = 'white',
       vertex.label = NA,
       edge.arrow.size = .1,
       layout = layout_with_kk(.)
  )

# Take out a giant component from the graph
comp <- components(subg)
gg <- subg %>% 
  induced.subgraph(., which(comp$membership == which.max(comp$csize)))

gg %>%
  plot(.,
       vertex.size = 2.5,
       vertex.frame.color = 'white',
       vertex.label = NA,
       vertex.label.cex = .5,
       edge.arrow.size = .1,
       layout = layout_with_kk(.)
  )

