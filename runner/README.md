### Docker compose command to start github runner
```bash
docker compose -f runner/runner-compose.yml --env-file runner/.env.runner up -d --build
```
