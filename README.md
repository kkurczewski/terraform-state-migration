# About

Script for auto-generating terraform migration blocks based on resource types.

## Instruction

1. Extract Terraform plan:
```bash
tf plan -out=plan.zip
```

2. Generate migration file:
```bash
tf show -json plan.zip | jq -r '.resource_changes | map({ type, address, action: .change.actions | join(" -> ") }) | map(select(.action == "delete" or .action == "create")) | group_by(.type) | map(group_by(.action) | select(length > 1) | combinations | map({ (.action): .address }) | add | { from: .delete, to: .create }) | .[]' | sed -e 's/{/moved {/g' -e 's/:/ =/g' -e 's/}/}\n/g' | tr -d '",' > migration.tf
```

3. Review and comment out conflicting blocks.

## Plan before

```bash
Terraform will perform the following actions:

  # null_resource.bar will be created
  + resource "null_resource" "bar" {
      + id = (known after apply)
    }

  # null_resource.baz will be created
  + resource "null_resource" "baz" {
      + id = (known after apply)
    }

  # null_resource.foo will be destroyed
  # (because null_resource.foo is not in configuration)
  - resource "null_resource" "foo" {
      - id = "7119300735804322618" -> null
    }

  # random_string.random_str will be created
  + resource "random_string" "random_str" {
      + id          = (known after apply)
      + length      = 4
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + numeric     = true
      + result      = (known after apply)
      + special     = true
      + upper       = true
    }

Plan: 3 to add, 0 to change, 1 to destroy.
```

## Plan before migration cleanup

```bash
╷
│ Error: Ambiguous move statements
│ 
│   on migration.tf line 6:
│    6: moved {
│ 
│ A statement at migration.tf:1,1 declared that null_resource.foo moved to null_resource.bar, but this statement instead declares that it moved to null_resource.baz.
│ 
│ Each resource can move to only one destination resource.
╵
```

## Plan after cleanup

```bash
Terraform will perform the following actions:

  # null_resource.foo has moved to null_resource.bar
    resource "null_resource" "bar" {
        id = "7119300735804322618"
    }

  # null_resource.baz will be created
  + resource "null_resource" "baz" {
      + id = (known after apply)
    }

  # random_string.random_str will be created
  + resource "random_string" "random_str" {
      + id          = (known after apply)
      + length      = 4
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + numeric     = true
      + result      = (known after apply)
      + special     = true
      + upper       = true
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```