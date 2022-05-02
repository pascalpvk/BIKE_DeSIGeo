# attention à l'adresse lors du chargement des tables #

################################################################################
################################################################################
##                                                                            ##
##                             I. premiers pas                                ##
##                                                                            ##
################################################################################
################################################################################

############################
### chargement des table ###
############################

data_ame_01 <- read.csv('C:/Users/maryc/OneDrive/Bureau/projet_continuite/01/com_bud_ame_01.csv')
data_ame_91 <- read.csv('C:/Users/maryc/OneDrive/Bureau/projet_continuite/91/com_bud_ame_91.csv')

#############################################################################
### creation d'une table 'totale' des 2 autres + retrait velo_rue inutile ###
#############################################################################

data_ame_91 <- data_ame_91[,- 17]

data_ame_tot <- rbind(data_ame_01,data_ame_91)

###################################
### on selectionnes des donnees ###
###################################

sel_01 <- subset(data_ame_01, 
               select = c(population, surface_ha, produits_total,
                          piste_cyclable, voie_verte, long_tot, densite_pop,
                          budget_p_hab, budget_p_ha, tot_foret_km2))

sel_91 <- subset(data_ame_91, 
                 select = c(population, surface_ha, produits_total,
                            piste_cyclable, voie_verte, long_tot, densite_pop,
                            budget_p_hab, budget_p_ha, tot_foret_km2))

sel_tot <- subset(data_ame_tot, 
                 select = c(population, surface_ha, produits_total,
                            piste_cyclable, voie_verte, long_tot, densite_pop,
                            budget_p_hab, budget_p_ha, tot_foret_km2))

###################################
### categorisation des communes ###
###################################

cat <- function(x) { 
  if(x < 1000) y <- "Pte"
  if(x >= 1000 & x < 10000) y <- "Moy"
  if(x >= 10000) y <- "Gde"
  return(y)
}

sel_01$cat_com <- sapply(sel_01$population,cat)
sel_91$cat_com <- sapply(sel_91$population,cat)
sel_tot$cat_com <- sapply(sel_tot$population,cat)

####################################################
### on change les noms de colonne :              ###
### pour ameliorer la lecture dans le plot final ###
### (avec legende, du coup)                      ###
####################################################

names(sel_01)[8] <- "budget_hab" #budget_p_hab
names(sel_01)[9] <- "budget_ha" #budget_p_ha
names(sel_01)[10] <- "foret_km2" #tot_foret_km2

names(sel_91)[8] <- "budget_hab" #budget_p_hab
names(sel_91)[9] <- "budget_ha" #budget_p_ha
names(sel_91)[10] <- "foret_km2" #tot_foret_km2

names(sel_tot)[8] <- "budget_hab" #budget_p_hab
names(sel_tot)[9] <- "budget_ha" #budget_p_ha
names(sel_tot)[10] <- "foret_km2" #tot_foret_km2

###################################
### on retire quelques extremes ###
###################################

################
### table 01 ###
################

max(sel_01$population)
sel_01 <- sel_01[sel_01[,1] != 41248,]
sel_01 <- sel_01[sel_01[,10] < 50,]
sel_01 <- sel_01[sel_01[,6] < 50,]

################
### table 02 ###
################

max(sel_91$population)
sel_91 <- sel_91[sel_91[,1] < 50000,]
sel_91 <- sel_91[sel_91[,10] < 15,]

#################
### table tot ###
#################

sel_tot <- sel_tot[sel_tot[,1] < 50000,]
sel_tot <- sel_tot[sel_tot[,10] < 50,]
sel_tot <- sel_tot[sel_tot[,6] < 50,]

############################################
### on affiche 1 plot simple pour chaque ###
############################################

plot(sel_01)
plot(sel_91)
plot(sel_tot)

plot(sel_01$"8",sel_01$"6")

#####################################################
### on affiche plus complet + couleur pour chaque ###
#####################################################

install.packages("GGally")
library("GGally")

ggpairs(sel_01) # test initial de ggpairs #

ggpairs(
  sel_01,
  title="Scatterplot des principales variables",
  columns = c(1,2,3,4,5,6,7,8,9,10),
  mapping=ggplot2::aes(colour = cat_com)
)

ggpairs(
  sel_91,
  title="Scatterplot des principales variables",
  columns = c(1,2,3,4,5,6,7,8,9,10),
  mapping=ggplot2::aes(colour = cat_com)
)

ggpairs(
  sel_tot,
  title="Scatterplot des principales variables",
  columns = c(1,2,3,4,5,6,7,8,9,10),
  mapping=ggplot2::aes(colour = cat_com)
)

# --> The diagonal consists of the densities of the three variables and the    #
# upper panels consist of the correlation coefficients between the variables.  #

####################################################
### autres test de representations, non retenues ###
####################################################

#############
### pairs ###
#############

pairs(sel_01, col="darkcyan")

# --> équivalent de plot #

##############
### ggplot ###
##############

p3 <- ggplot(sel_01)+
  geom_point(aes(x=population, y=surface_ha), color="darkcyan")+
  theme_light()+
  xlab("Population") + ylab("Surface en ha")
p3
# --> un plot simple en couleur #


################################################################################
################################################################################
##                                                                            ##
##                        II. regression lineaire                             ##
##                                                                            ##
################################################################################
################################################################################

install.packages("car")
library(car)

#############################
### regression lineaire 1 ###
#############################

scatterplot(population~produits_total, data = data_ame_01)
scatterplot(long_tot~produits_total, data = data_ame_01)
scatterplot(long_tot~population, data = data_ame_01)
scatterplot(long_tot~budget_p_hab, data = data_ame_01)

#############################
### regression lineaire 2 ###
############################

### creation fonction ###

reg_00 <- lm(population~produits_total, data = data_ame_01)
reg_01 <- lm(long_tot~produits_total, data = data_ame_01)
reg_02 <- lm(long_tot~population, data = data_ame_01)
reg_03 <- lm(long_tot~budget_p_hab, data = data_ame_01)


### calcul des residus ###

acf(residuals(reg_00), main = "reg 00")
acf(residuals(reg_01), main = "reg 01")
acf(residuals(reg_02), main = "reg 02")
acf(residuals(reg_03), main = "reg 03")


### test durbin watson ###

durbinWatsonTest (reg_00)
durbinWatsonTest (reg_01)
durbinWatsonTest(reg_02)
durbinWatsonTest(reg_03)

### trace ###

plot(reg_00, 2)
plot(reg_01, 2)
plot(reg_02, 2)
plot(reg_03, 2)


################################################################################
################################################################################
##                                                                            ##
##                            III. multi-varie                                ##
##                                                                            ##
################################################################################
################################################################################


install.packages("magrittr")  # pour le pipe %>%
install.packages("ade4")      # Calcul de l'ACP
install.packages("factoextra")# Visualisation  de l'ACP

library(ade4)
library(factoextra)
library(magrittr)


                                ##################
                                ### avec l'ain ###
                                ##################

sel_01 <- subset(data_ame_01, 
                 select = c(population, surface_ha, produits_total,
                            piste_cyclable, voie_verte, long_tot, densite_pop,
                            budget_p_hab, budget_p_ha, tot_foret_km2))

sel_01[is.na(sel_01)] <- 0

res_pca_01 <- dudi.pca(sel_01,
                    scannf = FALSE,   # Cacher le scree plot
                    nf = 5            # Nombre d'axes gardes
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca_01)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de representation).   ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

indiv_01 <- fviz_pca_ind(res_pca_01,
             col.ind = "cos2",
             title = "Graphique des individus de l'Ain",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv_01

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

graph_01 <- fviz_pca_var(res_pca_01,
             col.var = "contrib", 
             title = "Graphiques des variables de l'Ain",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

graph_01

#############################################
### Biplot des individus et des variables ###
#############################################

biplot_01 <- fviz_pca_biplot(res_pca_01, repel = TRUE,
                             title = "Biplot de l'Ain",
                col.var = "#2E9FDF", 
                col.ind = "#696969"  
)

biplot_01

###############################################
### Visualisation avec ade4 (noir et blanc) ###
###############################################

# Valeurs propres #

screeplot(res_pca_01, main = "Screeplot - Eigenvalues")

# Cercle de correlation des variables #

s.corcircle(res_pca_01$co)

# Graphique des individus (lignes) #

s.label(res_pca_01$li, 
        xax = 1,     # Dimension 1
        yax = 2)     # Dimension 2

# Biplot des individus et des variables #

scatter(res_pca_01,
        posieig = "none", # Cacher le scree plot
        clab.row = 0      # CachÃ© l'annotation des lignes
)

                            ######################
                            ### avec l'essonne ###
                            ######################

sel_91 <- subset(data_ame_91, 
                 select = c(population, surface_ha, produits_total,
                            piste_cyclable, voie_verte, long_tot, densite_pop,
                            budget_p_hab, budget_p_ha, tot_foret_km2))

sel_91[is.na(sel_91)] <- 0

res_pca_91 <- dudi.pca(sel_91,
                       scannf = FALSE,   # Cacher le scree plot
                       nf = 5            # Nombre d'axes gardÃ©s
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca_91)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de reprsentation).    ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

indiv_91 <- fviz_pca_ind(res_pca_91,
             col.ind = "cos2", 
             title = "Graphique des individus de l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv_91

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

varia_91 <- fviz_pca_var(res_pca_91,
             col.var = "contrib", 
             title = "Graphique des variables de l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

varia_91

#############################################
### Biplot des individus et des variables ###
#############################################

biplot91 <- fviz_pca_biplot(res_pca_91, repel = TRUE,
                            title = "Biplot de l'Essonne",
                col.var = "#2E9FDF", 
                col.ind = "#696969"  
)

biplot_91

###############################
### Visualisation avec ade4 ###
###############################

# Valeurs propres #

screeplot(res_pca_91, main = "Screeplot - Eigenvalues")

# Cercle de correlation des variables #

s.corcircle(res_pca_01$co)

# Graphique des individus (lignes) #

s.label(res_pca_91$li, 
        xax = 1,     # Dimension 1
        yax = 2)     # Dimension 2

# Biplot des individus et des variables #

scatter(res_pca_91,
        posieig = "none", # Cacher le scree plot
        clab.row = 0      # Cache l'annotation des lignes
)



                                #####################
                                ### avec les deux ###
                                #####################

sel_tot <- subset(data_ame_tot, 
                  select = c(population, surface_ha, produits_total,
                             piste_cyclable, voie_verte, long_tot, densite_pop,
                             budget_p_hab, budget_p_ha, tot_foret_km2))

sel_tot[is.na(sel_tot)] <- 0

res_pca_tot <- dudi.pca(sel_tot,
                       scannf = FALSE,   # Cacher le scree plot
                       nf = 5            # Nombre d'axes gardÃ©s
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca_tot)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de representation).   ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

indiv_01_91 <- fviz_pca_ind(res_pca_tot,
             col.ind = "cos2",
             title = "Graphique des individus Ain + Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv_01_91

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

varia_01_91 <- fviz_pca_var(res_pca_tot,
             col.var = "contrib", 
             title = "Graphique des variables Ain + Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

varia_01_91

#############################################
### Biplot des individus et des variables ###
#############################################

biplo_01_91 <- fviz_pca_biplot(res_pca_tot, repel = TRUE,
                col.var = "#2E9FDF", 
                col.ind = "#696969"  
)

biplo_01_91

###############################
### Visualisation avec ade4 ###
###############################

# Valeurs propres #

screeplot(res_pca_tot, main = "Screeplot - Eigenvalues")

# Cercle de correlation des variables #

s.corcircle(res_pca_tot$co)

# Graphique des individus (lignes) #

s.label(res_pca_tot$li, 
        xax = 1,     # Dimension 1
        yax = 2)     # Dimension 2

# Biplot des individus et des variables #

scatter(res_pca_tot,
        posieig = "none", # Cacher le scree plot
        clab.row = 0      # Cache l'annotation des lignes
)


            ##########################################################
            ##########################################################
            ###                                                    ###
            ### III.2 En enlevant une partie des donnees choisies  ###
            ###   (les donnees les moins correlees, a priori)      ###
            ###                                                    ###
            ##########################################################
            ##########################################################

################################################################################
# selection sans surface_ha, tot_foret_km2, densite_pop, budget_p_ha + NA -> 0 #
################################################################################

sel2_01 <- subset(data_ame_01, 
                  select = c(population, produits_total, piste_cyclable,
                             voie_verte, long_tot, budget_p_hab))
sel2_01[is.na(sel2_01)] <- 0

sel2_91 <- subset(data_ame_91, 
                  select = c(population, produits_total, piste_cyclable,
                             voie_verte, long_tot, budget_p_hab))
sel2_91[is.na(sel2_91)] <- 0

sel2_tot <- subset(data_ame_tot, 
                   select = c(population, produits_total, piste_cyclable,
                              voie_verte, long_tot, budget_p_hab))
sel2_tot[is.na(sel2_tot)] <- 0

                            ##################
                            ### avec l'ain ###
                            ##################

res_pca2_01 <- dudi.pca(sel2_01,
                        scannf = FALSE,   # Cacher le scree plot
                        nf = 5            # Nombre d'axes gardÃ©s
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca2_01)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de representation).   ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

indiv2_01 <- fviz_pca_ind(res_pca2_01,
             col.ind = "cos2", 
             title = "Graphique simplifié des individus de l'Ain",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv2_01

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

varia2_01 <- fviz_pca_var(res_pca2_01,
             col.var = "contrib", 
             title = "Graphique simplifié des variables de l'Ain",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

varia2_01

                          ######################
                          ### avec l'essonne ###
                          ######################

res_pca2_91 <- dudi.pca(sel2_91,
                        scannf = FALSE,   # Cacher le scree plot
                        nf = 5            # Nombre d'axes gardÃ©s
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca2_91)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de representation).   ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

indiv2_91 <- fviz_pca_ind(res_pca2_91,
             col.ind = "cos2", 
             title = "Graphique simplifié des individus de l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv2_91

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

varia2_91 <- fviz_pca_var(res_pca2_91,
             col.var = "contrib", 
             title = "Graphique simplifié des variables de l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

varia2_91

                        ######################
                        ### pour les deux  ###
                        ######################

res_pca2_tot <- dudi.pca(sel2_tot,
                        scannf = FALSE,   # Cacher le scree plot
                        nf = 5            # Nombre d'axes gardÃ©s
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca2_tot)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de representation).   ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

varia2_01_91 <- fviz_pca_ind(res_pca2_tot,
             col.ind = "cos2", 
             title = "Graphique simplifié des individus de l'Ain et de l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

varia2_01_91

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

indiv2_01_91 <- fviz_pca_var(res_pca2_tot,
             col.var = "contrib",
             title = "Graphique simplifié des variables de l'Ain et de l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv2_01_91

                ##########################################################
                ##########################################################
                ###                                                    ###
                ###  III.3 en faisant une autre selection des donnees  ###
                ###       ( pas de rapport entre les autres )          ###
                ###                                                    ###
                ##########################################################
                ##########################################################


################################################################################
# selection sans surface_ha, tot_foret_km2, densite_pop, budget_p_ha + NA -> 0 #
################################################################################

sel2_01 <- subset(data_ame_01, 
                  select = c(population, surface_ha, produits_total,
                             piste_cyclable, voie_verte, long_tot,
                             tot_foret_km2))
sel2_01[is.na(sel2_01)] <- 0

sel2_91 <- subset(data_ame_91, 
                  select = c(population, surface_ha, produits_total,
                             piste_cyclable, voie_verte, long_tot,
                             tot_foret_km2))
sel2_91[is.na(sel2_91)] <- 0

sel2_tot <- subset(data_ame_tot, 
                   select = c(population, surface_ha, produits_total,
                              piste_cyclable, voie_verte, long_tot,
                              tot_foret_km2))
sel2_tot[is.na(sel2_tot)] <- 0

                        ##################
                        ### avec l'ain ###
                        ##################

res_pca2_01 <- dudi.pca(sel2_01,
                        scannf = FALSE,   # Cacher le scree plot
                        nf = 5            # Nombre d'axes gardÃ©s
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca2_01)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de representation).   ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

indiv3_01 <- fviz_pca_ind(res_pca2_01,
             col.ind = "cos2",
             title = "Graphique final des individus de l'Ain",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv3_01

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

varia3_01 <- fviz_pca_var(res_pca2_01,
             col.var = "contrib", 
             title = "Graphique final des variables de l'Ain",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

varia3_01

                          ######################
                          ### avec l'essonne ###
                          ######################

res_pca2_91 <- dudi.pca(sel2_91,
                        scannf = FALSE,   # Cacher le scree plot
                        nf = 5            # Nombre d'axes gardÃ©s
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca2_91)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de representation).   ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

indiv3_91 <- fviz_pca_ind(res_pca2_91,
             col.ind = "cos2", 
             title = "Graphique final des individus de l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv3_91

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

varia3_91 <- fviz_pca_var(res_pca2_91,
             col.var = "contrib", 
             title = "Graphique final des variables de l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

varia3_91

                          #####################
                          ### pour les deux ###
                          #####################

res_pca2_tot <- dudi.pca(sel2_tot,
                         scannf = FALSE,   # Cacher le scree plot
                         nf = 5            # Nombre d'axes gardÃ©s
)

###################################
### visualisation du scree plot ###
###################################

fviz_eig(res_pca2_tot)

#####################################################################
### Graphique des individus.                                      ###
### Coloration en fonction du cos2 (qualite de representation).   ###
### Les individus similaires sont groupes ensemble.               ###
#####################################################################

indiv3_01_91 <- fviz_pca_ind(res_pca2_tot,
             col.ind = "cos2",
             title = "Graphique final des individus de l'Ain et l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

indiv3_01_91

################################################################################
### Graphique des variables.                                                 ###
### Coloration en fonction de la contribution des variables.                 ###
### Les variables correlees positivement sont du meme cote du graphique.     ###
# Les variables correlees negativement sont sur des cotes opposes du graphique #
################################################################################

varia3_01_91 <- fviz_pca_var(res_pca2_tot,
             col.var = "contrib", 
             title = "Graphique final des variables de l'Ain et l'Essonne",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     
)

varia3_01_91


