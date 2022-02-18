locals {
  // With UTF, there could be up to 4 bytes per character. So, if we limit it to 1,000,000 characters,
  // that's certain to be less than 4MB per file. We actually use 999,999 though, since that's a 
  // multiple of 3, which means it's a safe place to split base64-encoded files as well.
  characters_per_file = var.override_chunk_size
  // Find the correct content source
  content = var.content != null ? var.content : (var.sensitive_content != null ? sensitive(var.sensitive_content) : var.content_base64)
  // Calculate how many chunks we need to split it into
  num_chunks = ceil(var.max_characters != null ? var.max_characters / local.characters_per_file : length(local.content) / local.characters_per_file)
  // Split it into chunks
  chunks = [
    for i in range(0, local.num_chunks) :
    substr(local.content, i * local.characters_per_file, local.characters_per_file)
  ]
  // This uses the provided interim directory, or the default if none provided. It replaces all Windows separators ("\") with Unix separators ("/"), then ensures
  // that there is one, and only one, trailing "/"
  interim_directory = "${trimsuffix(replace(var.interim_file_directory != null ? var.interim_file_directory : "${path.module}/large-file-parts", "\\", "/"), "/")}/"
}

// This is a unique ID for this module, so the interim files never conflict with those of other copies of this same module
resource "random_uuid" "id" {}

// Create the interim files
resource "local_file" "interim" {
  count                = local.num_chunks
  content              = var.content != null ? local.chunks[count.index] : null
  sensitive_content    = var.sensitive_content != null ? local.chunks[count.index] : null
  content_base64       = var.content_base64 != null ? local.chunks[count.index] : null
  filename             = "${local.interim_directory}/${random_uuid.id.id}.part_${count.index}"
  file_permission      = var.file_permission
  directory_permission = var.directory_permission
}

// This module runs a shell script that concatenates the individual files. It's stateful, 
// so it won't re-run unless the content itself has changed.
module "merge_files" {
  source  = "Invicton-Labs/shell-resource/external"
  version = "~>0.1.2"
  // Wait for all of the local files to be created before trying to concatenate them
  depends_on = [
    local_file.interim
  ]
  // If the content changes, re-run this module
  triggers = {
    content  = sha256(local.content)
    filename = var.filename
    interim_files = [
      for f in local_file.interim :
      f.filename
    ]
  }
  command_windows              = "Get-Content $env:INTERIM_FILENAMES_WINDOWS | Set-Content -NoNewline $env:OUTPUT_FILENAME"
  command_when_destroy_windows = "Remove-Item \"$env:OUTPUT_FILENAME\" -ErrorAction Ignore"
  command_unix                 = "mkdir -p -m $DIRECTORY_PERMISSIONS $PARENT_DIRECTORY && cat $INTERIM_FILENAMES_UNIX > \"$OUTPUT_FILENAME\" && chmod $FILE_PERMISSIONS \"$OUTPUT_FILENAME\""
  command_when_destroy_unix    = "rm -f \"$OUTPUT_FILENAME\""
  environment = {
    DIRECTORY_PERMISSIONS = var.directory_permission
    FILE_PERMISSIONS      = var.file_permission
  }
  triggerless_environment = {
    // Anything that references abspath should be in a triggerless environment, since we don't want it to re-run if a new apply is done on a system with a different file structure
    // The filenames themselves are referenced in the "triggers" section, so this will still re-run if the input filename variable changes
    OUTPUT_FILENAME           = abspath(var.filename)
    INTERIM_FILENAMES_WINDOWS = "\"${join("\", \"", [for idx, file in local_file.interim : abspath(file.filename)])}\""
    INTERIM_FILENAMES_UNIX    = "\"${join("\" \"", [for idx, file in local_file.interim : abspath(file.filename)])}\""
    PARENT_DIRECTORY          = dirname(abspath(var.filename))
  }
  working_dir   = path.module
  fail_on_error = true
}
