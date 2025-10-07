#!/usr/bin/env bash

workload_name="s3bucket-redirection-service"
region=westeurope
environment="test"
tags="environment=$environment division=id subDivision=idci managedBy=azcli"

#repo_url="owner/repo"
repo_url=$(git remote -v | awk '/origin.*push/{gsub(/\.git$/, "", $2); print $2}')
branch="main"
app_location="/app"
api_location="api"
output_location=""
custom_url=""
static_web_app_sku="Free" # or "Standard"

### End of coniguration ###

resource_group_name=$(printf "rg-%s-%s" "$workload_name" "$environment")
static_web_app_name=$(printf "stapp-%s-%s" "$workload_name" "$environment")

if [[ "$1" == "-d" ]]; then
  echo "Cleaning up resources. This may take a few minutes."
  az group delete --name "$resource_group_name" | exit 1
  exit 0
fi

# Create resource group
if ! az group show --name "$resource_group_name" &>/dev/null; then
  az group create \
    --name "$resource_group_name" \
    --location "$region" \
    --tags $tags \
    --query "name" || exit 1
fi

# Create static web app
if ! az staticwebapp show -n "$static_web_app_name" -g "$resource_group_name" &>/dev/null; then
  az staticwebapp create \
    --name "$static_web_app_name" \
    --resource-group "$resource_group_name" \
    --location "$region" \
    --sku "$static_web_app_sku" \
    --source "$repo_url" \
    --branch "$branch" \
    --app-location "$app_location" \
    --api-location "$api_location" \
    --output-location "$output_location" \
    --login-with-github \
    --query "defaultHostname" || exit 1
fi

if [ ! -z "$custom_url" ]; then
  if ! az staticwebapp hostname show -n "$static_web_app_name" -g "$resource_group_name" \
    --hostname "$custom_url" &>/dev/null; then
    az staticwebapp hostname set \
      --name "$static_web_app_name" \
      --hostname "$custom_url" \
      --no-wait || exit 1
  else
    az staticwebapp hostname show \
      --name "$static_web_app_name" \
      --resource-group "$resource_group_name" \
      --hostname "$custom_url" \
      --query "{name:name,status:status}" || exit 1
  fi
fi

webapp_url=$(az staticwebapp show --name "$static_web_app_name" --resource-group "$resource_group_name" --query "defaultHostname" -o tsv)

runtime="+1M"
endtime=$(date -v${runtime} +%s)

while [[ $(date +%s) -le $endtime ]]; do
  if curl -I -s "$webapp_url" >/dev/null; then
    break
  else
    sleep 5
  fi
done

echo ""
echo "You can now visit your web app at https://$webapp_url"
[ ! -z "$custom_url" ] && echo "The web app is equally available at https://$custom_url"
echo
echo "The rendered page will be visible as soon as the workflow action has been run successfully."
echo "See $repo_url/actions"
