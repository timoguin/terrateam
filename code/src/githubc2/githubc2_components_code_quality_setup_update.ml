module V0 = struct
  module Ai_findings_option = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "on_push" -> Ok `On_push
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `On_push -> `String "on_push"

    type t =
      ([ `Disabled
       | `On_push
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Languages = struct
    module Items = struct
      let t_of_yojson = function
        | `String "csharp" -> Ok `Csharp
        | `String "go" -> Ok `Go
        | `String "java-kotlin" -> Ok `Java_kotlin
        | `String "javascript-typescript" -> Ok `Javascript_typescript
        | `String "python" -> Ok `Python
        | `String "ruby" -> Ok `Ruby
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Csharp -> `String "csharp"
        | `Go -> `String "go"
        | `Java_kotlin -> `String "java-kotlin"
        | `Javascript_typescript -> `String "javascript-typescript"
        | `Python -> `String "python"
        | `Ruby -> `String "ruby"

      type t =
        ([ `Csharp
         | `Go
         | `Java_kotlin
         | `Javascript_typescript
         | `Python
         | `Ruby
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Runner_type = struct
    let t_of_yojson = function
      | `String "labeled" -> Ok `Labeled
      | `String "standard" -> Ok `Standard
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Labeled -> `String "labeled"
      | `Standard -> `String "standard"

    type t =
      ([ `Labeled
       | `Standard
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "configured" -> Ok `Configured
      | `String "not-configured" -> Ok `Not_configured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Configured -> `String "configured"
      | `Not_configured -> `String "not-configured"

    type t =
      ([ `Configured
       | `Not_configured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    ai_findings_option : Ai_findings_option.t option; [@default None]
    languages : Languages.t option; [@default None]
    runner_label : string option; [@default None]
    runner_type : Runner_type.t option; [@default None]
    state : State.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module V1 = struct
  module Ai_findings_option = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "on_push" -> Ok `On_push
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `On_push -> `String "on_push"

    type t =
      ([ `Disabled
       | `On_push
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Languages = struct
    module Items = struct
      let t_of_yojson = function
        | `String "csharp" -> Ok `Csharp
        | `String "go" -> Ok `Go
        | `String "java-kotlin" -> Ok `Java_kotlin
        | `String "javascript-typescript" -> Ok `Javascript_typescript
        | `String "python" -> Ok `Python
        | `String "ruby" -> Ok `Ruby
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Csharp -> `String "csharp"
        | `Go -> `String "go"
        | `Java_kotlin -> `String "java-kotlin"
        | `Javascript_typescript -> `String "javascript-typescript"
        | `Python -> `String "python"
        | `Ruby -> `String "ruby"

      type t =
        ([ `Csharp
         | `Go
         | `Java_kotlin
         | `Javascript_typescript
         | `Python
         | `Ruby
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Runner_type = struct
    let t_of_yojson = function
      | `String "labeled" -> Ok `Labeled
      | `String "standard" -> Ok `Standard
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Labeled -> `String "labeled"
      | `Standard -> `String "standard"

    type t =
      ([ `Labeled
       | `Standard
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "configured" -> Ok `Configured
      | `String "not-configured" -> Ok `Not_configured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Configured -> `String "configured"
      | `Not_configured -> `String "not-configured"

    type t =
      ([ `Configured
       | `Not_configured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    ai_findings_option : Ai_findings_option.t option; [@default None]
    languages : Languages.t option; [@default None]
    runner_label : string option; [@default None]
    runner_type : Runner_type.t;
    state : State.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module V2 = struct
  module Ai_findings_option = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "on_push" -> Ok `On_push
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `On_push -> `String "on_push"

    type t =
      ([ `Disabled
       | `On_push
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Languages = struct
    module Items = struct
      let t_of_yojson = function
        | `String "csharp" -> Ok `Csharp
        | `String "go" -> Ok `Go
        | `String "java-kotlin" -> Ok `Java_kotlin
        | `String "javascript-typescript" -> Ok `Javascript_typescript
        | `String "python" -> Ok `Python
        | `String "ruby" -> Ok `Ruby
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Csharp -> `String "csharp"
        | `Go -> `String "go"
        | `Java_kotlin -> `String "java-kotlin"
        | `Javascript_typescript -> `String "javascript-typescript"
        | `Python -> `String "python"
        | `Ruby -> `String "ruby"

      type t =
        ([ `Csharp
         | `Go
         | `Java_kotlin
         | `Javascript_typescript
         | `Python
         | `Ruby
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Runner_type = struct
    let t_of_yojson = function
      | `String "labeled" -> Ok `Labeled
      | `String "standard" -> Ok `Standard
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Labeled -> `String "labeled"
      | `Standard -> `String "standard"

    type t =
      ([ `Labeled
       | `Standard
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "configured" -> Ok `Configured
      | `String "not-configured" -> Ok `Not_configured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Configured -> `String "configured"
      | `Not_configured -> `String "not-configured"

    type t =
      ([ `Configured
       | `Not_configured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    ai_findings_option : Ai_findings_option.t option; [@default None]
    languages : Languages.t option; [@default None]
    runner_label : string option; [@default None]
    runner_type : Runner_type.t option; [@default None]
    state : State.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module V3 = struct
  module Ai_findings_option = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "on_push" -> Ok `On_push
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `On_push -> `String "on_push"

    type t =
      ([ `Disabled
       | `On_push
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Languages = struct
    module Items = struct
      let t_of_yojson = function
        | `String "csharp" -> Ok `Csharp
        | `String "go" -> Ok `Go
        | `String "java-kotlin" -> Ok `Java_kotlin
        | `String "javascript-typescript" -> Ok `Javascript_typescript
        | `String "python" -> Ok `Python
        | `String "ruby" -> Ok `Ruby
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Csharp -> `String "csharp"
        | `Go -> `String "go"
        | `Java_kotlin -> `String "java-kotlin"
        | `Javascript_typescript -> `String "javascript-typescript"
        | `Python -> `String "python"
        | `Ruby -> `String "ruby"

      type t =
        ([ `Csharp
         | `Go
         | `Java_kotlin
         | `Javascript_typescript
         | `Python
         | `Ruby
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Runner_type = struct
    let t_of_yojson = function
      | `String "labeled" -> Ok `Labeled
      | `String "standard" -> Ok `Standard
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Labeled -> `String "labeled"
      | `Standard -> `String "standard"

    type t =
      ([ `Labeled
       | `Standard
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "configured" -> Ok `Configured
      | `String "not-configured" -> Ok `Not_configured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Configured -> `String "configured"
      | `Not_configured -> `String "not-configured"

    type t =
      ([ `Configured
       | `Not_configured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    ai_findings_option : Ai_findings_option.t option; [@default None]
    languages : Languages.t;
    runner_label : string option; [@default None]
    runner_type : Runner_type.t option; [@default None]
    state : State.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module V4 = struct
  module Ai_findings_option = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "on_push" -> Ok `On_push
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `On_push -> `String "on_push"

    type t =
      ([ `Disabled
       | `On_push
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Languages = struct
    module Items = struct
      let t_of_yojson = function
        | `String "csharp" -> Ok `Csharp
        | `String "go" -> Ok `Go
        | `String "java-kotlin" -> Ok `Java_kotlin
        | `String "javascript-typescript" -> Ok `Javascript_typescript
        | `String "python" -> Ok `Python
        | `String "ruby" -> Ok `Ruby
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Csharp -> `String "csharp"
        | `Go -> `String "go"
        | `Java_kotlin -> `String "java-kotlin"
        | `Javascript_typescript -> `String "javascript-typescript"
        | `Python -> `String "python"
        | `Ruby -> `String "ruby"

      type t =
        ([ `Csharp
         | `Go
         | `Java_kotlin
         | `Javascript_typescript
         | `Python
         | `Ruby
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Runner_type = struct
    let t_of_yojson = function
      | `String "labeled" -> Ok `Labeled
      | `String "standard" -> Ok `Standard
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Labeled -> `String "labeled"
      | `Standard -> `String "standard"

    type t =
      ([ `Labeled
       | `Standard
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "configured" -> Ok `Configured
      | `String "not-configured" -> Ok `Not_configured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Configured -> `String "configured"
      | `Not_configured -> `String "not-configured"

    type t =
      ([ `Configured
       | `Not_configured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    ai_findings_option : Ai_findings_option.t;
    languages : Languages.t option; [@default None]
    runner_label : string option; [@default None]
    runner_type : Runner_type.t option; [@default None]
    state : State.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t =
  | V0 of V0.t
  | V1 of V1.t
  | V2 of V2.t
  | V3 of V3.t
  | V4 of V4.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.any_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
       (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
       (fun v -> map (fun v -> V3 v) (V3.of_yojson v));
       (fun v -> map (fun v -> V4 v) (V4.of_yojson v));
     ])

let to_yojson = function
  | V0 v -> V0.to_yojson v
  | V1 v -> V1.to_yojson v
  | V2 v -> V2.to_yojson v
  | V3 v -> V3.to_yojson v
  | V4 v -> V4.to_yojson v
