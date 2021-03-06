% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/source.R
\name{round_stats}
\alias{round_stats}
\title{Get Information and leader board for a Round Number}
\usage{
round_stats(round_number, tournament = "Bernie")
}
\arguments{
\item{round_number}{Round Number for which information to fetch}

\item{tournament}{The name of the tournament, Default is Bernie and is not case-sensitive}
}
\value{
List containing general round information and leaderboard
}
\description{
Get Information and leader board for a Round Number
}
\examples{
\dontrun{
round_info <- round_stats(round_number=79)
round_info$round_info
round_info$round_leaderboard
}
}
