# Don't Starve Together Docker Server

This repo deploys a Don't Starve Together dedicated server using `jamesits/dst-server:nightly` as the runtime image. The DST dedicated server binaries are refreshed through SteamCMD into `server-bin/` before the container starts so the server matches current clients.

The server runs two shards:

- Master on UDP `10999`
- Caves on UDP `11000`

Server name:

- `meomeomeo`

Direct connect from the DST console:

```lua
c_connect("193.10.159.205", 10999)
```

Steam networking uses UDP `12346` and `12347`. The container runs with host networking so DST can also use its dynamic UDP ports directly. The server is configured for 12 players and enables these Steam Workshop mods:

- Global Positions (`378160973`)
- Finder (`780009141`)
- Wormhole Marks [DST] (`362175979`)
- Simple Health Bar DST (`1207269058`)
- Display Food Values (`347079953`)
- Display Attack Range (`2078243581`)

## Files

- `docker-compose.yml` starts the DST container with host networking and persists server data in `./data/DoNotStarveTogether`.
- `scripts/update-dst-server.sh` installs the current DST dedicated server into ignored local directory `server-bin/`.
- `scripts/entrypoint-no-steam-update.sh` skips the image's forced SteamCMD update step, which can fail with `App '343050' state is 0x6`, while still updating server mods and starting DST.
- `data/DoNotStarveTogether/Cluster_1` contains the checked-in cluster configuration.
- `scripts/deploy.sh` installs Docker on a blank Ubuntu server if needed, pulls the latest git changes, and restarts the container.
- `scripts/install-workshop-mods.sh` downloads configured Workshop mods with SteamCMD and links them into the active DST mods directory.
- `.env.example` shows the local environment variable used for a Klei cluster token.

## First deploy

From this folder:

```sh
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

The default deployment target is `ubuntu@193.10.159.205` and the server path is `/opt/dst-server`.

## Klei Cluster Token

Generate a token in the Don't Starve Together client:

1. Open the DST client.
2. Go to Account.
3. Open Games.
4. Open Don't Starve Together Servers.
5. Add a new server and copy the generated token.

This repo currently includes `data/DoNotStarveTogether/Cluster_1/cluster_token.txt`, because this deployment intentionally commits the token. If you rotate the token, update that file locally, commit, push, then deploy:

```sh
git add data/DoNotStarveTogether/Cluster_1/cluster_token.txt
git commit -m "Update DST cluster token"
git push origin main
./scripts/deploy.sh
```

You can also provide a token during deploy without editing the committed file:

```sh
DST_CLUSTER_TOKEN='PASTE_TOKEN_HERE' ./scripts/deploy.sh
```

## Change workflow

Every change should follow this order:

```sh
# edit locally
git add .
git commit -m "Describe the change"
git push origin main
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && git pull --ff-only && sudo docker pull jamesits/dst-server:nightly && sudo ./scripts/update-dst-server.sh && sudo ./scripts/install-workshop-mods.sh && sudo docker compose up -d --force-recreate'
```

This keeps GitHub, the local checkout, and the running server aligned.

For the common case, `./scripts/deploy.sh` performs the remote pull, DST binary update, and container recreate.

## Operations

Check status:

```sh
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && sudo docker compose ps'
```

Watch logs:

```sh
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && sudo docker compose logs -f --tail=200'
```

Restart cleanly:

```sh
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && sudo docker compose restart'
```

Stop the server:

```sh
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && sudo docker compose stop'
```

The compose file uses a six-minute stop grace period so DST has time to save worlds before the container exits.
