# Children of Ur: local development setup

This directory contains a locally runnable copy of the archived Children of Ur project. The project consists of an old Dart browser client, a Dart game server, and a separate Dart authentication server.

This document records what is checked out, how the local Docker stack is configured, how to start and stop it, and which production features are intentionally unavailable.

## Project layout

| Path | Purpose |
| --- | --- |
| `coUclient/` | Browser client and static web assets |
| `coUserver/` | Game HTTP/WebSocket server |
| `authServer/` | Authentication and account server |
| `vendor/` | Pinned Dart packages and local compatibility packages |
| `docker-compose.yml` | PostgreSQL, game server, auth server, and client services |
| `docker/` | Dockerfiles, PostgreSQL initialization, and local database access rules |
| `start-local.ps1` | Foreground convenience startup script |

## Repository sources

The main repositories came from the [ChildrenOfUr GitHub organization](https://github.com/ChildrenOfUr):

| Local path | Repository | Checked-out branch |
| --- | --- | --- |
| `coUclient` | [ChildrenOfUr/coUclient](https://github.com/ChildrenOfUr/coUclient) | `dev` |
| `coUserver` | [ChildrenOfUr/coUserver](https://github.com/ChildrenOfUr/coUserver) | `dev` |
| `authServer` | [ChildrenOfUr/authServer](https://github.com/ChildrenOfUr/authServer) | `dev` |
| `vendor/cou_login` | [ChildrenOfUr/cou_login](https://github.com/ChildrenOfUr/cou_login) | `dart-2` |
| `vendor/cou_toolkit` | [ChildrenOfUr/cou_toolkit](https://github.com/ChildrenOfUr/cou_toolkit) | `dart-2` |
| `vendor/emoticons` | [ChildrenOfUr/emoticons](https://github.com/ChildrenOfUr/emoticons) | `dart-2` |
| `vendor/gorgonDart` | [ChildrenOfUr/gorgonDart](https://github.com/ChildrenOfUr/gorgonDart) | `dart-2` |
| `vendor/libld` | [ChildrenOfUr/libld](https://github.com/ChildrenOfUr/libld) | `dart-2` |
| `vendor/scproxy` | [ChildrenOfUr/scproxy](https://github.com/ChildrenOfUr/scproxy) | `dart-2` |
| `vendor/dart-slack` | [ChildrenOfUr/dart-slack](https://github.com/ChildrenOfUr/dart-slack) | `master` |
| `vendor/transmit` | [ChildrenOfUr/transmit](https://github.com/ChildrenOfUr/transmit) | `master` |
| `vendor/mailer` | [RobertMcDermot/mailer](https://github.com/RobertMcDermot/mailer) | `master` |

The other directories under `vendor/` are copied or reconstructed compatibility packages needed by the archived pub dependencies, including `di`, `inflection`, `jsonx`, `message_bus`, `postgresql`, `redstone`, `redstone_mapper`, `redstone_mapper_pg`, and `route_hierarchical`.

## Version control

This directory is now a git repository, pushed to
[davidmanheim/ChildrenOfUr](https://github.com/davidmanheim/ChildrenOfUr).
`coUserver/`, `coUclient/`, and `authServer/` are **git-subtree merges** of
real forks of the upstream repos, not copied snapshots:

| Subdirectory | Fork (origin of subtree) | Upstream |
| --- | --- | --- |
| `coUserver/` | [davidmanheim/coUserver](https://github.com/davidmanheim/coUserver) | [ChildrenOfUr/coUserver](https://github.com/ChildrenOfUr/coUserver) |
| `coUclient/` | [davidmanheim/coUclient](https://github.com/davidmanheim/coUclient) | [ChildrenOfUr/coUclient](https://github.com/ChildrenOfUr/coUclient) |
| `authServer/` | [davidmanheim/authServer](https://github.com/davidmanheim/authServer) | [ChildrenOfUr/authServer](https://github.com/ChildrenOfUr/authServer) |

Each was merged at prefix `<name>/` from its fork's `dev` branch via
`git subtree add`, so the full original commit history/blame for those three
subdirectories is preserved (see `git log --follow` inside them), followed by
one commit applying this project's local-revival modifications on top. The
local git remotes `coUserver-fork`/`coUclient-fork`/`authServer-fork` point at
the forks (push target for sending changes upstream) and
`coUserver-upstream`/`coUclient-upstream`/`authServer-upstream` point at the
original `ChildrenOfUr` org repos (fetch target for pulling upstream changes).

Everything else (root docs, `vendor/`, `docker/`, `tools/`, `content/`) is
plain history local to the umbrella repo — the `vendor/` packages are vendored
snapshots, not forks, since they're pinned compatibility copies rather than
something changes would be sent upstream for.

`tmp/` (downloaded reference archives — `glitch-items`, `glitch-gameserver`,
browser-check data) and any `*.zip`/`*.crdownload` files dropped in the repo
root (e.g. a soundtrack archive) are gitignored: too large and/or
licensing-sensitive for normal git history. Keep them local-only unless a
deliberate decision is made to host them elsewhere (e.g. Git LFS, object
storage, or an external link).

## Prerequisites

- Windows PowerShell.
- Docker Desktop with the Linux engine running.
- Enough disk space for the historical Dart SDKs and Docker build layers.

The application does not require Dart installed on the host. The Dockerfiles download the compatible SDKs:

- Dart `2.7.0` for `coUserver` and `authServer`.
- Dart `2.1.1` for `coUclient`, because its archived Angular build toolchain predates newer SDKs.

If Docker Desktop has been restarted, the containers may be stopped even though their definitions still exist. Run the startup command again.

## Start the complete stack

From this directory:

```powershell
cd C:\Apps\ChildrenOfUr
docker compose up -d --build
```

The first build can take several minutes because the client uses the historical Angular/Dart compiler. To run in the foreground instead, use:

```powershell
.\start-local.ps1
```

Open the client at <http://localhost:8080>.

## Services and ports

| Service | Local address | Purpose |
| --- | --- | --- |
| Client | <http://localhost:8080> | Browser application |
| Game HTTP server | <http://localhost:8181> | Game API |
| Game WebSocket server | `ws://localhost:8282` | Game and chat sockets |
| Auth HTTP server | <http://localhost:8383> | Login/account API |
| Auth WebSocket server | `ws://localhost:8484` | Email verification socket |
| PostgreSQL | `localhost:5432` | Local database |

Useful checks:

```powershell
docker compose ps
Invoke-WebRequest http://localhost:8181/serverStatus
Invoke-WebRequest http://localhost:8383/serverStatus
```

The status endpoints should return HTTP 200. The game server loads its map, quests, achievements, and recipes during startup; the client build log should end with `Succeeded` and `Serving web on http://0.0.0.0:8080`.

## Local configuration

The browser reads `coUclient/web/server_domain.txt`, which is currently:

```text
localhost
```

That produces these client URLs:

```text
http://localhost:8181
ws://localhost:8282
http://localhost:8383
ws://localhost:8484
```

The local game server configuration is in `coUserver/lib/API_KEYS.dart`; the auth configuration is in `authServer/API_KEYS.dart`. Both use the Docker PostgreSQL connection:

```text
postgres://cou:cou@postgres:5432/cou
```

The local Redstone token is intentionally empty in both the server and client:

- `coUserver/lib/API_KEYS.dart`: `redstoneToken = ''`
- `coUclient/web/main.dart`: `rsToken = ''`

Keep those values aligned. If the client sends a non-empty production token, `/getMapData` returns `Invalid token` and the client shows its generic “server down” message even though the server is running.

## Database

PostgreSQL uses the `cou-postgres` Docker volume. `docker/postgres/init.sql` creates a minimal local schema for development; it is not a production database dump.

Normal stop, preserving data:

```powershell
docker compose down
```

Recreate the empty local database after changing the initialization SQL:

```powershell
docker compose down -v
docker compose up -d --build
```

The `-v` command deletes the local PostgreSQL volume and is intentionally destructive to local database data.

## What was adapted for local execution

The public repositories target obsolete Dart and package APIs. The local copy includes compatibility work needed to run them in Docker, including:

- Local path dependencies for the archived Children of Ur packages.
- Historical Dart SDK selection in the Dockerfiles.
- Dart 2 compatibility fixes for JSON, reflection, Redstone, PostgreSQL, and old collection typing.
- A legacy mapper adjustment for raw `List` and `Map` model fields.
- Non-interactive console handling for detached Docker containers.
- A corrected generated Angular login-component import and Firebase 5 compilation compatibility.
- Local PostgreSQL schema and Docker-network authentication rules.
- Local empty API tokens and `--no-load-cert`, since production certificates are not present.

## Working-tree status

The main repositories and the `cou_login` package are intentionally not pristine: they contain the local compatibility edits described above, plus generated Dart dependency/build files created during Docker builds. Preserve those changes when updating dependencies or switching branches. Do not run `git reset --hard` or discard uncommitted changes unless you are deliberately rebuilding the local port from scratch.

## Known limitations

- The public repositories do not contain production API credentials, certificates, or the production PostgreSQL dump.
- Slack, SoundCloud, SMTP email, weather, and other third-party integrations are disabled or have empty local credentials.
- The archived login UI still references Firebase, so fully local account authentication requires configuring a compatible Firebase project or further replacing that integration.
- The empty local database has no production users or game history. The game server may log that its API-access table could not be populated; it continues startup with an empty access set.
- Some asset and profile links in the archived client still point to public Children of Ur services.
- `localhost` works when the browser is on the same machine as Docker. If the browser is on another machine, replace `coUclient/web/server_domain.txt` with the Docker host name or LAN IP and rebuild/restart the client.

## Troubleshooting

View service logs:

```powershell
docker compose logs --tail=100 game-server
docker compose logs --tail=100 auth-server
docker compose logs --tail=100 client
```

If the browser still displays the old server-down screen after changing client code, do a hard refresh with `Ctrl+F5`. If Docker Desktop was restarted, run `docker compose up -d` again.

If the client reports the server is down, test the exact map request:

```powershell
$r = Invoke-WebRequest 'http://localhost:8181/getMapData?token=' -SkipHttpErrorCheck
"HTTP $($r.StatusCode), $($r.Content.Length) bytes"
```

It should return HTTP 200 and JSON beginning with the map data. An `Invalid token` response means the client and `coUserver/lib/API_KEYS.dart` no longer agree about the local empty token.

Last verified: 2026-08-26. At verification time, PostgreSQL, game server, auth server, and client were all running; the client and both status endpoints returned HTTP 200, and the map-data request returned HTTP 200.
