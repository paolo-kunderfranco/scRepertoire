#' Quantify the unique clonotypes in the filtered contigs.
#'
#' This function takes the output from combineTCR(), combineBCR(), or e
#' xpression2List() and quantifies unique clonotypes. The unique clonotypes 
#' can be either reported as a raw output or scaled to the total number of 
#' clonotypes recovered using the scale parameter. Multiple sequencing 
#' runs can be group together using the group parameter. If a matrix output 
#' for the data is preferred, set exportTable = TRUE.
#'
#' @examples
#' #Making combined contig data
#' x <- contig_list
#' combined <- combineTCR(x, rep(c("PX", "PY", "PZ"), each=2), 
#' rep(c("P", "T"), 3), cells ="T-AB")
#' quantContig(combined, cloneCall="gene+nt", scale = TRUE)
#'
#' @param df The product of combineTCR() combineBCR() or expression2List().
#' @param cloneCall How to call the clonotype - CDR3 gene (gene), 
#' CDR3 nucleotide (nt), CDR3 amino acid (aa), or 
#' CDR3 gene+nucleotide (gene+nt).
#' @param group The column header used for grouping.
#' @param scale Converts the graphs into percentage of unique clonotypes.
#' @param exportTable Returns the data frame used for forming the graph,
#' @import ggplot2
#' @export
#' @return ggplot of the total or relative unique clonotypes
quantContig <- function(df, cloneCall = "gene+nt", scale=FALSE, group = NULL, 
                    exportTable = FALSE) {
    if (length(group) > 1) { stop("Only one item in the group variable can 
                                    be listed.") }
    cloneCall <- theCall(cloneCall)
    if (!is.null(group)) {
        x <- group
        labs <- group
        Con.df <- data.frame(matrix(NA, length(df), 4))
        colnames(Con.df) <- c("contigs","values", "total", group)
        for (i in seq_along(df)) {
            Con.df[i,1] <- length(unique(df[[i]][,cloneCall]))
            Con.df[i,2] <- names(df)[i]
            Con.df[i,3] <- length(df[[i]][,cloneCall])
            location <- which(colnames(df[[i]]) == group)
            Con.df[i,4] <- df[[i]][1,location] }
        col <- length(unique(Con.df[,group]))
        if (scale == TRUE) { y <- "scaled"
            Con.df$scaled <- Con.df$contigs/Con.df$total*100
            ylab <- "Percent of Unique Clonotype"

        } else { y <- "contigs"
            x <- group
            ylab <- "Unique Clonotypes"}
    } else {
        x <- "values"
        labs <- "Samples"
        Con.df <- data.frame(matrix(NA, length(df), 3))
        colnames(Con.df) <- c("contigs","values", "total")
        for (i in seq_along(df)) {
            Con.df[i,1] <- length(unique(df[[i]][,cloneCall]))
            Con.df[i,2] <- names(df)[i]
            Con.df[i,3] <- length(df[[i]][,cloneCall]) }
        col <- length(unique(Con.df$values))
        if (scale == TRUE) { y <- "scaled"
            Con.df$scaled <- Con.df$contigs/Con.df$total*100
            ylab <- "Percent of Unique Clonotype"
        } else { y <- "contigs"
            ylab <- "Unique Clonotypes" } }
    if (exportTable == TRUE) { return(Con.df) }
    plot <- ggplot(aes(x=Con.df[,x], y=Con.df[,y],
            fill=as.factor(Con.df[,x])), data = Con.df) +
        stat_summary(geom = "errorbar", fun.data = mean_se, 
            position = "dodge", width=.5) + labs(fill = labs) +
        stat_summary(fun.y=mean, geom="bar", color="black", lwd=0.25)+
        theme_classic() + xlab("Samples") + ylab(ylab) +
        scale_fill_manual(values = colorblind_vector(col))
    return(plot) }


#' Demonstrate the relative abundance of clonotypes by group or sample.
#'
#' This function takes the output of combineTCR(), combineBCR(), or 
#' expression2List() and displays the number of clonotypes at specific 
#' frequencies by sample or group. Visualization can either be a line 
#' graph using calculated numbers or if scale = TRUE, the output will 
#' be a density plot. Multiple sequencing runs can be group together 
#' using the group parameter. If a matrix output for the data is 
#' preferred, set exportTable = TRUE.
#'
#' @examples
#' #Making combined contig data
#' x <- contig_list
#' combined <- combineTCR(x, rep(c("PX", "PY", "PZ"), each=2), 
#' rep(c("P", "T"), 3), cells ="T-AB")
#' abundanceContig(combined, cloneCall = "gene", scale = FALSE)
#'
#' @param df The product of combineTCR(), combineBCR(), or expression2List().
#' @param cloneCall How to call the clonotype - CDR3 gene (gene), 
#' CDR3 nucleotide (nt), CDR3 amino acid (aa), or C
#' DR3 gene+nucleotide (gene+nt).
#' @param group The column header for which you would like to analyze the data.
#' @param scale Converts the graphs into denisty plots in order to show 
#' relative distributions.
#' @param exportTable Exports a table of the data into the global 
#' environment in addition 
#' to the visualization.
#' @importFrom ggplot2 ggplot
#' @export
#' @return ggplot of the total or relative adundance of clonotypes 
#' across quanta
abundanceContig <- function(df, cloneCall = "gene+nt", scale=FALSE, 
                        group = NULL, exportTable = FALSE) {
    Con.df <- NULL
    xlab <- "Abundance"
    cloneCall <- theCall(cloneCall)
    names <- names(df)
    if (!is.null(group)) {
        for (i in seq_along(df)) {
            data1 <- parseContigs(df, i, names, cloneCall)
            label <- df[[i]][1,group]
            data1[,paste(group)] <- label
            Con.df<- rbind.data.frame(Con.df, data1) }
        Con.df <- data.frame(Con.df)
        col <- length(unique(Con.df[,group]))
        fill <- group
        if (scale == TRUE) { ylab <- "Density of Clonotypes"
            plot <- ggplot(Con.df, aes(x=Abundance, fill=Con.df[,group])) +
                geom_density(aes(y=..scaled..), alpha=0.5, 
                    lwd=0.25, color="black", bw=0.5)  +
                scale_fill_manual(values = colorblind_vector(col)) +
                labs(fill = fill)
        } else { ylab <- "Number of Clonotypes"
            plot <- ggplot(Con.df, aes(x=Abundance, group = values, 
                    color = Con.df[,group])) +
                geom_line(stat="count") +
                scale_color_manual(values = colorblind_vector(col)) +
                labs(color = fill)}
    } else{
        for (i in seq_along(df)) {
            data1 <- parseContigs(df, i, names, cloneCall)
            Con.df<- rbind.data.frame(Con.df, data1) }
        col <- length(unique(Con.df$values))
        fill <- "Samples"
        if (scale == TRUE) { ylab <- "Density of Clonotypes"
            plot <- ggplot(Con.df, aes(Abundance, fill=values)) +
                geom_density(aes(y=..scaled..), alpha=0.5, lwd=0.25, 
                    color="black", bw=0.5) +
                scale_fill_manual(values = colorblind_vector(col)) +
                labs(fill = fill)
        } else { ylab <- "Number of Clonotypes"
            plot <- ggplot(Con.df, aes(x=Abundance, group = values, 
                    color = values)) +
                geom_line(stat="count") +
                scale_color_manual(values = colorblind_vector(col)) +
                labs(color = fill)} }
    if (exportTable == TRUE) { return(Con.df)}
    plot <- plot + scale_x_log10() + ylab(ylab) + xlab(xlab) +
        theme_classic()
return(plot) }

#' Demonstrate the distribution of lengths filtered contigs.
#'
#' This function takes the output of combineTCR(), combineBCR(), or
#' expression2List() and displays either the nucleotide (nt) or amino 
#' acid (aa) sequence length. The sequence length visualized can be 
#' selected using the chains parameter, either the combined clonotype 
#' (both chains) or across all single chains. Visualization can either 
#' be a histogram or if scale = TRUE, the output will be a density plot. 
#' Multiple sequencing runs can be group together using the 
#' group parameter. If a matrix output for the data is preferred, set 
#' exportTable = TRUE.
#'
#' @examples
#' #Making combined contig data
#' x <- contig_list
#' combined <- combineTCR(x, rep(c("PX", "PY", "PZ"), each=2), 
#' rep(c("P", "T"), 3), cells ="T-AB")
#' lengthContig(combined, cloneCall="aa", chains = "combined")
#'
#' @param df The product of combineTCR(), combineBCR(), or expression2List()
#' @param cloneCall How to call the clonotype - CDR3 nucleotide (nt), 
#' CDR3 amino acid (aa).
#' @param group The group header for which you would like to analyze 
#' the data.
#' @param scale Converts the graphs into denisty plots in order to show 
#' relative distributions.
#' @param chains Whether to keep clonotypes "combined" or visualize
#'  by chain.
#' @param exportTable Returns the data frame used for forming the graph.
#' @importFrom stringr str_split
#' @importFrom ggplot2 ggplot
#' @export
#' @return ggplot of the discrete or relative length distributions of 
#' clonotype sequences
lengthContig <- function(df, cloneCall = "aa", group = NULL, scale = FALSE, 
                    chains = "combined", exportTable = FALSE) {
    if(cloneCall == "nt") { cloneCall <- "CTnt"
        ylab <- "CDR3 (NT)"
    } else if (cloneCall == "aa") { cloneCall <- "CTaa" 
        ylab <- "CDR3 (AA)"
    } else { stop("Please make a selection of the type of
                CDR3 sequence to analyze by using `cloneCall`") }
    cells <- df[[1]][1,"cellType"]
    c1 <- cellT(cells)[[1]]
    c2 <- cellT(cells)[[2]]
    xlab <- "Length"
    Con.df <- NULL
    Con.df <- lengthDF(df, cloneCall, chains, group, c1, c2)
    names <- names(df)
    if (!is.null(group)) { 
        fill = group
        col <- length(unique(Con.df[,group]))
        if (scale == TRUE) { yplus <- "Percent of "
            plot <- ggplot(Con.df, aes(fill=Con.df[,group],
                length,(..count..)/sum(..count..)*100)) + 
                geom_density(aes(y=..scaled..),alpha=.5,lwd=.25,color="black")
        } else { yplus <- "Number of "
            plot<-ggplot(Con.df,aes(as.factor(length),fill=Con.df[,group]))+
                geom_bar(position = position_dodge2(preserve = "single"), 
                color="black", lwd=0.25, width=0.9)  +
                scale_x_discrete(breaks = round(seq(min(Con.df$length), 
                max(Con.df$length), by = 5),10)) }
    } else if (is.null(group)){ 
        fill <- "Samples"
        col <- length(unique(Con.df$values))
        if (scale == TRUE) { yplus <- "Percent of "
            plot <- ggplot(Con.df, aes(length, (..count..)/sum(..count..)*100, 
                fill=values)) + geom_density(aes(y=..scaled..), alpha=0.5, 
                lwd=0.25, color="black")
    }  else { yplus <- "Number of "
        plot <- ggplot(Con.df, aes(as.factor(length), fill=values)) +
            geom_bar(position = position_dodge2(preserve = "single"), 
            color="black", lwd=0.25) +
            scale_x_discrete(breaks = round(seq(min(Con.df$length), 
            max(Con.df$length), by = 5),10))} }
    if (chains == "single") { plot <- plot + facet_grid(chain~.) }
    plot <- plot + scale_fill_manual(values = colorblind_vector(col)) +
        labs(fill = fill) + ylab(paste(yplus, ylab, sep="")) +
        xlab(xlab) + theme_classic()
    if (exportTable == TRUE) { return(Con.df) }
    return(plot)}

#' Demonstrate the difference in clonal proportion between clonotypes
#'
#' This function produces an alluvial or area graph of the proportion of 
#' the indicated clonotypes for all or selected samples. Clonotypes can be 
#' selected using the clonotypes parameter with the specific sequence of 
#' interest or using the number parameter with the top n clonotypes by 
#' proportion to be visualized. If multiple clonotypes have the same proportion 
#' and are within the selection by the number parameter, all the clonotypes 
#' will be visualized. In this instance, if less clonotypes are desired, 
#' reduce the number parameter.
#'
#' @examples
#' #Making combined contig data
#' x <- contig_list
#' combined <- combineTCR(x, rep(c("PX", "PY", "PZ"), each=2), 
#' rep(c("P", "T"), 3), cells ="T-AB")
#' compareClonotypes(combined, numbers = 10, 
#' samples = c("PX_P", "PX_T"), cloneCall="aa")
#'
#' @param df The product of combineTCR(), combineBCR(), or expression2List()
#' @param cloneCall How to call the clonotype - CDR3 gene (gene), 
#' CDR3 nucleotide (nt), CDR3 amino acid (aa), or 
#' CDR3 gene+nucleotide (gene+nt).
#' @param samples The specific samples to isolate for visualization.
#' @param clonotypes The specific sequences of interest.
#' @param numbers The top number clonotype sequences.
#' @param graph The type of graph produced, either "alluvial" or "area".
#' @param exportTable Returns the data frame used for forming the graph.
#' @import ggplot2
#'
#' @export
#' @return ggplot of the proportion of total sequencing read of 
#' selecting clonotypes
compareClonotypes <- function(df, cloneCall = "gene+nt", samples = NULL, 
                        clonotypes = NULL, numbers = NULL, graph = "alluvial",
                        exportTable = FALSE){
    cloneCall <- theCall(cloneCall)
    if (!is.null(numbers) & !is.null(clonotypes)) {
        stop("Make sure your inputs are either numbers or clonotype sequences.")
    }
    Con.df <- NULL
    for (i in seq_along(df)) {
        tbl <- as.data.frame(table(df[[i]][,cloneCall]))
        tbl[,2] <- tbl[,2]/sum(tbl[,2])
        colnames(tbl) <- c("Clonotypes", "Proportion")
        tbl$Sample <- names(df[i])
        Con.df <- rbind.data.frame(Con.df, tbl)
    }
    if (!is.null(samples)) {
        Con.df <- Con.df[Con.df$Sample %in% samples,] }
    if (!is.null(clonotypes)) {
        Con.df <- Con.df[Con.df$Clonotypes %in% clonotypes,] }
    if (!is.null(numbers)) {
        top <- Con.df %>% top_n(n = numbers, wt = Proportion)
        Con.df <- Con.df[Con.df$Clonotypes %in% top$Clonotypes,] }
    if (nrow(Con.df) < length(unique(Con.df$Sample))) {
        stop("Reasses the filtering strategies here, there is not 
            enough clonotypes to examine.") }
    if (exportTable == TRUE) { return(Con.df)}
    
    plot <- ggplot(Con.df, aes(x = Sample, fill = Clonotypes, group = Clonotypes,
                    stratum = Clonotypes, alluvium = Clonotypes, 
                    y = Proportion, label = Clonotypes)) +
                theme_classic() +
                theme(axis.title.x = element_blank())
    if (graph == "alluvial") {
        plot = plot +  geom_stratum() + geom_flow(stat = "alluvium")
    } else if (graph == "area") {
        plot = plot +
            geom_area(aes(group = Clonotypes), color = "black") }
    return(plot)
}

#' Hierarchical clustering of clonotypes on clonotype size and 
#' Jensen-Shannon divergence
#'
#' This functionn produces a heirachial clustering of clonotypes by sample 
#' using the Jensen-Shannon distance and discrete gamma-GPD spliced threshold 
#' model in the [powerTCR R package]
#' (https://bioconductor.org/packages/devel/bioc/html/powerTCR.html).
#' Please read and cite PMID: 30485278 if using the function for analyses. 
#' If a matrix output for the data is preferred set exportTable = TRUE.
#'
#' @examples
#' #Making combined contig data
#' x <- contig_list
#' combined <- combineTCR(x, rep(c("PX", "PY", "PZ"), each=2), 
#' rep(c("P", "T"), 3), cells ="T-AB")
#' clonesizeDistribution(combined, cloneCall = "gene+nt", method="ward.D2")
#'
#' @param df The product of combineTCR(), combineBCR(), or expression2List().
#' @param cloneCall How to call the clonotype - CDR3 gene (gene),
#' CDR3 nucleotide (nt), CDR3 amino acid (aa), or 
#' CDR3 gene+nucleotide (gene+nt).
#' @param method The clustering paramater for the dendrogram.
#' @param exportTable Returns the data frame used for forming the graph.
#' @import dplyr
#' @importFrom ggplot2 ggplot
#' @importFrom powerTCR fdiscgammagpd get_distances
#' @importFrom ggdendro ggdendrogram
#' @export
#' @return ggplot dendrogram of the clone size distribution

clonesizeDistribution <- function(df,  cloneCall ="gene+nt", 
                            method = "ward.D2", exportTable = FALSE) {
        cloneCall <- theCall(cloneCall)
        data <- bind_rows(df)
        unique_df <- unique(data[,cloneCall])
        Con.df <- data.frame(matrix(NA, length(unique_df), length(df)))
        Con.df <- data.frame(unique_df, Con.df, stringsAsFactors = FALSE)
        colnames(Con.df)[1] <- "clonotype"
        for (i in seq_along(df)) {
            data <- df[[i]]
            data <- data.frame(table(data[,cloneCall]), 
                        stringsAsFactors = FALSE)
            colnames(data) <- c(cloneCall, "Freq")
            for (y in seq_along(unique_df)){
                    clonotype.y <- Con.df$clonotype[y]
                    location.y <- which(clonotype.y == data[,cloneCall])
                    Con.df[y,i+1] <- data[location.y[1],"Freq"] }
        }
        colnames(Con.df)[2:(length(df)+1)] <- names(df)
        Con.df[is.na(Con.df)] <- 0
        list <- list()
        for (i in seq_along(df)) {
            list[[i]] <- Con.df[,i+1]
            list[[i]] <- suppressWarnings(fdiscgammagpd(list[[i]], useq = 1))}
        names(list) <- names(df)
        grid <- 0:10000
        distances <- get_distances(list, grid, modelType="Spliced")
        hclust <- hclust(as.dist(distances), method = method)
        plot <- ggdendrogram(hclust)
        if (exportTable == TRUE) { return(distances) }
        return(plot)
}

#This is the basic color palette for the package
#' @import RColorBrewer
#' @import colorRamps
colorblind_vector <- colorRampPalette(c("#FF4B20", "#FFB433", 
                                        "#C6FDEC", "#7AC5FF", "#0348A6"))

#Making lodes to function in alluvial plots
#' @import ggalluvial
makingLodes <- function(meta2, color, alpha, facet, set.axes) {
    if (!is.null(color) & !is.null(alpha) & !is.null(facet)) {
        lodes <- to_lodes_form(meta2,key="x",value="stratum",id="alluvium",
        axes=set.axes,diffuse=c(as.name(color),as.name(alpha),as.name(facet)))
    } else  if (!is.null(color) & !is.null(alpha) & is.null(facet)) {
        lodes <- to_lodes_form(meta2,key="x",value="stratum",id="alluvium",
        axes = set.axes, diffuse = c(as.name(color), as.name(alpha)))
    } else if (!is.null(color) & is.null(alpha) & !is.null(facet)) {
        lodes <- to_lodes_form(meta2,key="x",value="stratum",id ="alluvium",
        axes =set.axes, diffuse = c(as.name(color), as.name(facet)))
    } else if (is.null(color) & is.null(alpha) & !is.null(facet)) {
        lodes <- to_lodes_form(meta2, key = "x", value = "stratum", 
        id="alluvium",axes=set.axes,diffuse=c(as.name(alpha),as.name(facet)))
    } else if (is.null(color) & is.null(alpha) & !is.null(facet)) {
        lodes <- to_lodes_form(meta2, key = "x", value = "stratum", 
        id = "alluvium", axes = set.axes, diffuse = c(as.name(facet)))
    } else if (!is.null(color) & is.null(alpha) & is.null(facet)) {
        lodes <- to_lodes_form(meta2, key = "x", value = "stratum", 
        id = "alluvium", axes = set.axes, diffuse = c(as.name(color)))
    } else if (is.null(color) & !is.null(alpha) & is.null(facet)) {
        lodes <- to_lodes_form(meta2, key = "x", value = "stratum", 
        id = "alluvium", axes = set.axes, diffuse = c(as.name(alpha)))
    } else { lodes <- to_lodes_form(meta2, key = "x", value = "stratum", 
            id = "alluvium", axes = set.axes)}
    return(lodes) }


#' Visualizing the distribution of TCR V gene usage
#' 
#' This function will allow for the visualizing the distribution 
#' ofthe V-genes of the TCR by categroical variables.
#'
#' @examples
#' #Making combined contig data
#' x <- contig_list
#' combined <- combineTCR(x, rep(c("PX", "PY", "PZ"), each=2), 
#' rep(c("P", "T"), 3), cells ="T-AB")
#' 
#' vizVgenes(combined, TCR = "TCR1", facet.x = "sample")
#'
#' @param df The product of combineTCR(), combineBCR(), or expression2List().
#' @param TCR Which TCR chain to use, TCR1 = TCRA or TCR2 = TCRB
#' @param facet.x Categorical variable which to seperate by along x-axis
#' @param facet.y Categorical variable which to seperate by along y-axis
#' @param fill Categorical variable which to add color to bar chart
#' @param exportTable Returns the data frame used for forming the graph.
#' @import ggplot2
#' @importFrom stringr str_split
#' @export
#' @return ggplot bar diagram of vgene counts

vizVgenes <- function(df, TCR = "TCR1", 
                        facet.x = "sample", 
                        facet.y = NULL, 
                        fill = NULL, 
                        exportTable = FALSE){
    df <- bind_rows(df)
    TCR1 <- str_split(df[,"CTgene"], "_", simplify = TRUE)[,1] 
    TCR1 <- str_split(TCR1, "[.]", simplify = TRUE)[,1] 
    TCR2 <- str_split(df[,"CTgene"], "_", simplify = TRUE)[,2] 
    TCR2 <- str_split(TCR2, "[.]", simplify = TRUE)[,1] 
    df$TCR1_vgene <- TCR1
    df$TCR2_vgene <- TCR2
    if (TCR == "TCR1") {
        x <- "TCR1_vgene"}
    else if (TCR == "TCR2") {
        x <- "TCR2_vgene"}
    df <- subset(df, !is.na(df[,x])) #remove NA values
    df <- subset(df, df[,x] != "NA") #remove values that are character "NA"
    plot <- ggplot(df, aes(x=df[,x])) + 
        geom_bar() + 
        theme_classic() + 
        theme(axis.title.x = element_blank(), #remove titles
                axis.ticks.x = element_blank(), #removes ticks
                axis.text.x = element_text(angle = 90, 
                                    vjust = 0.5, hjust=1, size=rel(0.5)))
    
    if (!is.null(fill)) {
        plot <- plot + aes(fill = df[,fill]) + #Allow for coloring of bar
            labs(fill = fill)
    }
    #This allows for adaptive facetting so you can select which facet you'd like
    if (!is.null(facet.y) & !is.null(facet.x)) {
        plot <- plot + facet_grid(df[,facet.y] ~ df[,facet.x])
    } else if (is.null(facet.y) & !is.null(facet.x)) {
        plot <- plot + facet_grid(. ~ df[,facet.x])
    } else if (!is.null(facet.y) & is.null(facet.x)) {
        plot <- plot + facet_grid(df[,facet.y] ~ .)
    }
    if (exportTable == TRUE) { return(df) }
    return(plot)
}
