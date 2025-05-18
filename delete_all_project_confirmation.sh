#!/bin/bash

if [ -z "$2" ]; then
    echo "Usage: $0 <ENVIRONMENT> <GENEZIO_TOKEN>"
    exit 1
fi

environment=$1
token=$2

if [[ "$environment" == "dev" ]]; then
    BACKEND_URL="https://dev.api.genez.io"
elif [[ "$environment" == "prod" ]]; then
    BACKEND_URL="https://api.genez.io"
else
    echo "Invalid environment. Use 'dev' or 'prod'."
    exit 1
fi

response=$(curl -s -H "Authorization: Bearer $token" "$BACKEND_URL/users/user")
email=$(echo "$response" | jq -r '.user.email')
subscription_plan=$(echo "$response" | jq -r '.user.subscriptionPlan')

echo "You are impersonating the account $email with the subscription plan $subscription_plan"

read -rp "Should we proceed? [y/N]: " confirm
confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

if [[ "$confirm" != "y" ]]; then
    echo "Aborting."
    exit 1
fi
echo "Proceeding with the deletion..."

start_index=0
limit=100
# Make the API request to list projects
projects=$(curl -s -H "Authorization: Bearer $token" \
                  -H "Accept-Version: genezio-cli/3.0.7" \
                  "$BACKEND_URL/projects?startIndex=$start_index&projectsLimit=$limit")

project_ids=($(echo "$projects" | jq -r '.projects[].id'))
project_names=($(echo "$projects" | jq -r '.projects[].name'))

for i in "${!project_ids[@]}"; do
    project_id="${project_ids[$i]}"
    project_name="${project_names[$i]}"

    read -rp "Do you want to delete project: $project_name (ID: $project_id)? [y/N]: " confirm
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

    if [[ "$confirm" == "y" ]]; then
        echo "Deleting $project_name..."
        GENEZIO_TOKEN="$token" genezio delete --force "$project_id" > /dev/null
        echo "$project_name deleted successfully."
    else
        echo "Skipped deleting $project_name."
    fi
done
