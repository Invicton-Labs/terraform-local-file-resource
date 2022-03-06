output "complete" {
  description = "A bool that can be used for dependencies, as it doesn't return a value until everything in this module has finished running."
  depends_on = [
    module.file_creator,
    null_resource.large_file
  ]
  value = true
}

output "filename" {
  depends_on = [
    module.file_creator,
    null_resource.large_file
  ]
  description = "The path to the file that was created. Does not return until the file has been created."
  value       = var.filename
}
