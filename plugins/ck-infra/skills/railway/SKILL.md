---
name: railway
description: "Use for ANY Railway work: creating, configuring or deploying Railway projects, services, databases (Postgres, MySQL, Redis, Mongo), volumes, buckets, domains or variables; running the railway CLI; writing .railway/railway.ts, railway.json or railway.toml; or reviewing Railway setup."
---

# Railway: IaC + CLI deploys + Dockerfiles + generic names

Apply these rules to every Railway task, even if the user did not mention them. If the project already breaks a rule, fix it in what you touch and list the rest in one line at the end.

## 1. The rules

| Do | Never |
|---|---|
| Describe infrastructure with Railway IaC in `.railway/` (one file per service, section 3) and apply with `pnpm apply` | `railway.json` / `railway.toml`, or creating/configuring services by hand in the dashboard |
| Deploy code with `railway up` from the CLI | Link a GitHub repo: no `github()` source, no `source: { repo }`, no `railway service source connect`, no "Deploy from GitHub repo" in the dashboard |
| Build every service, databases included, from a `Dockerfile` in the repo (`builder: "DOCKERFILE"`) | Railway templates or managed database helpers: `railway deploy` (templates), `railway add --database`, `template()`, `postgres()`, `mysql()`, `redis()`, `mongo()`, `database()`; Nixpacks / Railpack / auto-detected builds |
| Name services and volumes by role: `database`, `database-data` | Names with the product, project, vendor or technology: `myapp-api`, `postgres`, `Postgres-xyz1`, `redis`, `pg-volume` |
| Give every service and volume the smallest CPU, memory and size Railway allows (`SMALLEST_LIMITS`, `SMALLEST_VOLUME`, section 5); go higher only when required (section 5a) | Leaving limits unset (the plan maximum), or sizing up "just in case" |

Why: one reviewed file is the source of truth (plan before apply, no drift); deploys happen only when we say so; the Dockerfile pins the exact image and version, and it runs the same locally; generic names survive switching Postgres versions or engines and keep variable references (`${{database.…}}`) stable across projects; small limits cap the bill and a runaway process, and volumes can be grown later but not shrunk.

## 2. Names

Name by what the service does for the app, lowercase kebab-case. A volume is `<service>-data`.

| Role | Service | Volume |
|---|---|---|
| Relational / document database | `database` | `database-data` |
| Cache / queue broker | `cache` | `cache-data` |
| Search | `search` | `search-data` |
| HTTP API | `api` | |
| Frontend | `web` | |
| Background jobs | `worker` | |
| Scheduled job | `cron` | |
| Object storage bucket | `storage` | |

When there are two of a role, add the role-level difference, not the tech: `database-analytics`, `worker-email`. The project name is the app's name (only the project, never repeated in service names). Environments are `production` and `staging`.

## 3. Layout

```
.railway/
  package.json               # the IaC SDK + plan/apply/deploy scripts (section 5)
  tsconfig.json
  railway.ts                 # entry: wires services together, lists every resource
  shared.ts                  # values used by more than one service (domains, origins, shared builders)
  services/
    api.ts                   # one file per service, named after the service
    database.ts              # a service and the volumes it owns live in the same file
infra/database/Dockerfile    # one folder per infrastructure service
infra/cache/Dockerfile
api/Dockerfile               # one folder per app service (or `.` if the repo is a single app)
```

`.railway/` is its own small Node package (Node 22+): the SDK is installed there, not at the repo root, so non-Node repos need no root `package.json`. Use the repo's package manager (`pnpm` if there's a `pnpm-lock.yaml`, etc.; default `pnpm`). Commit the lockfile; add `.railway/node_modules/` to `.gitignore`.

Pin exact versions (no `^`). Check the current ones with `npm view railway version` and `npm view typescript version`.

## 4. Setup flow

1. `railway whoami`. If not logged in, ask the user to run `! railway login`.
2. Link or create the project: `railway link` (existing) or `railway init --name <app>` (new). Never pick "deploy from GitHub".
3. If `railway.json` / `railway.toml` exists: `railway config migrate` (dry run), review, then `railway config migrate --apply --delete-files`. If the project already has services: `railway config pull`. Then split the generated file into the layout above and rename and convert services to these rules.
4. Otherwise write the files in section 5 and the Dockerfiles in section 6. (`railway config init` only creates a single-file starter; replace it.)
5. In `.railway/`: install, `pnpm typecheck`, `pnpm plan`, show the user the plan, then `pnpm apply`. Destructive changes (deletes, renames, which recreate the resource and lose volume data) need explicit user approval before `--confirm-destructive`.
6. Deploy each service with its `deploy:<service>` script (section 7).

## 5. `.railway/` files

Replace `<app>` with the app's name. Add a `deploy:<service>` script for every service; its path is the folder holding that service's Dockerfile.

`.railway/package.json`:

```json
{
  "name": "<app>-infra",
  "private": true,
  "type": "module",
  "scripts": {
    "typecheck": "tsc --noEmit -p .",
    "plan": "cd .. && railway config plan",
    "apply": "cd .. && railway config apply",
    "deploy:api": "cd .. && railway up api --path-as-root --service api --ci --message \"api $(git rev-parse --short HEAD)\"",
    "deploy:database": "cd .. && railway up infra/database --path-as-root --service database --ci --message \"database $(git rev-parse --short HEAD)\""
  },
  "devDependencies": {
    "railway": "3.16.0",
    "typescript": "5.9.3"
  }
}
```

`.railway/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "types": []
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules"]
}
```

`.railway/shared.ts`:

```ts
/** Values shared by every service definition. */

/**
 * Services have no GitHub source on purpose: deploys only happen from the CLI
 * (`pnpm deploy:<service>` in this folder, wrapping `railway up`).
 */
export const dockerfile = { builder: "DOCKERFILE", dockerfilePath: "Dockerfile" } as const;

/**
 * Smallest per-replica limits Railway accepts. Every service starts here.
 * Pass `limits(cpu, memoryMB)` instead only with a comment saying why the minimum is not enough.
 */
export const limits = (cpu: number, memoryMB: number) =>
  ({ limitOverride: { containers: { cpu, memoryBytes: memoryMB * 1_000_000 } } }) as const;
export const SMALLEST_LIMITS = limits(0.5, 500);

/** Smallest volume size. Volumes can grow later (online), never shrink. */
export const SMALLEST_VOLUME = { sizeMB: 500, allowOnlineResize: true } as const;

/** Public hostnames. */
export const WEB_ORIGIN = "https://example.com";
export const API_DOMAIN = "api.example.com";
```

`.railway/services/database.ts`:

```ts
import { empty, service, volume } from "railway/iac";
import { SMALLEST_LIMITS, SMALLEST_VOLUME, dockerfile } from "../shared";

/** Postgres built from infra/database/Dockerfile, data on the database-data volume. */
export function database() {
  const data = volume("database-data", SMALLEST_VOLUME);
  const db = service("database", {
    source: empty(),
    build: dockerfile,
    deploy: SMALLEST_LIMITS,
    volumeMounts: { "/var/lib/postgresql/data": data },
    env: {
      POSTGRES_USER: "app",
      POSTGRES_DB: "app",
      POSTGRES_PASSWORD: "${{secret(32)}}",
      PGDATA: "/var/lib/postgresql/data/pgdata", // subfolder: the volume root has lost+found
    },
  });
  return { db, data };
}
```

`.railway/services/api.ts`:

```ts
import { empty, service, type ResourceNode } from "railway/iac";
import { API_DOMAIN, SMALLEST_LIMITS, WEB_ORIGIN, dockerfile } from "../shared";

/** HTTP API built from api/Dockerfile. Takes the services it depends on. */
export function api(db: ResourceNode) {
  /** Railway reference to one of db's variables: ${{database.VAR}} */
  const dbVar = (name: string) => "${{" + db.name + "." + name + "}}";

  return service("api", {
    source: empty(),
    build: dockerfile,
    deploy: SMALLEST_LIMITS,
    healthcheck: "/health",
    domains: [API_DOMAIN],
    env: {
      CORS_ORIGIN: WEB_ORIGIN,
      DATABASE_URL: `postgresql://${dbVar("POSTGRES_USER")}:${dbVar("POSTGRES_PASSWORD")}@${dbVar("RAILWAY_PRIVATE_DOMAIN")}:5432/${dbVar("POSTGRES_DB")}`,
    },
  });
}
```

`.railway/railway.ts`:

```ts
import { defineRailway, group, project } from "railway/iac";
import { api } from "./services/api";
import { database } from "./services/database";

/**
 * <App>'s Railway infrastructure. Each service lives in its own file under ./services.
 *
 *   railway link                      # once, pick the project/environment
 *   pnpm plan                         # preview
 *   pnpm apply                        # apply settings (never deploys code)
 *   pnpm deploy:api                   # deploy code from this machine (railway up)
 *
 * Services are never connected to GitHub: every deploy is an explicit CLI upload.
 *
 * Every resource Railway should keep must be listed below: anything omitted is deleted on apply.
 */
export default defineRailway(() => {
  const { db, data } = database();
  const backend = api(db);

  return project("<app>", {
    environments: ["production"],
    resources: [group("Backend", [backend, db, data])],
  });
});
```

- One file per service in `services/`, named exactly like the service (`services/worker-email.ts` → `service("worker-email")`). Each exports a function that takes the nodes it depends on and returns its service, plus any volume it owns. `railway.ts` only wires and lists them; no service config there.
- Pass `ctx` (the `defineRailway` callback's argument) into a service function only when it varies by environment (`ctx.isEnvironment("production")`).
- `shared.ts` holds only what two or more services use. Something used by one service stays in its file.
- `source: empty()` on every service: no repo, no image. Code arrives only through `railway up`.
- Secrets: generate with `"${{secret(32)}}"` or set out of band with `railway variable set` and keep them in the file as `preserve()`. Never commit real secret values. Don't use `ctx.randomString()` for secrets: it is a deterministic hash.
- Wire services with Railway references (`${{database.VAR}}`, or `db.env.VAR` for a whole value) over the private network (`RAILWAY_PRIVATE_DOMAIN`). No public TCP proxy on a database unless the user asks.
- Group resources on the canvas with `group()` (e.g. `Backend`, `Workers`). Every service and volume must be in `resources`: omitting one deletes it on the next apply.

### 5a. Sizing

Every `service()` gets `deploy: SMALLEST_LIMITS` and every `volume()` gets `SMALLEST_VOLUME`. Unset limits default to the plan maximum, so always set them.

Go above the minimum only when there is a concrete reason, and write that reason in a comment next to the value:
- the image documents a higher floor, such as a search engine or JVM that needs at least 1-2 GB of heap;
- the service was OOM-killed or CPU-throttled at the current limit (check `railway logs` and the service metrics);
- the data, or its known growth, does not fit in the volume.

Raise in small steps (`limits(1, 1000)`, `sizeMB: 2000`), not to the plan maximum. When raising, set `deploy: limits(...)` in the service's own file, or set `{ ...SMALLEST_VOLUME, sizeMB: 2000 }` for a volume.

The `SMALLEST_*` values in `shared.ts` are the smallest values Railway is known to accept (Railway does not document a floor). If `pnpm plan` or `pnpm apply` rejects them, change only the constant, to the smallest value it accepts. Never shrink an existing volume below its current size: Railway can only grow volumes.

## 6. Dockerfiles

Pin the major version, never `latest`. Infrastructure Dockerfiles stay minimal; config lives in env vars.

```dockerfile
# infra/database/Dockerfile
FROM postgres:17-alpine
```

```dockerfile
# infra/cache/Dockerfile
FROM redis:7-alpine
CMD ["sh", "-c", "exec redis-server --requirepass \"$REDIS_PASSWORD\" --appendonly yes --dir /data"]
```

App Dockerfiles: multi-stage build, run as a non-root user, listen on `$PORT`, bind to `::` (Railway's private network is IPv6), add a `.dockerignore`.

## 7. Deploy

From `.railway/`: `pnpm deploy:<service>`. Each script runs `railway up <folder> --path-as-root --service <name> --ci` with the git short SHA as the message, so it streams the build and fails if the build fails. Add the script whenever you add a service.

After a deploy, check it is healthy: `railway deployment list --service <name> --json` and `railway logs --service <name> --lines 100`. Don't report success until a check passes. For another environment, add `--environment staging` (or a `deploy:<service>:staging` script).

For CI, use a `RAILWAY_TOKEN` project token and run the same scripts (`pnpm apply --yes`, `pnpm deploy:<service>`). Still no GitHub link.

## 8. Check before finishing

```bash
find . -name "railway.json" -o -name "railway.toml" | grep -v node_modules       # should be empty
grep -rnE "github\(|repo:|template\(|postgres\(|mysql\(|redis\(|mongo\(|[^a-z]database\(\"|NIXPACKS|RAILPACK" .railway --include=*.ts --exclude-dir=node_modules
grep -rn 'service("\|volume("' .railway/services                                   # names follow section 2, file name = service name
grep -rLE "SMALLEST_LIMITS|limits\(" .railway/services                              # should be empty: every service has limits
grep -rn 'volume("[^"]*")' .railway/services                                       # should be empty: every volume has a size
(cd .railway && pnpm typecheck)
(cd .railway && pnpm plan --detailed-exit-code)                                    # exit 0: no drift
```

Fix anything these find in the project you are working on.
