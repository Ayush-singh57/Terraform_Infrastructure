output "SECRET_S3_BUCKET_NAME" {
  description = "GitHub Secret Name: S3_BUCKET_NAME"
  value       = module.frontend_cdn.s3_bucket_name
}

output "SECRET_CLOUDFRONT_DIST_ID" {
  description = "GitHub Secret Name: CLOUDFRONT_DIST_ID"
  value       = module.frontend_cdn.cloudfront_distribution_id
}

output "FRONTEND_LIVE_URL" {
  description = "This is the live public URL for your React app!"
  value       = "https://${module.frontend_cdn.cloudfront_domain_name}"
}