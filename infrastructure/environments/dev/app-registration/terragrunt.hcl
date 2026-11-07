# =============================================================================
# Unit — Entra app registration (the API's identity)
# =============================================================================
# The platform's OAuth identity: the audience that every service validates a
# caller's token against, and the app roles authorization is driven by. There is
# no identity MICROSERVICE — Entra issues the tokens and each service validates
# them (D5). This unit has NO dependency on the resource group: an app
# registration is a DIRECTORY object, not an Azure resource, and lives in the
# tenant rather than in a subscription. That is the first of the four separate
# permission planes this platform crosses.
#
# The test client is a PUBLIC client for the Postman authorization-code + PKCE
# flow, so a human can obtain a real user token and the identity-propagation
# demo can be exercised end to end.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/app-registration"
}

inputs = {
  display_name = "${include.root.locals.project}-api-${include.root.locals.environment}"

  create_test_client       = true
  test_client_display_name = "ak-postman-test"
  test_client_redirect_uri = "https://oauth.pstmn.io/v1/callback"

  tags = [include.root.locals.project, include.root.locals.environment]
}
