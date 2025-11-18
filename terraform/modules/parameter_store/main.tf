locals {
  normalized_parameters = {
    for key, value in var.parameters : key => merge(
      {
        name        = coalesce(value.name, key)
        description = coalesce(value.description, "")
        type        = coalesce(value.type, "SecureString")
        tier        = coalesce(value.tier, "Standard")
        overwrite   = coalesce(value.overwrite, true)
        key_id      = try(value.key_id, null)
        value       = value.value
      },
      {}
    )
  }
}

resource "aws_ssm_parameter" "this" {
  for_each = local.normalized_parameters

  name        = each.value.name
  description = each.value.description
  type        = each.value.type
  value       = each.value.value
  key_id      = each.value.key_id
  tier        = each.value.tier
  overwrite   = each.value.overwrite

  tags = var.tags
}
