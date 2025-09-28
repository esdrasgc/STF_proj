# STF Scraper - EIP Rotation on 403 (AWS EC2)

This project can optionally rotate the EC2 instance public IPv4 (Elastic IP) when the target site responds with HTTP 403. This helps reduce long blocks by changing the outgoing IP, then briefly pausing the scraper before continuing.

The feature is disabled by default and is safe to enable only when running on AWS EC2 with an instance profile (IAM Role) that allows EIP management.

## How it works

- **Trigger**: When `coleta_processo.py` or `coleta_aba.py` encounters a 403 response.
- **Locking**: A Redis-based distributed lock prevents multiple workers rotating at once.
- **Rotation**:
  - Allocates a new Elastic IP in the VPC.
  - Associates it with the primary ENI's primary private IP (AllowReassociation=True).
  - Optionally releases the old Elastic IP if it was previously associated.
- **Cooldown**: A cooldown (default 300s) prevents excessive rotations.
- **Backoff**: After a successful rotation, a short global block is set so the workers pause before retrying.

Code lives in `aws_ip_rotator.py` and is invoked in the 403 handlers in `coleta_processo.py` and `coleta_aba.py`.

## Enable EIP rotation

Set the following environment variables (e.g. in `.env` or deployment env):

```env
# Enable/disable rotation
EIP_ROTATION_ENABLED=true

# Release the old EIP after successful reassociation (recommended to avoid leaks/costs)
EIP_RELEASE_OLD=true

# Cooldown between rotations (seconds)
EIP_ROTATION_COOLDOWN_SECS=300

# TTL for the rotation lock in Redis (seconds)
EIP_ROTATION_LOCK_TTL_SECS=300

# Optional: if not set, region is discovered via EC2 IMDSv2
# AWS_REGION=sa-east-1

# Redis (already used by the rate limiter)
# REDIS_HOST=redis
# REDIS_PORT=6379
# REDIS_DB=0
```

Ensure the application can read AWS credentials via the instance profile (IAM Role) attached to the EC2 instance. No static keys are needed if using IAM Roles.

## Required IAM permissions (instance role)

The instance profile must allow the following actions (scoped to your account/region):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeAddresses",
        "ec2:AllocateAddress",
        "ec2:AssociateAddress",
        "ec2:ReleaseAddress"
      ],
      "Resource": "*"
    }
  ]
}
```

Optionally restrict with condition keys like `ec2:Region` and account-scoped ARNs if you prefer tighter policies.

## Dependencies

- `boto3` has been added to `requirements.txt`.
- `aws_ip_rotator.py` will attempt to use IMDSv2 (`169.254.169.254`) to discover the instance id and region. Ensure your environment (host network and any containerized setup) allows access to the Instance Metadata Service.

## Operational notes

- **Costs**: Each Elastic IP allocated but not associated may incur costs. This code releases the previous EIP by default (`EIP_RELEASE_OLD=true`). If you set it to `false`, remember to periodically clean up unused EIPs.
- **Rate limiting**: Even after rotation, the scraper applies a short global block to avoid hammering the site.
- **Docker**: If running inside Docker on EC2, ensure the container can access IMDS and is using the instance role credentials (no static env keys required).

## Troubleshooting

- If rotation does nothing, check:
  - `EIP_ROTATION_ENABLED` is set to `true`.
  - The EC2 instance has a role with the required IAM permissions.
  - Security software/firewall does not block IMDS (169.254.169.254).
  - Redis is reachable for the rotation lock and last-rotation markers.
- Logs will include lines prefixed with `[EIP]` indicating rotation attempts and results.
