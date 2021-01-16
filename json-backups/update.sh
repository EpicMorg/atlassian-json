#!/bin/bash
export DOTNET_CLI_TELEMETRY_OPTOUT=true
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true

rm -rfv $PWD/current $PWD/archived $PWD/eap
mkdir -p $PWD/current $PWD/archived $PWD/eap

dotnet tool install -g dotnet-script

###################################################################################################
# Current links
###################################################################################################

# Bamboo
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/bamboo.json

# Bitbucket (Stash)
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/stash.json

# Confluence
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/confluence.json

# Crowd
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/crowd.json

# Crucible
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/crucible.json

# FishEye
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/fisheye.json

# Jira
#wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/jira.json
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/jira-core.json
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/jira-software.json
wget -c -nv --random-wait -P $PWD/current/ https://my.atlassian.com/download/feeds/current/jira-servicedesk.json

# SourceTree
echo "Generating sourcetree.json for current release"
echo "-----------------------------------------------"
dotnet script $PWD/sourcetreeapp.csx
echo "-----------------------------------------------"
touch $PWD/current/sourcetree.json
dotnet script $PWD/sourcetreeapp.csx > $PWD/current/sourcetree.json

###################################################################################################
# Archived links
###################################################################################################

# Bamboo
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/bamboo.json

# Bitbucket (Stash)
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/stash.json

# Confluence
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/confluence.json

# Crowd
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/crowd.json

# Crucible
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/crucible.json

# FishEye
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/fisheye.json

# Jira
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/jira.json
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/jira-core.json
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/jira-software.json
wget -c -nv --random-wait -P $PWD/archived/ https://my.atlassian.com/download/feeds/archived/jira-servicedesk.json

# SourceTree
echo "Generating sourcetree.json for arvhive release"
echo "-----------------------------------------------"
dotnet script $PWD/sourcetreeapp-archive.csx
echo "-----------------------------------------------"
touch $PWD/archived/sourcetree.json
dotnet script $PWD/sourcetreeapp-archive.csx > $PWD/archived/sourcetree.json

###################################################################################################
# EAP links
###################################################################################################
wget -c -nv --random-wait -P $PWD/eap/ https://my.atlassian.com/download/feeds/eap/bamboo.json
wget -c -nv --random-wait -P $PWD/eap/ https://my.atlassian.com/download/feeds/eap/confluence.json
wget -c -nv --random-wait -P $PWD/eap/ https://my.atlassian.com/download/feeds/eap/jira.json
wget -c -nv --random-wait -P $PWD/eap/ https://my.atlassian.com/download/feeds/eap/jira-servicedesk.json
wget -c -nv --random-wait -P $PWD/eap/ https://my.atlassian.com/download/feeds/eap/stash.json

