#!/bin/bash

LAN=192.168.1
args=( )

showhelp() {
cat <<EOF
$0 [--lan LAN ] PASSTHROUGH ARGS

DESCRIPTION
    Same as server.sh but intercepts args for generating IP address LAN
    certificates.  RFC1918 private IP is assumed with subnet mask
    255.255.255.0.

OPTIONS

  --lan LAN
    Where LAN is the first three octets of LAN network.

EOF
exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --lan)
      LAN="$2"
      shift
      shift
      ;;
    -h|--help)
      showhelp
      ;;
    *)
      args+=( "$1" )
      shift
  esac
done

if ! grep '^[0-9]\+\.[0-9]\+\.[0-9]\+$' <<< "${LAN:-}" &> /dev/null; then
  echo 'Not a valid LAN address' >&2
  echo 'Example: --lan 192.168.1' >&2
  exit 1
fi

lan_ips="${LAN}.1"
for x in $(seq 2 254); do
  lan_ips="${lan_ips} ${LAN}.${x}"
done

./server_cert.sh --ip-alts "${lan_ips}" "${args[@]}"
