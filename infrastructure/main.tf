provider "azurerm" {
  features {}
}

locals {
  previewVaultName = "${var.product}-shared-aat"
  nonPreviewVaultName = "${var.product}-shared-${var.env}"
  vaultName = var.env == "preview" ? local.previewVaultName : local.nonPreviewVaultName
  vaultUri = data.azurerm_key_vault.et_key_vault.vault_uri
  previewRG = "${var.product}-aat"
  nonPreviewRG = "${var.product}-${var.env}"
  resourceGroup = var.env == "preview" ? local.previewRG : local.nonPreviewRG
  localEnv = var.env == "preview" ? "aat" : var.env
  s2sRG  = "rpe-service-auth-provider-${local.localEnv}"
  common_tags = {
    "environment"  = var.env
    "Team Name"    = var.team_name
    "Team Contact" = var.team_contact
    "Destroy Me"   = var.destroy_me
  }
  tags = merge(local.common_tags, map("lastUpdated", timestamp()))
}

data "azurerm_key_vault" "et_key_vault" {
  name                = local.vaultName
  resource_group_name = local.resourceGroup
}

data "azurerm_key_vault" "s2s_key_vault" {
  name                = "s2s-${local.localEnv}"
  resource_group_name = local.s2sRG
}

resource "azurerm_key_vault_secret" "AZURE_APPINSGHTS_KEY" {
  name         = "AppInsightsInstrumentationKey"
  value        = azurerm_application_insights.appinsights.instrumentation_key
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

resource "azurerm_application_insights" "appinsights" {
  name                = "${var.product}-${var.component}-appinsights-${var.env}"
  location            = var.appinsights_location
  resource_group_name = local.resourceGroup
  application_type    = "web"

  tags = var.common_tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to appinsights as otherwise upgrading to the Azure provider 2.x
      # destroys and re-creates this appinsights instance
      application_type,
    ]
  }
}

data "azurerm_key_vault_secret" "microservicekey_et_message_handler" {
  name = "microservicekey-et-message-handler"
  key_vault_id = data.azurerm_key_vault.s2s_key_vault.id
}

resource "azurerm_key_vault_secret" "et_message_handler_s2s_key" {
  name         = "et-message-handler-s2s-key"
  value        = data.azurerm_key_vault_secret.microservicekey_et_message_handler.value
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

# SERVICE BUS
data "azurerm_key_vault_secret" "create_updates_queue_send_conn_str" {
  name = "create-updates-queue-send-connection-string"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

data "azurerm_key_vault_secret" "create_updates_queue_listen_conn_str" {
  name = "create-updates-queue-listen-connection-string"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

data "azurerm_key_vault_secret" "update_case_queue_send_conn_str" {
  name = "update-case-queue-send-connection-string"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

data "azurerm_key_vault_secret" "update_case_queue_listen_conn_str" {
  name = "update-case-queue-listen-connection-string"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

# DB
data "azurerm_key_vault_secret" "et_message_handler_postgres_user" {
  name = "et-message-handler-postgres-user"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

data "azurerm_key_vault_secret" "et_message_handler_postgres_password" {
  name = "et-message-handler-postgres-password"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

data "azurerm_key_vault_secret" "et_message_handler_postgres_host" {
  name = "et-message-handler-postgres-host"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

data "azurerm_key_vault_secret" "et_message_handler_postgres_port" {
  name = "et-message_handler-postgres-port"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}

data "azurerm_key_vault_secret" "et_message_handler_postgres_database" {
  name = "et-message-handler-postgres-database"
  key_vault_id = data.azurerm_key_vault.et_key_vault.id
}
