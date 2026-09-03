module Primary = struct
  module Auth_type = struct
    let t_of_yojson = function
      | `String "oidc_aws" -> Ok `Oidc_aws
      | `String "oidc_azure" -> Ok `Oidc_azure
      | `String "oidc_cloudsmith" -> Ok `Oidc_cloudsmith
      | `String "oidc_gcp" -> Ok `Oidc_gcp
      | `String "oidc_jfrog" -> Ok `Oidc_jfrog
      | `String "token" -> Ok `Token
      | `String "username_password" -> Ok `Username_password
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Oidc_aws -> `String "oidc_aws"
      | `Oidc_azure -> `String "oidc_azure"
      | `Oidc_cloudsmith -> `String "oidc_cloudsmith"
      | `Oidc_gcp -> `String "oidc_gcp"
      | `Oidc_jfrog -> `String "oidc_jfrog"
      | `Token -> `String "token"
      | `Username_password -> `String "username_password"

    type t =
      ([ `Oidc_aws
       | `Oidc_azure
       | `Oidc_cloudsmith
       | `Oidc_gcp
       | `Oidc_jfrog
       | `Token
       | `Username_password
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Registry_type = struct
    let t_of_yojson = function
      | `String "cargo_registry" -> Ok `Cargo_registry
      | `String "composer_repository" -> Ok `Composer_repository
      | `String "docker_registry" -> Ok `Docker_registry
      | `String "git_source" -> Ok `Git_source
      | `String "goproxy_server" -> Ok `Goproxy_server
      | `String "helm_registry" -> Ok `Helm_registry
      | `String "hex_organization" -> Ok `Hex_organization
      | `String "hex_repository" -> Ok `Hex_repository
      | `String "maven_repository" -> Ok `Maven_repository
      | `String "npm_registry" -> Ok `Npm_registry
      | `String "nuget_feed" -> Ok `Nuget_feed
      | `String "pub_repository" -> Ok `Pub_repository
      | `String "python_index" -> Ok `Python_index
      | `String "rubygems_server" -> Ok `Rubygems_server
      | `String "terraform_registry" -> Ok `Terraform_registry
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Cargo_registry -> `String "cargo_registry"
      | `Composer_repository -> `String "composer_repository"
      | `Docker_registry -> `String "docker_registry"
      | `Git_source -> `String "git_source"
      | `Goproxy_server -> `String "goproxy_server"
      | `Helm_registry -> `String "helm_registry"
      | `Hex_organization -> `String "hex_organization"
      | `Hex_repository -> `String "hex_repository"
      | `Maven_repository -> `String "maven_repository"
      | `Npm_registry -> `String "npm_registry"
      | `Nuget_feed -> `String "nuget_feed"
      | `Pub_repository -> `String "pub_repository"
      | `Python_index -> `String "python_index"
      | `Rubygems_server -> `String "rubygems_server"
      | `Terraform_registry -> `String "terraform_registry"

    type t =
      ([ `Cargo_registry
       | `Composer_repository
       | `Docker_registry
       | `Git_source
       | `Goproxy_server
       | `Helm_registry
       | `Hex_organization
       | `Hex_repository
       | `Maven_repository
       | `Npm_registry
       | `Nuget_feed
       | `Pub_repository
       | `Python_index
       | `Rubygems_server
       | `Terraform_registry
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Visibility = struct
    let t_of_yojson = function
      | `String "all" -> Ok `All
      | `String "private" -> Ok `Private
      | `String "selected" -> Ok `Selected
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `All -> `String "all"
      | `Private -> `String "private"
      | `Selected -> `String "selected"

    type t =
      ([ `All
       | `Private
       | `Selected
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    account_id : string option; [@default None]
    api_host : string option; [@default None]
    audience : string option; [@default None]
    auth_type : Auth_type.t option; [@default None]
    aws_region : string option; [@default None]
    client_id : string option; [@default None]
    created_at : string;
    domain : string option; [@default None]
    domain_owner : string option; [@default None]
    identity_mapping_name : string option; [@default None]
    jfrog_oidc_provider_name : string option; [@default None]
    name : string;
    namespace : string option; [@default None]
    registry_type : Registry_type.t;
    replaces_base : bool; [@default false]
    role_name : string option; [@default None]
    service_account : string option; [@default None]
    service_slug : string option; [@default None]
    tenant_id : string option; [@default None]
    updated_at : string;
    url : string option; [@default None]
    username : string option; [@default None]
    visibility : Visibility.t;
    workload_identity_provider : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
