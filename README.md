# DevSecOps Homework (Hardened WordPress)

This repository contains a secure WordPress setup and automated security scanning tools.

## What's in here?

- **`Dockerfile`**: Builds a hardened WordPress container (hides versions, blocks user enumeration, secures headers).
- **`docker-compose.yml`**: Spins up the database and the hardened WordPress site.
- **`act.sh`**: A simple script to run GitHub Actions locally.
- **`scans/`**: Contains vulnerability scan results (vulnerable vs. patched).

## How to configure & run

1. **Set up the variables**
   Create a `.env` file in the main folder with these values:

   ```env
   MYSQL_ROOT_PASSWORD=password
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wp_user
   MYSQL_PASSWORD=password

   WORDPRESS_DB_HOST=wp-db:3306
   WORDPRESS_DB_USER=wp_user
   WORDPRESS_DB_PASSWORD=password
   WORDPRESS_DB_NAME=wordpress

   WP_ADMIN_USER=admin
   WP_ADMIN_PASSWORD=password
   WP_ADMIN_EMAIL=admin@example.com

   WPSCAN_SECRET=apitoken123
   ```

2. **Start the environment**
   Run the following command to build and start WordPress:

   ```bash
   docker compose --env-file .env up --build -d
   ```

   The site will be ready at `http://localhost:8080`.

(\*). **Run the local scan (Optional)**
Run `./act.sh` to test the GitHub Actions security scan locally. This will automatically run and stop the containers.

## How to stop

To shut everything down, run:

```bash
docker compose down
```
