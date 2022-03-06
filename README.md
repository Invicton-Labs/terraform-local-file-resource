# Terraform Local File (Resource)

On the Terraform Registry: [Invicton-Labs/file-resource/local](https://registry.terraform.io/modules/Invicton-Labs/file-resource/local/latest)

This module serves the same function as the [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) resource, but allows creation of files larger than 4MB, which is [currently not possible](https://github.com/hashicorp/terraform-provider-local/issues/28) with the `local_file` resource.

It works by using the [Invicton-Labs/file-data/local](https://registry.terraform.io/modules/Invicton-Labs/file-data/local/latest) module internally to create a large file, along with a [null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) to track the state.

This module has been tested on Linux and Windows, but not macOS. In theory, it should function on any Unix-based OS that supports `bash` and `base64` commands, or any Windows-based OS that supports PowerShell.

## Limitations

- The `file_permission` and `directory_permission` variables have no effect when running on Windows, as PowerShell has no `chmod` equivalent.

## Usage

```
module "local-file-resource" {
  source = "Invicton-Labs/file-resource/local"

  filename = "${path.module}/testdir/test.txt"

  // You'd want a large file here, but this small
  // string is just to demo
  content = "Hello World!
}
```
