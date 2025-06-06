% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/prompt_templates.R
\name{create_discussion_prompt}
\alias{create_discussion_prompt}
\title{Create prompt for additional discussion rounds}
\usage{
create_discussion_prompt(
  cluster_id,
  cluster_genes,
  tissue_name,
  previous_rounds,
  round_number
)
}
\arguments{
\item{cluster_id}{The ID of the cluster being analyzed}

\item{cluster_genes}{The marker genes for the cluster}

\item{tissue_name}{The name of the tissue (optional)}

\item{previous_rounds}{A list of previous discussion rounds}

\item{round_number}{The current round number}
}
\value{
A formatted prompt string for additional discussion rounds
}
\description{
Create prompt for additional discussion rounds
}
\keyword{internal}
