import os
import time
import json
import logging
import uuid
from typing import Optional, Dict, Any

import boto3
import requests
from botocore.config import Config as BotoConfig

from rate_limiter import rate_limiter

logger = logging.getLogger(__name__)

# Env flags
EIP_ROTATION_ENABLED = os.getenv("EIP_ROTATION_ENABLED", "false").lower() in ("1", "true", "yes")
EIP_RELEASE_OLD = os.getenv("EIP_RELEASE_OLD", "true").lower() in ("1", "true", "yes")
EIP_ROTATION_COOLDOWN_SECS = int(os.getenv("EIP_ROTATION_COOLDOWN_SECS", "300"))
AWS_REGION_ENV = os.getenv("AWS_REGION")

# Redis keys
LOCK_KEY = "stf:eip_rotation_lock"
LOCK_TTL_SECS = int(os.getenv("EIP_ROTATION_LOCK_TTL_SECS", "300"))
LAST_ROTATION_KEY = "stf:last_eip_rotation"

# IMDSv2 endpoints
IMDS_BASE = "http://169.254.169.254/latest"
IMDS_TOKEN_URL = f"{IMDS_BASE}/api/token"
IMDS_INSTANCE_ID_URL = f"{IMDS_BASE}/meta-data/instance-id"
IMDS_IID_DOC_URL = f"{IMDS_BASE}/dynamic/instance-identity/document"


class _RedisLock:
    def __init__(self, client, key: str, ttl: int):
        self.client = client
        self.key = key
        self.ttl = ttl
        self.token = str(uuid.uuid4())
        self.acquired = False

    def acquire(self) -> bool:
        if not self.client:
            return True  # if no redis, behave as if lock acquired to proceed best-effort
        try:
            ok = self.client.set(self.key, self.token, nx=True, ex=self.ttl)
            self.acquired = bool(ok)
            return self.acquired
        except Exception as e:
            logger.warning(f"[EIP] Failed to acquire redis lock: {e}")
            return False

    def release(self):
        if not self.client:
            return
        if not self.acquired:
            return
        # Safe release: only delete if token matches
        try:
            val = self.client.get(self.key)
            if val == self.token:
                self.client.delete(self.key)
        except Exception:
            pass


def _get_imds_token() -> Optional[str]:
    try:
        r = requests.put(IMDS_TOKEN_URL, headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"}, timeout=2)
        if r.status_code == 200:
            return r.text
    except Exception:
        pass
    return None


def _imds_get(url: str, token: Optional[str]) -> Optional[str]:
    headers = {"X-aws-ec2-metadata-token": token} if token else {}
    try:
        r = requests.get(url, headers=headers, timeout=2)
        if r.status_code == 200:
            return r.text
    except Exception:
        pass
    return None


def _get_instance_identity() -> Dict[str, str]:
    token = _get_imds_token()
    instance_id = _imds_get(IMDS_INSTANCE_ID_URL, token)
    region = AWS_REGION_ENV
    if not region:
        doc_txt = _imds_get(IMDS_IID_DOC_URL, token)
        if doc_txt:
            try:
                doc = json.loads(doc_txt)
                region = doc.get("region")
            except Exception:
                pass
    return {"instance_id": instance_id, "region": region}


def _get_ec2_client(region: str):
    return boto3.client(
        "ec2",
        region_name=region,
        config=BotoConfig(retries={"max_attempts": 5, "mode": "standard"}),
    )


def _get_primary_eni_and_private_ip(ec2, instance_id: str) -> Optional[Dict[str, str]]:
    resp = ec2.describe_instances(InstanceIds=[instance_id])
    reservations = resp.get("Reservations", [])
    if not reservations:
        return None
    instance = reservations[0]["Instances"][0]
    nis = instance.get("NetworkInterfaces", [])
    # Pick device index 0
    primary = None
    for ni in nis:
        att = ni.get("Attachment", {})
        if att.get("DeviceIndex") == 0:
            primary = ni
            break
    if not primary:
        return None
    eni_id = primary["NetworkInterfaceId"]
    # Find primary private ip
    priv_ip = None
    for pip in primary.get("PrivateIpAddresses", []):
        if pip.get("Primary"):
            priv_ip = pip.get("PrivateIpAddress")
            break
    if not priv_ip and primary.get("PrivateIpAddress"):
        priv_ip = primary.get("PrivateIpAddress")
    return {"eni_id": eni_id, "private_ip": priv_ip}


def _get_current_eip_allocation(ec2, eni_id: str, private_ip: str) -> Optional[str]:
    # Return AllocationId of EIP currently associated to this ENI+private IP, if any
    resp = ec2.describe_addresses(
        Filters=[
            {"Name": "network-interface-id", "Values": [eni_id]},
            {"Name": "private-ip-address", "Values": [private_ip]},
        ]
    )
    addrs = resp.get("Addresses", [])
    if not addrs:
        return None
    return addrs[0].get("AllocationId")


def rotate_eip_if_possible(reason: str = "", min_block_secs_on_success: int = 60) -> Dict[str, Any]:
    """
    Attempt to rotate the instance public IPv4 by allocating a new Elastic IP and
    associating it to the primary ENI. Optionally release the old EIP if it was
    previously associated.

    Returns a dict with keys: rotated(bool), new_allocation_id, new_public_ip, old_allocation_id, message
    """
    if not EIP_ROTATION_ENABLED:
        return {"rotated": False, "message": "EIP rotation disabled"}

    client = getattr(rate_limiter, "redis_client", None)
    lock = _RedisLock(client, LOCK_KEY, LOCK_TTL_SECS)

    # Enforce a cooldown to avoid aggressive rotations
    try:
        if client:
            last = client.get(LAST_ROTATION_KEY)
            if last:
                try:
                    last_ts = float(last)
                    if time.time() - last_ts < EIP_ROTATION_COOLDOWN_SECS:
                        return {"rotated": False, "message": "Cooldown active"}
                except Exception:
                    pass
    except Exception:
        pass

    if not lock.acquire():
        return {"rotated": False, "message": "Another rotation in progress"}

    try:
        ident = _get_instance_identity()
        instance_id = ident.get("instance_id")
        region = ident.get("region")
        if not instance_id or not region:
            return {"rotated": False, "message": "Not running on EC2 or region missing"}

        ec2 = _get_ec2_client(region)
        eni_info = _get_primary_eni_and_private_ip(ec2, instance_id)
        if not eni_info:
            return {"rotated": False, "message": "Primary ENI not found"}
        eni_id = eni_info["eni_id"]
        private_ip = eni_info["private_ip"]

        old_alloc = _get_current_eip_allocation(ec2, eni_id, private_ip)

        # Allocate new EIP in VPC
        alloc = ec2.allocate_address(Domain="vpc")
        new_alloc_id = alloc["AllocationId"]
        new_public_ip = alloc.get("PublicIp")

        # Associate to ENI primary private IP, allowing reassociation
        ec2.associate_address(
            AllocationId=new_alloc_id,
            NetworkInterfaceId=eni_id,
            PrivateIpAddress=private_ip,
            AllowReassociation=True,
        )

        # Optionally release old EIP if there was one
        if old_alloc and EIP_RELEASE_OLD and old_alloc != new_alloc_id:
            try:
                ec2.release_address(AllocationId=old_alloc)
            except Exception as ex:
                logger.warning(f"[EIP] Failed to release old EIP {old_alloc}: {ex}")

        # Persist last rotation time
        try:
            if client:
                client.set(LAST_ROTATION_KEY, str(time.time()), ex=EIP_ROTATION_COOLDOWN_SECS)
        except Exception:
            pass

        msg = f"Rotated EIP to {new_public_ip} (alloc {new_alloc_id}) reason='{reason}'"
        logger.warning(f"[EIP] {msg}")
        return {
            "rotated": True,
            "new_allocation_id": new_alloc_id,
            "new_public_ip": new_public_ip,
            "old_allocation_id": old_alloc,
            "message": msg,
            "min_block_secs": int(min_block_secs_on_success),
        }
    except Exception as e:
        logger.error(f"[EIP] Rotation failed: {e}")
        return {"rotated": False, "message": str(e)}
    finally:
        lock.release()
