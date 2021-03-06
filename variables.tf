variable "max_characters" {
  description = <<EOF
The maximum number of bytes that the file will contain. This variable is used to pre-calculate the number of individual files that will need to be created and then concatenated.

If you don't set this value, then if the content size isn't known until the apply step, you'll need to do a `terraform apply -target` to target the resource that generates the content.

If you set a value that is drastically larger than the actual expected size, it will still work, but will simply create more resources and interim files than are necessary. 

If you set it lower than the actual size, you may get the same error as you would if you used the normal `local_file` resource.
EOF
  type        = number
  default     = null
}

variable "filename" {
  description = "The path of the file to create."
  type        = string
}

variable "content" {
  description = "The content of the file to create. Conflicts with `content_base64`."
  type        = string
  default     = null
}

variable "content_base64" {
  description = "The base64 encoded content of the file to create. Use this when dealing with binary data. Conflicts with `content`."
  type        = string
  default     = null
}

variable "file_permission" {
  description = "The permission to set for the created file. Expects a 4-character string (e.g. \"0777\"). Only has an effect when running on Unix-based systems."
  type        = string
  default     = "0777"
}

variable "directory_permission" {
  description = "The permission to set for any directories created.  Expects a 4-character string (e.g. \"0777\"). Only has an effect when running on Unix-based systems."
  type        = string
  default     = "0777"
}

variable "override_chunk_size" {
  description = "Set this variable to override the default per-file chunk size. This is generally only used for testing and should not normally be used. If you do set it, ensure that you set it to a value that is a multiple of 76 so that it doesn't break base64 encoding where it splits."
  type        = number
  default = null
}
