#!/bin/bash
echo "[INFO] [DynDNSCron] Regenerating ACL.."
source /generateACL.sh
echo "[INFO] [DynDNSCron] ACL regenerated!"
echo "[INFO] [DynDNSCron] Reloading DnsDist ACl config"
/usr/bin/dog @127.0.0.1:53 --short reload.acl.minidns.local
retVal=$?
if [ $retVal -eq 0 ]; then
  echo "[INFO] [DynDNSCron] DnsDist ACL config successfully reloaded!"
else
  echo "[ERROR] [DynDNSCron] Failed to reload DnsDist ACL config!"
fi
