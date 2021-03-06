[![Travis-CI Build Status](https://travis-ci.org/Omni-Analytics-Group/Rnumerai.svg?branch=master)](https://travis-ci.org/Omni-Analytics-Group/Rnumerai)

<a href="https://omnianalytics.io" target="_blank"><img src="man/figures/OAG_CLR_web_small.png" align="right"/></a>

# Rnumerai 
> R Interface to the Numerai Machine Learning Tournament API

This interface allows download of tournament data, submit predictions, get user information, stake NMR's and much more.
Using the functions from this package end user can write R code to automate the whole procedure related to numerai tournament.

If you encounter a problem or have suggestions, feel free to open an issue.

# Installation

- For the latest stable release: `install.packages("Rnumerai")`
- For the latest development release: `devtools::install_github("Omni-Analytics-Group/Rnumerai")`

# Automatic submission using this package

### 1. Load the package.

-   `library(Rnumerai)`

### 2. Set working directory where data will be downloaded and submission files would be kept.

- Use current working directory

    `data_dir <- getwd()`

- Or use temporary directory

    `data_dir <- tempdir()`

- Or use a user specific directory

    `data_dir <- "~/OAG/numerai"`

### 3. Set Public Key and Secret API key variables.

Get your public key and api key by going to numer.ai and then going to `Custom API Keys` section under your `Account` Tab. Select appropriate scopes to generate the key or select all scopes to use the full functionality of this package.

-   `set_public_id("public_id_here")`
-   `set_api_key("api_key_here")`

Optional: If we choose not to setup the credentials here the terminal will interactively prompt us to type the values when we make an API call.

### 4. Download data set for the current round and split it into training data and tournament data 

-    `data <- download_data(data_dir)`
-    `data_train <- data$data_train`
-    `data_tournament <- data$data_tournament`

### 5. Generate predictions

A user can put his/her own custom model code to generate the predictions here. For demonstration purposes, we will generate random predictions.

-   `submission <- data.frame(id=data_tournament$id,probability = sample(seq(.35,.65,by=.1),nrow(data_tournament),replace=TRUE))`

### 5-A. Generate predictions for multiple tournaments

A user can put his/her own custom model code to generate the predictions here. For demonstration purposes, we will generate random predictions.

-   `submissions <- list(
							"Bernie" = data.frame(id=data_tournament$id,probability = sample(seq(.35,.65,by=.1),nrow(data_tournament),replace=TRUE)),
							"Elizabeth" = data.frame(id=data_tournament$id,probability = sample(seq(.35,.65,by=.1),nrow(data_tournament),replace=TRUE))
						)`

### 6. Submit predictions for single tournament and get submission id

The submission object should have two columns (id & probability) only, The submission function would automatically append the tournament name to probability column according to parameter tournament supplied in following function. 

-    `submission_id <- submit_predictions(submission,data_dir,tournament="Elizabeth")`

### 6-A. Submit predictions for multiple tournaments and get submission ids

The submission object should be a named list and each element should have two columns (id & probability) only, The submission function would automatically append the tournament name to probability column according to the name of elements in the list.

-    `submission_ids <- submit_predictions_multi(submissions,data_dir)`

### 7. Check the status of the submission (Wait for a few seconds to get the submission evaluated)

-   `Sys.sleep(10)      ## 10 Seconds wait period`
-   `status_submission_by_id(submission_id)`
    
### 8. Stake submission on submission made above and get transaction hash for it.

-   `stake_tx_hash <- stake_nmr(tournament="Elizabeth",value = 1, confidence = ".5")`
-   `stake_tx_hash`

### 8-A. Stake submission on multiple tournament submissions made and get transaction hashes for them.

-   `stake_tx_hashes <- stake_nmr_multi(tournaments=c("Bernie","Elizabeth"),values = c(1,1), confidence_vals = c(".25",".5"))`
-   `stake_tx_hashes`

# Additional functions

### 1. Get User information

Get user information for the user whose API key and ID are entered, Check out the name of the return object to see what informations are included in the return and than subset the required information

-   `uinfo <- user_info()`
-   `uinfo`
-   `names(uinfo)`
-   `uinfo$Latest_Submission`

### 2. Get leaderboard for a round
Get leaderboard information for a given round number (Round 51 & Above).

-   `round_info <- round_stats(tournament="Bernie",round_number=79)`
-   `round_info$round_info`
-   `round_info$round_leaderboard`

### 3. Get current open round
Get closing time and round number for current open round

-   `current_round()`

### 4. Run Custom GraphQL code from R:

-   `custom_query <- 'query queryname {
    					rounds (number:82) {
    						closeTime
    					}
    				}'`
-   `run_query(query=custom_query)$data`
