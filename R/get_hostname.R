#' Get the container hostname we are running inside
#'
#' Get the container hostname we are running inside
#' @return nodename
#' @export
get_hostname <- function() {
  Sys.info()[["nodename"]]
}
