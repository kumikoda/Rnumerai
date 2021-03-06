#' Gets the Numerai Password
#'
#' @return Your Numerai Password, if set
#' @export
#' @examples
#' \dontrun{
#' get_password()
#' }
get_password <- function() {
  env <- Sys.getenv("NUMERAIPASS")
  if (!identical(env, "")) return(env)

  if (!interactive()) {
    stop("Please set the environment variable NUMERAIPASS to your Numerai Password", call. = FALSE)
  }

  message("Please enter your Numerai Password and press enter:")

  pass <- readline(": ")

  if (identical(pass, "")) {
    stop("Invalid Password", call. = FALSE)
  }

  message("Updating NUMERAIPASS environment variable.")
  Sys.setenv(NUMERAIPASS = pass)

  return(pass)
}

#' Sets the Numerai Password
#'
#' @name set_password
#' @param pass The Numerai Password
#' @return A boolean TRUE if the password was successfully set
#' @export
#' @examples
#' \dontrun{
#' set_password("abcdefghijklmnop")
#' }
set_password <- function(pass) {
  if (identical(pass, "")) {
    stop("Invalid Password", call. = FALSE)
  }

  Sys.setenv(NUMERAIPASS = pass)

  return(TRUE)
}

#' Gets the Numerai Public ID
#'
#' @return Your Numerai Public ID, if set
#' @export
#' @examples
#' \dontrun{
#' get_public_id()
#' }
get_public_id <- function() {
  env <- Sys.getenv("NUMERAIID")
  if (!identical(env, "")) return(env)

  if (!interactive()) {
    stop("Please set the environment variable NUMERAIID to your Numerai Public ID", call. = FALSE)
  }

  message("Please enter your Numerai Public ID and press enter:")

  id <- readline(": ")

  if (identical(id, "")) {
    stop("Invalid Public ID", call. = FALSE)
  }

  message("Updating NUMERAIID environment variable.")
  Sys.setenv(NUMERAIID = id)

  return(id)
}

#' Sets the Numerai Public ID
#'
#' @name set_public_id
#' @param id The Numerai Public ID
#' @return A boolean TRUE if the ID was successfully set
#' @export
#' @examples
#' \dontrun{
#' set_public_id("abcdefghijklmnop")
#' }
set_public_id <- function(id) {
  if (identical(id, "")) {
    stop("Invalid Public ID", call. = FALSE)
  }

  Sys.setenv(NUMERAIID = id)

  return(TRUE)
}

#' Gets the Numerai API key
#'
#' @return Your Numerai API key, if set
#' @export
#' @examples
#' \dontrun{
#' get_api_key()
#' }
get_api_key <- function() {
  env <- Sys.getenv("NUMERAIKEY")
  if (!identical(env, "")) return(env)

  if (!interactive()) {
    stop("Please set the environment variable NUMERAIKEY to your Numerai API key", call. = FALSE)
  }

  message("Please enter your Numerai API key and press enter:")

  key <- readline(": ")

  if (identical(key, "")) {
    stop("Invalid API key", call. = FALSE)
  }

  message("Updating NUMERAIKEY environment variable.")
  Sys.setenv(NUMERAIKEY = key)

  return(key)
}

#' Sets the Numerai API key
#'
#' @name set_api_key
#' @param key The Numerai API key
#' @return A boolean TRUE if the key was successfully set
#' @export
#' @examples
#' \dontrun{
#' set_api_key("abcdefghijklmnop")
#' }
set_api_key <- function(key) {
  if (identical(key, "")) {
    stop("Invalid API key", call. = FALSE)
  }

  Sys.setenv(NUMERAIKEY = key)

  return(TRUE)
}

#' Function to run a raw GraphQL query on the API interface
#'
#' @name run_query
#' @param query The graphQL query to run on the API as a string in single quotes
#' @param id The public id of the Numerai application
#' @param key The Numerai API key
#' @return The parsed json content returned from the request
#' @export
#' @import httr
#' @examples
#' \dontrun{
#' ## Run Custom GraphQL code from R
#' custom_query <- "query queryname {
#' rounds (number:82) {
#' closeTime
#' }
#' }"
#' run_query(query=custom_query)$data
#' }
run_query <- function(query, id = get_public_id(), key = get_api_key())
{
	## httr's POST call to retrieve results from numerai graphql API
	raw <- POST(
					url = "https://api-tournament.numer.ai",
					body = list(query=query),
					encode="json",
					add_headers(
									Authorization=paste0("Token ",id,"$",key),
									"Content-type"="application/json",
									Accept="application/json"
								)
	)
	return(content(raw, "parsed"))
}

#' Function to download the Numerai Tournament data
#'
#' @name download_data
#' @param location The directory path in which to store the data
#' @param tournament The name of the tournament, Default is Bernie and is not case-sensitive. Since at the moment the datasets are same for all tournaments this parameter can be left blank.
#' @return A list containing the training and tournament data objects
#' @export
#' @import lubridate
#' @import httr
#' @importFrom utils unzip
#' @importFrom utils read.csv
#' @examples
#' \dontrun{
#' ## Directory where data files and prediction files to be saved
#' ## Put custom directory path or use the current working directory
#' data_dir <- tempdir()
#'
#' ## Download data set for current competition
#' data <- download_data(data_dir,tournament="Elizabeth")
#' data_train <- data$data_train
#' data_tournament <- data$data_tournament
#' }
download_data <- function(location = tempdir(),tournament="Bernie")
{
	## Match tournament ID
	tournament_id <- match(tolower(tournament),tolower(c("BERNIE","ELIZABETH","JORDAN","KEN","CHARLES","FRANK","HILLARY")))
	if(is.na(tournament_id)) stop("Tournament Name doesn't match")

	## Get download link
	download_link_query <- paste0('{dataset(tournament:',tournament_id,')}')
	query_pass <- run_query(query=download_link_query)
	download_link <- query_pass$data$dataset

	message("Downloading Data...\n")

	## Download File
	filename <- file.path(location, paste0("numerai_dataset_", today(), ".zip"))
	result <- GET(download_link, write_disk(filename, overwrite = TRUE))

	## Unzip the file
	unzip(filename,overwrite = TRUE,exdir = location)
	message("Finished downloading data\nReading dataset now...")

	## Read and return the data set
	data_train <- read.csv(file.path(location, "numerai_training_data.csv"))
	data_tournament <- read.csv(file.path(location, "numerai_tournament_data.csv"))
	return(list(data_train=data_train,data_tournament=data_tournament))
}

#' Function to submit the Numerai Tournament predictions for a single tournament
#'
#' @name submit_predictions
#' @param submission The data frame of predictions to submit. This should have two columns named "id" & "probability"
#' @param location The location in which to store the predictions
#' @param tournament The name of the tournament, Default is Bernie and is not case-sensitive
#' @return The submission id for the submission made
#' @export
#' @import lubridate
#' @import httr
#' @importFrom utils write.csv
#' @examples
#' \dontrun{
#' submission_id <- submit_predictions(submission_data,tournament="Elizabeth")
#' }
submit_predictions <- function(submission, location = tempdir(),tournament="Bernie")
{
	## Match tournament ID
	tournament_id <- match(tolower(tournament),tolower(c("BERNIE","ELIZABETH","JORDAN","KEN","CHARLES","FRANK","HILLARY")))
	if(is.na(tournament_id)) stop("Tournament Name doesn't match")
	if(!all(names(submission)==c("id","probability"))) stop("Column names should be id & probability")
	names(submission)[2] <- paste0(names(submission)[2],"_",tolower(tournament))

	## Write out the file
	submission_filename <- file.path(location, paste0("submission_data_", today(), ".csv"))
	write.csv(submission, submission_filename, row.names = FALSE)

	## Get a slot on AWS for our submission
	aws_slot_query <- paste0('query aws_slot_query {
							submissionUploadAuth (filename : "submission_data.csv",tournament:',tournament_id,'){
								filename,
								url
							}
						}')
	query_pass <- run_query(query=aws_slot_query)

	## Upload the predictions
	mysubmission <- PUT(
							url = query_pass$data$submissionUploadAuth$url,
							body = upload_file(path = submission_filename)
						)

	## Register our submission and get evaluation for it
	register_submission_query <- paste0(
											'mutation register_submission_query {
												createSubmission (filename : "',query_pass$data$submissionUploadAuth$filename,'",tournament:',tournament_id,'){id}
											}'
										)
	query_pass <- run_query(query=register_submission_query)

	## If error
	if(!is.null(query_pass$errors[[1]]$message)) stop(query_pass$errors[[1]]$message)

	## Return submission id
	message(paste("Submitted Prediction with id",query_pass$data$createSubmission$id))
	return(query_pass$data$createSubmission$id)
}

#' Function to submit the Numerai Tournament predictions for multiple tournaments
#'
#' @name submit_predictions_multi
#' @param submissions The named list of the data frames of predictions to submit. The list names should be tournament names and each element a data frame having two columns named "id" & "probability" for that particular tournament
#' @param location The location in which to store the predictions
#' @return The submission ids for the submissions made
#' @export
#' @import lubridate
#' @import httr
#' @importFrom utils write.csv
#' @examples
#' \dontrun{
#' submission_ids <- submit_predictions_multi(submissions_data)
#' }
submit_predictions_multi <- function(submissions, location = tempdir())
{
	## Error check
	if(class(submissions)!="list") stop("submissions should be a named list of the data frames of predictions to submit. The list names should be tournament names and each element a data frame having two columns named `id` & `probability` for that particular tournament")

	## Loop for each element in the list and record the returned submission ids
	submission_ids_return <- character()
	for(idx in 1:length(submissions))
	{
		submission <- submissions[[idx]]
		tournament <- names(submissions)[idx]

		submission_ids_return <- c(submission_ids_return,tryCatch({
																	submit_predictions(submission=submission,location=location,tournament=tournament)
																	}, error=function(e){ as.character(e) }))
	}

	names(submission_ids_return) <- names(submissions)
	return(submission_ids_return)
}

#' Get information about a submission from a submission id
#'
#' @name status_submission_by_id
#' @param sub_id The id of the submission
#' @return A list containing information about the given submission id
#' @export
#' @examples
#' \dontrun{
#' status_submission_by_id(submission_id)
#' }
status_submission_by_id <- function(sub_id)
{
	sub_stat_query <- paste0(
								'query sub_stat_query {
									submissions (id : "',sub_id,'"){
										filename,
										liveLogloss,
										round{
											number
										},
										selected,
										validationLogloss,
										consistency,
										concordance {
											pending
											value
										}
									}
								}'
							)
	query_pass <- run_query(query=sub_stat_query)

	## If not evaluated yet
	if(is.null(query_pass$data$submissions[[1]]$validationLogloss))
	{
		return(NULL)
	}

	## If evaluated submission
	result <- list(
					Submission_ID = sub_id,
					Round_Number = query_pass$data$submissions[[1]]$round$number,
					Tournament_Name = c("BERNIE","ELIZABETH","JORDAN","KEN","CHARLES","FRANK","HILLARY")[query_pass$data$submissions[[1]]$round$tournament],
					Filename = query_pass$data$submissions[[1]]$filename,
					Selected = query_pass$data$submissions[[1]]$selected,
					Validation_Logloss = query_pass$data$submissions[[1]]$validationLogloss,
					Consistency = query_pass$data$submissions[[1]]$consistency,
					Concordance = ifelse(!query_pass$data$submissions[[1]]$concordance$pending,query_pass$data$submissions[[1]]$concordance$value,"Pending"),
					Live_Logloss = query_pass$data$submissions[[1]]$liveLogloss
					)
	return(result)
}

#' Get information about your username
#'
#' @name user_info
#' @return A list containing information about user
#' @export
#' @examples
#' \dontrun{
#' uinfo <- user_info()
#' names(uinfo)
#' uinfo$Latest_Submission
#' }
user_info <- function()
{
	user_info_query <-	'query user_info_query {
							user {
								apiTokens {
									name
									publicId
									scopes
								}
								assignedEthAddress
								banned
								customEthAddresses
								id
								email
								username
								insertedAt
								status
								mfaEnabled
								latestSubmission {
									id
									round {
										number
									}
								}
								availableUsd
								availableNmr
								nmrDeposits {
									from
									to
									value
									posted
									source
									status
									txHash
								}
								nmrWithdrawals {
									from
									to
									value
									posted
									source
									status
									txHash
								}
								payments {
									round {
										number
									}
									nmrAmount
									usdAmount
									submission {
										id
										filename
									}
									tournament
								}
								usdWithdrawals {
									from
									to
									ethAmount
									usdAmount
									sendTime
									confirmTime
									status
									posted
									txHash
								}
								stakeTxs{
									roundNumber
									value
									confidence
									status
									insertedAt
									soc
									staker
									txHash
								}
							}
						}'

	query_pass <- run_query(query=user_info_query)

	## Cleaning functions to report result
	clean_tokens_info <- function(x)
	{
		data.frame(
						Name = x$name,
						Public_ID = x$publicId,
						Scopes = paste(unlist(x$scopes),collapse=", ")
					)
	}
	clean_nmr_deposits <- function(x)
	{
		if(length(x)==0) return(NULL)
		return(as.data.frame(do.call(rbind,x))[,c("from","to","value","status","posted","source","txHash"),drop=FALSE])
	}
	clean_nmr_withdrawls <- function(x)
	{
		if(length(x)==0) return(NULL)
		return(as.data.frame(do.call(rbind,x))[,c("from","to","value","status","posted","source","txHash"),drop=FALSE])
	}
	clean_usd_withdrawls <- function(x)
	{
		if(length(x)==0) return(NULL)
		return(as.data.frame(do.call(rbind,x))[,c("from","to","ethAmount","usdAmount","sendTime","confirmTime","status","posted","txHash"),drop=FALSE])
	}
	clean_payments_data <- function(x)
	{
		if(length(x)==0) return(NULL)
		payment_data <- as.data.frame(do.call(rbind,lapply(x,unlist))[,c("round.number","nmrAmount","usdAmount","tournament","submission.id","submission.filename"),drop=FALSE])
		names(payment_data) <- c("Round_Number","NMR","USD","Tournament","Submission_ID","Submission_Filename")
		return(payment_data)
	}
	clean_stake_transactions <- function(x)
	{
		if(length(x)==0) return(NULL)
		return(as.data.frame(do.call(rbind,x))[,c("roundNumber","value","soc","confidence","status","insertedAt","staker","txHash"),drop=FALSE])
	}

	result <- list(
						Email_Address = query_pass$data$user$email,
						Username = query_pass$data$user$username,
						ID = query_pass$data$user$id,
						Generated_Time = query_pass$data$user$insertedAt,
						Current_Status = query_pass$data$user$status,
						MFA_Enabled = query_pass$data$user$mfaEnabled,
						Banned = query_pass$data$user$banned,
						Api_Tokens = do.call(rbind,lapply(query_pass$data$user$apiTokens,clean_tokens_info)),
						Assigned_ETH_Address = query_pass$data$user$assignedEthAddress,
						Custom_ETH_Address = unlist(query_pass$data$user$customEthAddresses),
						Latest_Submission = data.frame(Round_Number = unlist(query_pass$data$user$latestSubmission)[1], Submission_ID = unlist(query_pass$data$user$latestSubmission)[2]),
						Balances = data.frame(USD=query_pass$data$user$availableUsd,NMR = query_pass$data$user$availableNmr),
						NMR_Deposits = clean_nmr_deposits(query_pass$data$user$nmrDeposits),
						NMR_Withdrawls = clean_nmr_withdrawls(query_pass$data$user$nmrWithdrawals),
						Payments = clean_payments_data(query_pass$data$user$payments),
						USD_Withdrawls = clean_usd_withdrawls(query_pass$data$user$usdWithdrawals),
						Stakes_Transactions = clean_stake_transactions(query_pass$data$user$stakeTxs)
					)
	return(result)
}

#' Get current round and it's closing time
#'
#' @name current_round
#' @param tournament The name of the tournament, Default is Bernie and is not case-sensitive
#' @return Returns the current round number and it's closing times
#' @export
#' @examples
#' \dontrun{
#' current_round()
#' }
current_round <- function(tournament="Bernie")
{
	## Match tournament ID
	tournament_id <- match(tolower(tournament),tolower(c("BERNIE","ELIZABETH","JORDAN","KEN","CHARLES","FRANK","HILLARY")))
	if(is.na(tournament_id)) stop("Tournament Name doesn't match")
	
	current_round = paste0('query current_round {
						rounds(number:0,tournament:',tournament_id,') {
							number
							closeTime
							closeStakingTime
						}
					}')
	query_pass <- run_query(query=current_round)
	return(c(Round_Number=query_pass$data$rounds[[1]]$number,Close_Time=query_pass$data$rounds[[1]]$closeTime,Close_Staking_Time=query_pass$data$rounds[[1]]$closeStakingTime))
}

#' Stake NMR on the current round and single tournament
#'
#' @name stake_nmr
#' @param tournament The name of the tournament, Default is Bernie and is not case-sensitive
#' @param value The amount of NMR to stake
#' @param confidence The confidence value to use
#' @param mfa_code The mfa code
#' @param password Your password
#' @return The transaction hash for stake made
#' @export
#' @examples
#' \dontrun{
#' stake_tx_hash <- stake_nmr(tournament="Elizabeth",value = 1, confidence = ".5")
#' }
stake_nmr <- function(tournament="Bernie",value, confidence, mfa_code = "", password = "")
{
	## Match tournament ID
	tournament_id <- match(tolower(tournament),tolower(c("BERNIE","ELIZABETH","JORDAN","KEN","CHARLES","FRANK","HILLARY")))
	if(is.na(tournament_id)) stop("Tournament Name doesn't match")

	stake_query <- paste0(
							'mutation stake_query {
								stake(code:"',mfa_code,'"
								password:"',password,'"
								value:"',value,'"
								confidence:"',confidence,'"
								tournament :',tournament_id,' 
								round:',as.numeric(current_round()["Round_Number"]),'
								){
									txHash
								}}'
							)
	query_pass <- run_query(query=stake_query)
	return(query_pass)
}

#' Stake NMR on the current round and multiple tournaments
#'
#' @name stake_nmr_multi
#' @param tournaments The vector of names of the tournaments
#' @param values The vector of the amounts of NMR to stake
#' @param confidence_vals The vector of the confidence values to use
#' @param mfa_code The mfa code
#' @param password Your password
#' @return The transaction hashes for stakes made
#' @export
#' @examples
#' \dontrun{
#' stake_tx_hashes <- stake_nmr_multi(tournaments=c("Bernie","Elizabeth"),values = c(1,1), confidence_vals = c(".25",".5"))
#' }
stake_nmr_multi <- function(tournaments,values, confidence_vals, mfa_code = "", password = "")
{
	## Error Check
	if(!all(length(tournaments)==c(length(tournaments),length(values),length(confidence_vals)))) stop("tournaments, values & confidence_vals should all be of equal lengths")

	## Loop and make individual stakes
	stake_tx_hashes <- character()
	for(idx in 1:length(tournaments))
	{
		tournament <- tournaments[idx]
		value <- values[idx]
		confidence <- confidence_vals[idx]

		stake_tx_hashes <- c(stake_tx_hashes,tryCatch({
														stake_nmr(tournament=tournament,value = value, confidence = confidence)
														}, error=function(e){ as.character(e) }))
	}

	names(stake_tx_hashes) <- tournaments
	return(stake_tx_hashes)
}

#' Get Information and leader board for a Round Number
#'
#' @name round_stats
#' @param round_number Round Number for which information to fetch
#' @param tournament The name of the tournament, Default is Bernie and is not case-sensitive
#' @return List containing general round information and leaderboard
#' @export
#' @examples
#' \dontrun{
#' round_info <- round_stats(round_number=79)
#' round_info$round_info
#' round_info$round_leaderboard
#' }
round_stats <- function(round_number,tournament="Bernie")
{
	## Match tournament ID
	tournament_id <- match(tolower(tournament),tolower(c("BERNIE","ELIZABETH","JORDAN","KEN","CHARLES","FRANK","HILLARY")))
	if(is.na(tournament_id)) stop("Tournament Name doesn't match")

	round_stats_query <- paste0(
									'query round_stats_query {
									rounds(number:',round_number,',tournament:',tournament_id,'){
										number
										tournament
										openTime
										resolvedGeneral
										resolvedStaking
										closeTime
										closeStakingTime
										leaderboard {
											username
											banned
											validationLogloss
											consistency
											liveLogloss
											paymentGeneral {
												nmrAmount
												usdAmount
      										}
      										paymentStaking {
												usdAmount
												nmrAmount
											}
											stake {
												confidence
												value
											}
											stakeResolution {
												successful
												destroyed
												paid
											}
										}
									}}'
								)
	query_pass <- run_query(query=round_stats_query)

	round_data <- query_pass$data$rounds[[1]]
	result_info <- data.frame(
								Round_Number = round_data$number,
								Tournament_Name = c("BERNIE","ELIZABETH","JORDAN","KEN","CHARLES","FRANK","HILLARY")[round_data$tournament],
								Open_Time = round_data$openTime,
								Close_Time = round_data$closeTime,
								Close_Staking_Time = ifelse(is.null(round_data$closeStakingTime),NA,round_data$closeStakingTime),
								If_Resolved = round_data$resolvedGeneral
  							)
	round_lb <- query_pass$data$rounds[[1]]$leaderboard
	result_leaderboard <- data.frame(
										Username = sapply(round_lb,function(x) x$username),
										Banned = sapply(round_lb,function(x) x$banned),
										Live_Logloss = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$liveLogloss),0,x$liveLogloss))),
										Validation_Logloss = sapply(round_lb,function(x) ifelse(is.null(x$validationLogloss),NA,x$validationLogloss)),
										Consistency = sapply(round_lb,function(x) ifelse(is.null(x$consistency),NA,x$consistency)),
										Paid_USD = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$paymentGeneral$usdAmount),0,x$paymentGeneral$usdAmount))),
										Paid_NMR = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$paymentGeneral$nmrAmount),0,x$paymentGeneral$nmrAmount))),
										Stake_Amount = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$stake$value),0,x$stake$value))),
										Stake_Confidence = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$stake$confidence),NA,x$stake$confidence))),
										Stake_Success = sapply(round_lb,function(x) ifelse(is.null(x$stakeResolution$successful),NA,x$stakeResolution$successful)),
										Stake_Destroyed = sapply(round_lb,function(x) ifelse(is.null(x$stakeResolution$destroyed),NA,x$stakeResolution$destroyed)),
										Stake_Paid = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$paymentStaking$usdAmount),0,x$paymentStaking$usdAmount))),
										Stake_Paid_NMR = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$paymentStaking$nmrAmount),0,x$paymentStaking$nmrAmount))),
										Paid_USD_Total = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$paymentGeneral$usdAmount),0,x$paymentGeneral$usdAmount)))+as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$paymentStaking$usdAmount),0,x$paymentStaking$usdAmount))),
										Paid_NMR_Total = as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$paymentGeneral$nmrAmount),0,x$paymentGeneral$nmrAmount)))+as.numeric(sapply(round_lb,function(x) ifelse(is.null(x$paymentStaking$nmrAmount),0,x$paymentStaking$nmrAmount)))
									)
	return(list(round_info = result_info , round_leaderboard = result_leaderboard))
}






