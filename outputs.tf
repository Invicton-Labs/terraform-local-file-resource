output "complete" {
    description = "A bool that can be used for dependencies, as it doesn't return a value until everything in this module has finished running."
    depends_on = [
        module.merge_files
    ]
    value = true
}