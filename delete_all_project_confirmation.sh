#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <GENEZIO_TOKEN>"
    exit 1
fi

token=$1

response=$(curl -s -H "Authorization: Bearer $token" "https://api.genez.io/users/user")
email=$(echo "$response" | jq -r '.user.email')
subscription_plan=$(echo "$response" | jq -r '.user.subscriptionPlan')

echo "You are impersonating the account $email with the subscription plan $subscription_plan"

read -rp "Should we proceed? [y/N]: " confirm
confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

if [[ "$confirm" != "y" ]]; then
    echo "Aborting."
    exit 1
fi
echo "Proceeding with the deletion of all projects."

start_index=0
limit=100
# Make the API request to list projects
projects=$(curl -s -H "Authorization: Bearer $token" \
                  -H "Accept-Version: genezio-cli/3.0.7" \
                  "https://api.genez.io/projects?startIndex=$start_index&projectsLimit=$limit")

project_ids=($(echo "$projects" | jq -r '.projects[].id'))
project_names=($(echo "$projects" | jq -r '.projects[].name'))

for i in "${!project_ids[@]}"; do
    project_id="${project_ids[$i]}"
    project_name="${project_names[$i]}"

    read -rp "Do you want to delete project: $project_name (ID: $project_id)? [y/N]: " confirm
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

    if [[ "$confirm" == "y" ]]; then
        echo "Deleting $project_name..."
        # GENEZIO_TOKEN="$token" genezio delete --force "$project_id"
        echo "$project_name deleted successfully."
    else
        echo "Skipped deleting $project_name."
    fi
done
