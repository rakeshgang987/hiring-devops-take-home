# How I Used AI

## Tools used
- ChatGPT for troubleshooting guidance, configuration review, shell-script improvements and documentation drafting.
- Docker Compose, Nginx, Redis CLI, PHP-FPM checks, curl, shell syntax validation and Git for hands-on verification.

## How I used them
- Asked for help investigating configuration mismatches and likely service failures.
- Reviewed suggested changes and applied them to the repository.
- Ran configuration checks and tested the SaaS endpoint.
- Improved backup-script error handling and made credentials configurable through environment variables.
- Drafted incident notes while distinguishing confirmed fixes from risks needing further investigation.

## Key prompts
1. Help investigate the WordPress HTTP 502 using Nginx FastCGI and PHP-FPM listener configuration.
2. Review Redis memory settings and eviction policy.
3. Compare SaaS application ports with the Nginx upstream.
4. Improve backup-script error handling and credential configuration.
5. Document incident findings, prevention steps and unresolved risks.

## When the AI was wrong or risky
The initial FastCGI-port fix addressed a real configuration mismatch. I then checked the effective Nginx configuration and PHP-FPM listener settings, and verified the recovery end to end: the WordPress HTTPS endpoint returned HTTP 200 and served the expected page. I updated the incident report to distinguish this verified fix from other potential risks that still need further investigation.

Some settings, such as the PHP memory limit and database buffer pool, indicate potential risks but do not independently prove a production incident. I documented these as items requiring evidence rather than confirmed root causes with completed fixes.

## What I'd never let an AI do unchecked on a production server
- Run destructive commands, delete volumes or backups, or restart critical services without impact review and approval.
- Change firewall rules, IAM permissions, credentials or databases without verifying access requirements and rollback options.
- Declare an incident resolved based only on syntax checks without verifying service health and user-facing behavior.
