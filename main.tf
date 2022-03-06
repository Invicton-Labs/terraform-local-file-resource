module "assert_valid_input" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  condition = length([for c in [
    var.content,
    var.content_base64
    ] :
    true
    if c != null
  ]) == 1
  error_message = "Exactly one of `content` or `content_base64` must be provided."
}

locals {
  // Whether the content came from the content_base64 variable
  is_base64 = var.content == null

  // Find the correct content source
  content = module.assert_valid_input.checked ? (local.is_base64 ? var.content_base64 : var.content) : null
}

// This is the module that actually creates the file
module "file_creator" {
  source         = "Invicton-Labs/file-data/local"
  version        = "~>0.1.0"
  // Depend on the null resource so that the destroy provisioner
  // deletes the file before we try to create a new one
  depends_on = [
    null_resource.large_file
  ]

  // Pass the content, filename, and permissions through unaltered
  content              = var.content
  content_base64       = var.content_base64
  filename             = var.filename
  directory_permission = var.directory_permission
  file_permission      = var.file_permission

  // If the number of characters is provided, use that. Otherwise, calculate it from the content length
  max_characters = var.max_characters == null ? length(local.content) : var.max_characters

  // Don't want to append, want to replace
  append = false
  // Since this module is intended to act as a resource and not a data source, always wait for apply
  // if the file actually needs creation of modifications
  force_wait_for_apply = module.file_creator.must_be_modified

  // If a value is provided, use it. Otherwise, use the default value of the data module
  override_chunk_size = var.override_chunk_size == null ? module.file_creator.default_chunk_size : var.override_chunk_size
}

resource "null_resource" "large_file" {
  triggers = sensitive({
    // If the filename changes, that needs a re-create
    filename             = var.filename
    max_characters       = var.max_characters
    file_permission      = var.file_permission
    directory_permission = var.directory_permission
    // If the content changes, that needs a re-create
    content_hash = base64sha256(local.content)
  })

  provisioner "local-exec" {
    when        = destroy
    interpreter = dirname("/") == "\\" ? ["powershell.exe"] : []
    command     = dirname("/") == "\\" ? "if (Test-Path \"$env:TF_LOCAL_FILE_NAME\") {Remove-Item \"$env:TF_LOCAL_FILE_NAME\"}" : "rm -f \"$TF_LOCAL_FILE_NAME\""
    environment = {
      TF_LOCAL_FILE_NAME = abspath(self.triggers.filename)
    }
    working_dir = path.module
  }
}
