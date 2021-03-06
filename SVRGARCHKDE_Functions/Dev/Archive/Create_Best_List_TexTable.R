rm(list = ls())
graphics.off()

setwd(paste0(Sys.getenv("USERPROFILE"), "/Desktop/Master/Master_Thesis/Simulation"))

library(xtable)

source("SVRGARCHKDE_Functions/Dev/Result2Table_Functions.R")
test        <- readRDS("Final_Analysis/Final_Model.rds")
loop_var <- c("EuroStoxx50", "S&P500", "Nikkei225")

model_paras <- result <- vector("list", length(loop_var)) 
#names(model_paras) <- loop_var  
project_folder     <- "From1996to2006_ZeroMean"

i <- 1
for(i in 1:3){
  
  
  series_name        <- loop_var[i]  
  
  
  ###############################################################################
  # Get data
  ###############################################################################
  
  path2data     <- paste0("Tuning\\Results\\RDS_", series_name, "\\", project_folder, "\\VaR\\")
  start_load    <- Sys.time()
  files         <- lapply(file.path(path2data, list.files(path2data)), readRDS)
  end_load      <- Sys.time()
  end_load - start_load
  
  
  
  
  ###############################################################################
  # Get Christoffersons LR test statistic for every list element
  ###############################################################################
  
  # Get results of tests
  probs              <- c(0.005, 0.01, 0.025, 0.05)  # x%-Quantiles used in results table
  n                  <- length(files)
  list_table         <- lapply(1:n, function(x) arrange_results_df(files[[x]][[1]], probs, "SVM_KDE", loop_var[i]))
  
  grid_df            <- Reduce("rbind", lapply(1:n, function(x) cbind(rownames(files[[x]][[2]]),
                                                                      rbind(files[[x]][[2]],
                                                                            files[[x]][[2]],
                                                                            files[[x]][[2]],
                                                                            files[[x]][[2]]))))
  names(grid_df)[1]  <- "model"
  
  
  # Convert list to data frame
  df                 <- cbind(grid_df, Reduce("rbind", list_table))
  df_sorted          <- df[order(-df$Quantile, df$Series, df$UC, df$Model, decreasing = TRUE),]
  
  
  get_best_paramters <- function(prob){
    
    df <- df_sorted[df_sorted$Quantile == prob,]
    #df$UC_Rank <- rank(df$UC, ties.method = "max")
    #df$DUR_Rank <- rank(df$DUR, ties.method = "max")
    #df$Rank     <- df$UC_Rank + df$DUR_Rank
    # df$UC_DUR    <- df$UC + df$DUR
    
    return(df)
    
  }
  
  
  df_05 <- get_best_paramters(0.5)
  df_1 <- get_best_paramters(1)
  df_25 <- get_best_paramters(2.5)
  df_5 <- get_best_paramters(5)
  
  head_n <- 1
  
  df_paras <- rbind(head(df_05[order(df_05$CC, decreasing = TRUE),], head_n),
                    head(df_1[order(df_1$CC, decreasing = TRUE),], head_n),
                    head(df_25[order(df_25$CC, decreasing = TRUE),], head_n),
                    head(df_5[order(df_5$CC, decreasing = TRUE),], head_n))
  
  df_paras_sub <- df_paras[, c("cost", "psi", "gamma", "Series", "Quantile", "Exceedances", "UC", "ID", "CC")]
  names(df_paras_sub)[1:6] <- c("C", "psi", "gamma", "Index", "Quantile", "Violations")
  
  model_paras[[i]] <- df_paras_sub
  
}

rm(list = ls()[which(ls() != "model_paras")])

df4Tex <- Reduce("rbind", model_paras)


###############################################################################

# file_title <- "Tunig_Results_Case_1"
# savePath   <- paste0("C:/Users/luxmariu.hub/Desktop/Master/Master_Thesis/Simulation/Tex_Tables/"
#                    , "Results_", file_title, ".tex")
# 
# 
# tex_caption <- paste0("The best models in the tuning period according to the p-value of the test for conditional coverage.
#                       UC, ID and CC indicate the p-value of the corresponding test. All values in the columns Quantile, Violation,
#                       UC, ID and CC are given in percent.")
# 
# 
# 
# bold <- function(x) {paste('\\textbf{',x,'}', sep ='')}
# 
# tex_raw <- xtable(df4Tex, caption = tex_caption, label = "Tab:tuning_case1")
# align(tex_raw) <- "c|c|c|c|c|c|c|c|c|c"
# print(tex_raw
#                 , include.rownames = FALSE
#                 , hline.after = c(-1, 0, 0, 4, 4, 8, 8, 12, 12)
#                 , sanitize.colnames.function=bold
#                 , type = "latex"
#                 , file = savePath
# )


