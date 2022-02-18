# Terraform Local Large File

This module serves the same function as the [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) resource, but allows creation of files larger than 4MB, which is [currently not possible](https://github.com/hashicorp/terraform-provider-local/issues/28) with the `local_file` resource.

It works by splitting the content into chunks that are below the size limit, creating a `local_file` resource for each of those, then using a shell script with state tracking to concatenate the files on the filesystem into a single file.

### Limitations

- This module does not respect the `file_permission` and `directory_permission` variables when running on Windows. It does respect them when running on Unix-based systems.