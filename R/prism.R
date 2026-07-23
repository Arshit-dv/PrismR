prism <- function(data,target=NULL){

  quality <- quality_score(data)
  leakage <- detect_leakage(data,target)
  transformation <- recommend_transform(data)
  stability <- feature_stability(data)

  new_PrismReport(
    quality = quality,
    leakage= leakage,
    transformation = transformation,
    stability = stability,
    readiness = NA_real_,
    verdict = "Not Evaluated"
  )
}
