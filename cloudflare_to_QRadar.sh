#!/bin/bash

# Get the current date and time
#current_date_time=$(date +"%Y-%m-%dT%H:%M:%SZ")
#Linux
current_date_time=$(date -d '3 hour ago' +"%Y-%m-%dT%H:%M:%SZ")
#MacOS
#current_date_time=$(date -v-180M "+%Y-%m-%dT%H:%M:%SZ")
echo "$current_date_time"
# Get the date and time before 1 hour
#Linux
one_hour_ago=$(date -d '4 hour ago' +"%Y-%m-%dT%H:%M:%SZ")
#MacOS
#one_hour_ago=$(date -v-240M "+%Y-%m-%dT%H:%M:%SZ")
echo "$one_hour_ago"

QUERY=$(echo '{ "query":
  "query ListFirewallEvents($zoneTag: string, $filter: FirewallEventsAdaptiveFilter_InputObject) {
    viewer {
      zones(filter: { zoneTag: $zoneTag }) {
        firewallEventsAdaptive(
          filter: $filter
          limit: 10
          orderBy: [datetime_DESC]
        ) {
          action
          rayName
          ref
          ruleId
          clientAsn
          clientCountryName
          clientIP
          clientRequestPath
          clientRequestQuery
          datetime
          source
          userAgent
        }
      }
    }
  }",
  "variables": {
    "zoneTag": "ENTER_YOUR_ZONE_TAG",
    "filter": {
      "datetime_geq": "'"$one_hour_ago"'",
      "datetime_leq": "'"$current_date_time"'"
    }
  }
}' | tr -d '\n')

response=$(curl -s -X POST https://api.cloudflare.com/client/v4/graphql \
-H "Content-Type: application/json" \
-H "X-Auth-Email: ENTER_YOUR_X-Auth-Email" \
-H "X-Auth-Key: ENTER_YOUR_X-Auth-Key" \
-d "$QUERY")


# Send to QRadar
echo "$response"|jq -r '.data.viewer.zones[].firewallEventsAdaptive[] | tojson' | while read -r repo; do curl -k -X POST http://<YOUR_QRADAR_IP>:12469 -H 'Content-Type: application/json' -H "X-Auth-Email: <X-Auth-Email>" -H "X-Auth-Key: <X-Auth-Key>" -d "$repo"; done

# Send to Arcsight
echo "$response"|jq -r '.data.viewer.zones[].firewallEventsAdaptive[] | tojson' | while read -r repo; do logger -n <YOUR_ARCSIGHT_IP> -t cloudflare_waf "CEF:0|MyCompany|CloudflareWAF|1.0|1001|Cloudflare WAF event|5|src=<MANDATORY_ATTACKER_ADDRESS> msg=$repo"; done
