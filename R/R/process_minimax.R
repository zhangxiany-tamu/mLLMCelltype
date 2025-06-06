#' Process request using MiniMax models
#' Note: Model names are case-insensitive, but we use lowercase by convention (e.g., "minimax-text-01")
#' @keywords internal
process_minimax <- function(prompt, model, api_key) {
  write_log("\n=== Starting MiniMax API Request ===\n")
  write_log(sprintf("Model: %s", model))
  
  # MiniMax API endpoint
  url <- "https://api.minimaxi.chat/v1/text/chatcompletion_v2"
  write_log("API URL:")
  write_log(url)
  
  # Process all input at once
  input_lines <- strsplit(prompt, "\n")[[1]]
  write_log("\nInput lines:")
  write_log(paste(input_lines, collapse = "\n"))
  
  cutnum <- 1  # Changed to always use 1 chunk
  write_log(sprintf("\nProcessing input in %d chunk(s)", cutnum))
  
  if (cutnum > 1) {
    cid <- as.numeric(cut(1:length(input_lines), cutnum))	
  } else {
    cid <- rep(1, length(input_lines))
  }
  
  # Process each chunk
  allres <- sapply(1:cutnum, function(i) {
    write_log(sprintf("\nProcessing chunk %d of %d", i, cutnum))
    id <- which(cid == i)
    
    chunk_content <- paste(input_lines[id], collapse = '\n')
    write_log("\nChunk content:")
    write_log(chunk_content)
    
    # Prepare the request body
    body <- list(
      model = model,  # Use the model name passed as parameter
      messages = list(
        list(
          role = "user",
          name = "user",
          content = chunk_content
        )
      )
    )
    
    write_log("\nRequest body:")
    write_log(jsonlite::toJSON(body, auto_unbox = TRUE, pretty = TRUE))
    
    write_log("\nSending API request...")
    # Make the API request
    response <- httr::POST(
      url = url,
      httr::add_headers(
        "Content-Type" = "application/json",
        "Authorization" = paste("Bearer", api_key)
      ),
      body = jsonlite::toJSON(body, auto_unbox = TRUE),
      encode = "json"
    )
    
    # Check for errors
    if (httr::http_error(response)) {
      error_message <- httr::content(response, "parsed")
      write_log(sprintf("ERROR: MiniMax API request failed: %s", 
                       if (!is.null(error_message$error$message)) error_message$error$message else "Unknown error"))
      return(NULL)
    }
    
    write_log("Parsing API response...")
    # Parse the response
    content <- httr::content(response, "parsed")
    
    # Log the raw response for debugging
    write_log("Raw API response:")
    write_log(jsonlite::toJSON(content, auto_unbox = TRUE, pretty = TRUE))
    
    # Check if response has the expected structure
    if (is.null(content) || is.null(content$choices) || length(content$choices) == 0 ||
        is.null(content$choices[[1]]$message) || is.null(content$choices[[1]]$message$content)) {
      write_log("ERROR: Unexpected response format from MiniMax API")
      write_log(sprintf("Content structure: %s", paste(names(content), collapse = ", ")))
      if (!is.null(content$choices)) {
        write_log(sprintf("Choices structure: %s", jsonlite::toJSON(content$choices, auto_unbox = TRUE, pretty = TRUE)))
      }
      return(NULL)
    }
    
    # MiniMax's response should be in content$choices[[1]]$message$content
    response_content <- content$choices[[1]]$message$content
    if (!is.character(response_content)) {
      write_log("ERROR: Response content is not a character string")
      return(NULL)
    }
    
    res <- strsplit(response_content, '\n')[[1]]
    write_log(sprintf("Got response with %d lines", length(res)))
    write_log(sprintf("Raw response from MiniMax:\n%s", paste(res, collapse = "\n")))
    
    res
  }, simplify = FALSE)
  
  write_log("All chunks processed successfully")
  return(gsub(',$', '', unlist(allres)))
}
