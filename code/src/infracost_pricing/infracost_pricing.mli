(** The Infracost CLI pricing protocol, served from the [products] table of the [cloud_pricing]
    database.

    The CLI posts a batch of GraphQL queries and reads back one element for each element it sent, in
    the same order. *)

module Regex : sig
  type case =
    | Sensitive
    | Insensitive
  [@@deriving show, eq]

  type t = {
    pattern : string;
    case : case;
  }
  [@@deriving show, eq]
end

module Attribute_filter : sig
  (** [Never] is a filter that carries neither a value nor a pattern. It matches no product. *)
  type match_ =
    | Eq of string
    | Empty
    | Regex of Regex.t
    | Never
  [@@deriving show, eq]

  type t = {
    key : string;
    match_ : match_;
  }
  [@@deriving show, eq]
end

module Filter : sig
  (** The product filter and the price filter of one query, with the rate that changes the stored US
      dollar price into [currency].

      A field that is [None] puts no condition on the query. An empty string matches a column or a
      key that is absent or empty. *)
  type t = {
    vendor_name : string option;
    service : string option;
    product_family : string option;
    region : string option;
    sku : string option;
    attribute_filters : Attribute_filter.t list;
    purchase_option : string option;
    unit : string option;
    description : string option;
    description_regex : Regex.t option;
    start_usage_amount : string option;
    end_usage_amount : string option;
    term_length : string option;
    term_purchase_option : string option;
    term_offering_class : string option;
    currency : string;
    rate : string;
  }
  [@@deriving show, eq]
end

module Element : sig
  (** [Probe] is the empty query that the CLI posts before each run to test the API key. *)
  type t =
    | Probe
    | Query of Filter.t
  [@@deriving show, eq]
end

type err =
  [ `Bad_request_err
  | `Unsupported_currency_err
  ]
[@@deriving show, eq]

(** Read a batch. The body must be an array whose elements are the empty query or the fixed
    product-and-price query of the CLI, which carries the currency as the name of the price field.
*)
val decode : Yojson.Safe.t -> (Element.t list, [> err ]) result

(** Run a batch and build the response array. A batch that holds a query takes one connection from
    the pool. *)
val run :
  Pgsql_pool.t ->
  Element.t list ->
  ( Terrat_api_components.Infracost_graphql_batch_response.t,
    [> Pgsql_pool.err | Pgsql_io.err ] )
  result
  Abb.Future.t

module Tests : sig
  (** Read the [/pattern/flags] form that the CLI sends. Text that is not in that form gives the
      empty pattern, which matches everything.

      {v
      regex_of_string "/^foo/"  = { pattern = "^foo"; case = Sensitive }
      regex_of_string "/^foo/i" = { pattern = "^foo"; case = Insensitive }
      regex_of_string "/a/b/i"  = { pattern = "a/b";  case = Insensitive }
      regex_of_string "foo"     = { pattern = "";     case = Sensitive }
      v} *)
  val regex_of_string : string -> Regex.t

  module Row : sig
    (** [Merge_cny] marks the prices of an AWS product that carries no region. Only these prices
        merge their Chinese yuan twin. *)
    type cny_merge =
      | Merge_cny
      | No_cny_merge
    [@@deriving show, eq]

    (** One price of one product. [amount] is the stored US dollar price in the currency the batch
        asked for, and [cny_amount] is the stored Chinese yuan price in that same currency. Each one
        is [None] when the price does not carry that amount. *)
    type t = {
      product_hash : string;
      price_hash : string option;
      amount : string option;
      cny_amount : string option;
      start_usage_amount : string option;
      end_usage_amount : string option;
      cny_merge : cny_merge;
    }
    [@@deriving show, eq]
  end

  (** Build the response element for one batch element. The rows are the prices that match the
      filter of that element.

      A price that carries no US dollar amount takes the Chinese yuan amount instead. On an AWS
      product that carries no region, a yuan price that is alone in its group and carries no US
      dollar amount first merges into the price with the same hash without the ["-cny"] suffix and
      the same usage amounts, and then leaves the answer. *)
  val encode : Element.t -> Row.t list -> Terrat_api_components.Infracost_graphql_response.t

  (** {!run} on the given connection. *)
  val run_on_conn :
    Pgsql_io.t ->
    Element.t list ->
    (Terrat_api_components.Infracost_graphql_batch_response.t, [> Pgsql_io.err ]) result
    Abb.Future.t
end
