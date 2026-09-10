#!/usr/bin/env bash
#
# Refreshes the mirrored Atlassian download feeds.
#
# Every file is fetched to a temporary path, checked for being valid JSON, and only then
# moved into place. Nothing is deleted up front. That matters: the previous version began with
# "rm -rf current archived eap" and wrote each file with a plain redirect, so any failed fetch left
# either an empty file or no file at all, and the commit step pushed that loss without anyone
# noticing. sourcetree.json sat at 0 bytes and the archived one at "downloads([])" for exactly this
# reason.
#
# A failing feed no longer takes the others down with it. The script keeps going, leaves the last
# good copy of whatever failed untouched, and exits non-zero at the end so the run shows red while
# the feeds that did update still get committed.

set -euo pipefail

export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

readonly FEED_BASE="https://my.atlassian.com/download/feeds"
readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Legacy "jira" is archived and EAP only; it has had no current release since the 2015 split into
# Jira Core, Jira Software and Jira Service Desk.
readonly CURRENT_FEEDS=(bamboo stash mesh clover confluence crowd crucible fisheye
                        jira-core jira-software jira-servicedesk)
readonly ARCHIVED_FEEDS=(bamboo stash mesh clover confluence crowd crucible fisheye
                         jira jira-core jira-software jira-servicedesk)
readonly EAP_FEEDS=(bamboo confluence jira jira-servicedesk stash)

failures=()

log() { printf '%s\n' "$*"; }

# Replaces "$2" with "$1" only if it holds valid JSON.
#
# The fourth argument says whether an empty list is acceptable. It is for the feeds, where "[]"
# simply means there is no build in that channel right now, as eap/stash and eap/jira-servicedesk
# both return today. It is not for the scraped SourceTree pages, where an empty result means the
# page changed and the scraper found nothing, which is the failure this rewrite exists to catch.
install_if_valid() {
    local staged="$1" target="$2" label="$3" allow_empty="$4"

    if [ ! -s "$staged" ]; then
        log "  FAILED $label: empty response"
        failures+=("$label")
        rm -f "$staged"
        return
    fi

    if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$staged" 2>/dev/null; then
        log "  FAILED $label: not valid JSON"
        failures+=("$label")
        rm -f "$staged"
        return
    fi

    if [ "$allow_empty" != "allow-empty" ] \
       && ! python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1])) else 1)' "$staged"; then
        log "  FAILED $label: parsed but held no entries"
        failures+=("$label")
        rm -f "$staged"
        return
    fi

    mv -f "$staged" "$target"
    log "  ok $label ($(wc -c <"$target") bytes)"
}

fetch_feed() {
    local channel="$1" product="$2"
    local target="$ROOT/$channel/$product.json"
    local staged="$target.tmp"

    if ! curl --silent --show-error --fail --location --max-time 120 \
              --retry 3 --retry-delay 5 \
              --output "$staged" "$FEED_BASE/$channel/$product.json"; then
        log "  FAILED $channel/$product: download error"
        failures+=("$channel/$product")
        rm -f "$staged"
        return
    fi

    install_if_valid "$staged" "$target" "$channel/$product" allow-empty
}

# SourceTree has no feed of its own, so these two scripts read the product pages instead.
generate_sourcetree() {
    local channel="$1" script="$2"
    local target="$ROOT/$channel/sourcetree.json"
    local staged="$target.tmp"

    if ! dotnet script "$ROOT/$script" >"$staged"; then
        log "  FAILED $channel/sourcetree: $script exited non-zero"
        failures+=("$channel/sourcetree")
        rm -f "$staged"
        return
    fi

    install_if_valid "$staged" "$target" "$channel/sourcetree" require-entries
}

mkdir -p "$ROOT/current" "$ROOT/archived" "$ROOT/eap"

if ! command -v dotnet-script >/dev/null 2>&1; then
    log "Installing dotnet-script"
    dotnet tool install -g dotnet-script
    export PATH="$PATH:$HOME/.dotnet/tools"
fi

log "Current feeds"
for product in "${CURRENT_FEEDS[@]}"; do fetch_feed current "$product"; done
generate_sourcetree current sourcetreeapp.csx

log "Archived feeds"
for product in "${ARCHIVED_FEEDS[@]}"; do fetch_feed archived "$product"; done
generate_sourcetree archived sourcetreeapp-archive.csx

log "EAP feeds"
for product in "${EAP_FEEDS[@]}"; do fetch_feed eap "$product"; done

if [ ${#failures[@]} -gt 0 ]; then
    log ""
    log "${#failures[@]} feed(s) failed and kept their previous contents:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi

log ""
log "All feeds updated."
