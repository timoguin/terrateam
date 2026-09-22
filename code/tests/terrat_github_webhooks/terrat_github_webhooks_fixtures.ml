let app_payload =
  {json|{
  "client_id": "client_id",
  "created_at": "2026-09-05T06:21:37Z",
  "description": "A bot that comments",
  "events": [
    "issue_comment"
  ],
  "external_url": "https://example.com/some-bot",
  "html_url": "https://api.github.com/html_url",
  "id": 1,
  "name": "Some Bot",
  "node_id": "NODE",
  "owner": {
    "avatar_url": "https://api.github.com/avatar_url",
    "events_url": "https://api.github.com/events_url",
    "followers_url": "https://api.github.com/followers_url",
    "following_url": "https://api.github.com/following_url",
    "gists_url": "https://api.github.com/gists_url",
    "gravatar_id": "gravatar_id",
    "html_url": "https://api.github.com/html_url",
    "id": 1,
    "login": "an-org",
    "node_id": "NODE",
    "organizations_url": "https://api.github.com/organizations_url",
    "received_events_url": "https://api.github.com/received_events_url",
    "repos_url": "https://api.github.com/repos_url",
    "site_admin": false,
    "starred_url": "https://api.github.com/starred_url",
    "subscriptions_url": "https://api.github.com/subscriptions_url",
    "type": "Organization",
    "url": "https://api.github.com/url",
    "user_view_type": "public"
  },
  "permissions": {
    "contents": "read",
    "pull_requests": "write"
  },
  "slug": "some-bot",
  "updated_at": "2026-09-05T06:21:37Z"
}|json}

let base_payload =
  {json|{
  "action": "created",
  "comment": {
    "author_association": "author_association",
    "body": "terrateam plan",
    "created_at": "2026-09-05T06:21:37Z",
    "html_url": "https://api.github.com/html_url",
    "id": 1,
    "issue_url": "https://api.github.com/issue_url",
    "minimized": null,
    "node_id": "NODE",
    "performed_via_github_app": null,
    "reactions": {
      "total_count": 1,
      "url": "https://api.github.com/url"
    },
    "updated_at": "2026-09-05T06:21:37Z",
    "url": "https://api.github.com/url",
    "user": {
      "avatar_url": "https://api.github.com/avatar_url",
      "events_url": "https://api.github.com/events_url",
      "followers_url": "https://api.github.com/followers_url",
      "following_url": "https://api.github.com/following_url",
      "gists_url": "https://api.github.com/gists_url",
      "gravatar_id": "gravatar_id",
      "html_url": "https://api.github.com/html_url",
      "id": 1,
      "login": "a-person",
      "node_id": "NODE",
      "organizations_url": "https://api.github.com/organizations_url",
      "received_events_url": "https://api.github.com/received_events_url",
      "repos_url": "https://api.github.com/repos_url",
      "site_admin": false,
      "starred_url": "https://api.github.com/starred_url",
      "subscriptions_url": "https://api.github.com/subscriptions_url",
      "type": "User",
      "url": "https://api.github.com/url",
      "user_view_type": "public"
    }
  },
  "installation": {
    "id": 1,
    "node_id": "NODE"
  },
  "issue": {
    "active_lock_reason": "active_lock_reason",
    "assignees": [],
    "author_association": "author_association",
    "comments": 1,
    "comments_url": "https://api.github.com/comments_url",
    "created_at": "2026-09-05T06:21:37Z",
    "draft": false,
    "events_url": "https://api.github.com/events_url",
    "html_url": "https://api.github.com/html_url",
    "id": 1,
    "labels": [
      {
        "archived_at": null,
        "archived_by": null,
        "color": "color",
        "default": false,
        "description": "description",
        "id": 1,
        "name": "name",
        "node_id": "NODE",
        "url": "https://api.github.com/url"
      }
    ],
    "labels_url": "https://api.github.com/labels_url",
    "locked": false,
    "milestone": null,
    "node_id": "NODE",
    "number": 42,
    "performed_via_github_app": null,
    "pull_request": {
      "url": "https://api.github.com/pull"
    },
    "reactions": {
      "total_count": 1,
      "url": "https://api.github.com/url"
    },
    "repository_url": "https://api.github.com/repository_url",
    "state": "open",
    "state_reason": null,
    "timeline_url": "https://api.github.com/timeline_url",
    "title": "title",
    "updated_at": "2026-09-05T06:21:37Z",
    "url": "https://api.github.com/url",
    "user": {
      "avatar_url": "https://api.github.com/avatar_url",
      "events_url": "https://api.github.com/events_url",
      "followers_url": "https://api.github.com/followers_url",
      "following_url": "https://api.github.com/following_url",
      "gists_url": "https://api.github.com/gists_url",
      "gravatar_id": "gravatar_id",
      "html_url": "https://api.github.com/html_url",
      "id": 1,
      "login": "a-person",
      "node_id": "NODE",
      "organizations_url": "https://api.github.com/organizations_url",
      "received_events_url": "https://api.github.com/received_events_url",
      "repos_url": "https://api.github.com/repos_url",
      "site_admin": false,
      "starred_url": "https://api.github.com/starred_url",
      "subscriptions_url": "https://api.github.com/subscriptions_url",
      "type": "User",
      "url": "https://api.github.com/url",
      "user_view_type": "public"
    }
  },
  "repository": {
    "archive_url": "https://api.github.com/archive_url",
    "archived": false,
    "assignees_url": "https://api.github.com/assignees_url",
    "blobs_url": "https://api.github.com/blobs_url",
    "branches_url": "https://api.github.com/branches_url",
    "clone_url": "https://api.github.com/clone_url",
    "collaborators_url": "https://api.github.com/collaborators_url",
    "comments_url": "https://api.github.com/comments_url",
    "commits_url": "https://api.github.com/commits_url",
    "compare_url": "https://api.github.com/compare_url",
    "contents_url": "https://api.github.com/contents_url",
    "contributors_url": "https://api.github.com/contributors_url",
    "created_at": 1,
    "default_branch": "default_branch",
    "deployments_url": "https://api.github.com/deployments_url",
    "description": "description",
    "downloads_url": "https://api.github.com/downloads_url",
    "events_url": "https://api.github.com/events_url",
    "fork": false,
    "forks": 1,
    "forks_count": 1,
    "forks_url": "https://api.github.com/forks_url",
    "full_name": "full_name",
    "git_commits_url": "https://api.github.com/git_commits_url",
    "git_refs_url": "https://api.github.com/git_refs_url",
    "git_tags_url": "https://api.github.com/git_tags_url",
    "git_url": "https://api.github.com/git_url",
    "has_downloads": false,
    "has_issues": false,
    "has_pages": false,
    "has_projects": false,
    "has_pull_requests": true,
    "has_wiki": false,
    "homepage": "homepage",
    "hooks_url": "https://api.github.com/hooks_url",
    "html_url": "https://api.github.com/html_url",
    "id": 1,
    "is_template": false,
    "issue_comment_url": "https://api.github.com/issue_comment_url",
    "issue_events_url": "https://api.github.com/issue_events_url",
    "issues_url": "https://api.github.com/issues_url",
    "keys_url": "https://api.github.com/keys_url",
    "labels_url": "https://api.github.com/labels_url",
    "language": "language",
    "languages_url": "https://api.github.com/languages_url",
    "merges_url": "https://api.github.com/merges_url",
    "milestones_url": "https://api.github.com/milestones_url",
    "mirror_url": "https://api.github.com/mirror_url",
    "name": "name",
    "node_id": "NODE",
    "notifications_url": "https://api.github.com/notifications_url",
    "open_issues": 1,
    "open_issues_count": 1,
    "owner": {
      "avatar_url": "https://api.github.com/avatar_url",
      "events_url": "https://api.github.com/events_url",
      "followers_url": "https://api.github.com/followers_url",
      "following_url": "https://api.github.com/following_url",
      "gists_url": "https://api.github.com/gists_url",
      "gravatar_id": "gravatar_id",
      "html_url": "https://api.github.com/html_url",
      "id": 1,
      "login": "an-org",
      "node_id": "NODE",
      "organizations_url": "https://api.github.com/organizations_url",
      "received_events_url": "https://api.github.com/received_events_url",
      "repos_url": "https://api.github.com/repos_url",
      "site_admin": false,
      "starred_url": "https://api.github.com/starred_url",
      "subscriptions_url": "https://api.github.com/subscriptions_url",
      "type": "Organization",
      "url": "https://api.github.com/url",
      "user_view_type": "public"
    },
    "private": false,
    "pull_request_creation_policy": "all",
    "pulls_url": "https://api.github.com/pulls_url",
    "releases_url": "https://api.github.com/releases_url",
    "size": 1,
    "ssh_url": "https://api.github.com/ssh_url",
    "stargazers_count": 1,
    "stargazers_url": "https://api.github.com/stargazers_url",
    "statuses_url": "https://api.github.com/statuses_url",
    "subscribers_url": "https://api.github.com/subscribers_url",
    "subscription_url": "https://api.github.com/subscription_url",
    "svn_url": "https://api.github.com/svn_url",
    "tags_url": "https://api.github.com/tags_url",
    "teams_url": "https://api.github.com/teams_url",
    "topics": [
      "topics"
    ],
    "trees_url": "https://api.github.com/trees_url",
    "updated_at": "2026-09-05T06:21:37Z",
    "url": "https://api.github.com/url",
    "visibility": "visibility",
    "watchers": 1,
    "watchers_count": 1
  },
  "sender": {
    "avatar_url": "https://api.github.com/avatar_url",
    "events_url": "https://api.github.com/events_url",
    "followers_url": "https://api.github.com/followers_url",
    "following_url": "https://api.github.com/following_url",
    "gists_url": "https://api.github.com/gists_url",
    "gravatar_id": "gravatar_id",
    "html_url": "https://api.github.com/html_url",
    "id": 1,
    "login": "a-person",
    "node_id": "NODE",
    "organizations_url": "https://api.github.com/organizations_url",
    "received_events_url": "https://api.github.com/received_events_url",
    "repos_url": "https://api.github.com/repos_url",
    "site_admin": false,
    "starred_url": "https://api.github.com/starred_url",
    "subscriptions_url": "https://api.github.com/subscriptions_url",
    "type": "User",
    "url": "https://api.github.com/url",
    "user_view_type": "public"
  }
}|json}

let json_of_string s = Yojson.Safe.from_string s

let remove_member key = function
  | `Assoc kvs -> `Assoc (CCList.filter (fun (k, _) -> not (CCString.equal k key)) kvs)
  | json -> json

let set_member key v json =
  match remove_member key json with
  | `Assoc kvs -> `Assoc ((key, v) :: kvs)
  | json -> json

let update_member key f = function
  | `Assoc kvs ->
      `Assoc (CCList.map (fun (k, v) -> if CCString.equal k key then (k, f v) else (k, v)) kvs)
  | json -> json
