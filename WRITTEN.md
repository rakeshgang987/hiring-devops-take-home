# Written Responses

## 1. Least-Privilege IAM Policy for Backups

The backup process needs permission to upload objects only within the designated prefix. The following policy grants `s3:PutObject` and does not grant listing, reading, or deleting objects.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UploadBackupsOnly",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::bsf-backups/site-x/*"
    }
  ]
}
```

Attach this policy to a dedicated IAM role or user used only by the backup process. On EC2, prefer an instance profile with temporary role credentials. On a VPS outside AWS, use securely stored credentials or a supported federation mechanism, rotate credentials, and never commit secrets to source control. If server-side encryption uses a customer-managed KMS key, grant only the additional KMS permissions actually required. Bucket policies and organizational controls may further restrict access.

## 2. Troubleshooting Cloudflare Error 525

Error 525 indicates that Cloudflare could not complete the TLS handshake with the origin server. I would investigate in this order:

1. Confirm the origin server is reachable and listening on the expected HTTPS port, usually 443.
2. Check the web server's TLS listener and inspect Nginx or Apache configuration.
3. Validate the origin certificate's validity period, hostname/SAN, certificate chain, and private-key pairing.
4. Check TLS protocol and cipher compatibility, SNI configuration, and the virtual host selected for the requested hostname.
5. Review origin firewall rules and security groups to ensure legitimate Cloudflare connections are permitted.
6. Inspect web-server and TLS error logs while reproducing the request. Test the origin directly with the correct hostname and SNI, for example:

   `openssl s_client -connect ORIGIN_IP:443 -servername example.com -showcerts`

7. After fixing the underlying problem, verify the origin certificate and retry through Cloudflare using Full (strict) mode.

I would not permanently disable certificate validation or leave the site on an insecure SSL mode as a workaround.

## 3. Amazon SES Emails Landing in Spam

I would verify authentication, alignment, and sending reputation:

1. **SPF:** Publish the SPF record specified by the email provider for the sending domain or custom MAIL FROM domain. Ensure there is only one SPF record per hostname and avoid exceeding DNS lookup limits.
2. **DKIM:** Enable Easy DKIM in SES and publish the exact CNAME records SES supplies. Confirm the domain reports DKIM as verified.
3. **DMARC:** Publish a TXT record at `_dmarc.example.com`. Start with monitoring (`p=none`), review aggregate reports and alignment, then move toward `quarantine` or `reject` once legitimate senders are accounted for.
4. **MAIL FROM:** If using a custom MAIL FROM domain, configure the SES-provided MX and SPF records correctly.
5. **Reputation:** Review SES bounce and complaint rates, account reputation, suppression-list events, sending quotas, and message rejection logs. Remove invalid addresses and honor unsubscribes.
6. **Message quality:** Send only to opted-in recipients, use accurate subjects and clear unsubscribe options where applicable, and inspect message headers and authentication results.

I would test delivery to multiple mailbox providers and inspect the received headers rather than assuming that publishing DNS records alone guarantees inbox placement.

## 4. First 10 Minutes of a cPanel Server at 100% CPU

My priority is to identify the process and preserve evidence before making changes.

### Minutes 0–2: Establish the current state

Run:

```bash
date
uptime
top -c
free -h
vmstat 1 5
ps -eo pid,ppid,user,%cpu,%mem,etime,cmd --sort=-%cpu | head -25
```

Check load average, CPU saturation, memory pressure, swap activity, and the processes consuming the most CPU. Determine whether the issue is sustained or a short spike.

### Minutes 2–5: Attribute the workload

```bash
ps -eo user,pid,%cpu,%mem,cmd --sort=-%cpu | head -25
```

Identify whether the load comes from PHP-FPM, Apache, MySQL/MariaDB, a scheduled job, backups, or an unexpected process. On cPanel, correlate process owners with hosting accounts. Inspect available Apache/Nginx access and error logs, PHP-FPM logs, and database slow-query logs for request patterns, repeated errors, or a single abusive endpoint.

### Minutes 5–8: Find the cause

- Check access logs for unusually frequent requests, expensive URLs, and concentrated source IPs.
- Inspect MySQL/MariaDB process activity and slow queries if database load is high.
- Check cron jobs, backup tasks, imports, and recent deployments.
- Look for suspicious processes, unexpected files, or signs of compromised accounts without deleting evidence.
- Compare current usage with monitoring history and recent traffic changes.

### Minutes 8–10: Apply a narrow mitigation and verify

Choose a mitigation based on evidence: rate-limit abusive traffic, disable a clearly identified runaway scheduled task with approval, pause a resource-intensive backup, or roll back a confirmed problematic deployment. Coordinate with the affected account owner when appropriate.

Recheck `top`, `uptime`, service health, and logs to confirm whether CPU usage and customer impact have improved. Record the timeline, findings, commands, and actions taken. Avoid blindly killing processes or rebooting the server before identifying the workload; escalate if the cause remains unclear or compromise is suspected.
