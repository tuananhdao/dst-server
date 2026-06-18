# Don't Starve Together Docker Server

This repo deploys a Don't Starve Together dedicated server using `jamesits/dst-server:latest` and Docker Compose.

The server runs two shards:

- Master on UDP `10999`
- Caves on UDP `11000`

Steam networking uses UDP `12346` and `12347`. The Global Positions server mod is enabled with Steam Workshop ID `378160973`.

## Files

- `docker-compose.yml` starts the DST container and persists server data in `./data/DoNotStarveTogether`.
- `data/DoNotStarveTogether/Cluster_1` contains the checked-in cluster configuration.
- `scripts/deploy.sh` installs Docker on a blank Ubuntu server if needed, pulls the latest git changes, and restarts the container.
- `.env.example` shows the local environment variable used for a Klei cluster token.

## First deploy

From this folder:

```sh
chmod +x scripts/deploy.sh
git add .
git commit -m "Set up DST Docker server"
git push origin main
./scripts/deploy.sh
```

The default deployment target is `ubuntu@193.10.159.205` and the server path is `/opt/dst-server`.

## Add the Klei Cluster Token

Generate a token in the Don't Starve Together client:

1. Open the DST client.
2. Go to Account.
3. Open Games.
4. Open Don't Starve Together Servers.
5. Add a new server and copy the generated token.

Then write it on the server:

```sh
ssh ubuntu@193.10.159.205
cd /opt/dst-server
printf '%s\n' 'PASTE_TOKEN_HERE' > data/DoNotStarveTogether/Cluster_1/cluster_token.txt
docker compose restart
```

Do not commit a real cluster token.

You can also provide the token during deploy:

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
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && git pull --ff-only && docker compose pull && docker compose up -d'
```

This keeps GitHub, the local checkout, and the running server aligned.

## Operations

Check status:

```sh
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && docker compose ps'
```

Watch logs:

```sh
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && docker compose logs -f --tail=200'
```

Restart cleanly:

```sh
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && docker compose restart'
```

Stop the server:

```sh
ssh ubuntu@193.10.159.205 'cd /opt/dst-server && docker compose stop'
```

The compose file uses a six-minute stop grace period so DST has time to save worlds before the container exits.
