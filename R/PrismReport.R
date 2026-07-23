new_PrismReport <- function(
  quality,
  leakage,
  transformation,
  stability,
  readiness,
  verdict
){
  structure(
    list(
      quality=quality,
      leakage=leakage,
      transformation=transformation,
      stability=stability,
      readiness=readiness,
      verdict=verdict
    ),
    class= "PrismReport"
  )
}
