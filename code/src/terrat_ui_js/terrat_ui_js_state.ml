type t = {
  client : Terrat_ui_js_client.t;
  user : Terrat_api_components.User.t;
  installations : Terrat_api_components.Installation.t list Brtl_js2.Note.S.t;
  selected_installation : Terrat_api_components.Installation.t;
  notifications : Terrat_ui_js_notification.t Brtl_js2.Note.E.t;
  notify : Terrat_ui_js_notification.t Brtl_js2.Note.E.send;
}

let create ~client ~user ~installations ~selected_installation () =
  let notifications, notify = Brtl_js2.Note.E.create () in
  { client; user; installations; selected_installation; notifications; notify }

let user t = t.user
let client t = t.client
let installations t = t.installations
let selected_installation t = t.selected_installation

let notify t msg =
  let notification = Terrat_ui_js_notification.make ~msg () in
  t.notify notification

let notifications t = t.notifications