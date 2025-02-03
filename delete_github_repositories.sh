#!/bin/bash

# Run this as GITHUB_TOKEN=your_token_here GITHUB_USERNAME=your_username ./delete_github_repositories.sh
# Generate a classic PAT token from https://github.com/settings/tokens
# The following permissions are required:
# - repo
# - delete_repo
# - admin:org

# Retrieve GitHub personal access token from environment variable
TOKEN="${GITHUB_TOKEN}"

# Check if the token is set
if [ -z "$TOKEN" ]; then
  echo "Error: GitHub token is not set. Please set the GITHUB_TOKEN environment variable."
  exit 1
fi

# GitHub username
USERNAME="${GITHUB_USERNAME}"

if [ -z "$USERNAME" ]; then
    USERNAME="andreia-oca"
fi

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <DAYS_AGO>"
    exit 1
fi

DAYS_AGO="$1"

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DATE_CMD="date -v-${DAYS_AGO}d +\"%Y-%m-%dT%H:%M:%SZ\""
else
    # Linux
    DATE_CMD="date -d \"${DAYS_AGO} days ago\" +\"%Y-%m-%dT%H:%M:%SZ\""
fi


DAYS_AGO_TIMESTAMP=$(eval $DATE_CMD)

if [[ "$DAYS_AGO" -eq 1 ]]; then
    HUMAN_READABLE_DATE="1 day ago"
else
    HUMAN_READABLE_DATE="$DAYS_AGO days ago"
fi

echo "Fetching repositories created after: $DAYS_AGO_TIMESTAMP"

# Function to delete a GitHub repository
delete_repo() {
  REPO_NAME=$1
  echo "Deleting repository: $REPO_NAME"

  # GitHub API URL for deleting the repository
  URL="https://api.github.com/repos/$USERNAME/$REPO_NAME"

  # Delete the repository using curl
  response=$(curl -s -o /dev/null -w "%{http_code}" -L \
    -X DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    $URL)

  # Check if the deletion was successful
  if [ $response -eq 204 ]; then
    echo "Repository $REPO_NAME deleted successfully."
  else
    echo "Failed to delete repository $REPO_NAME. HTTP Status Code: $response"
  fi
}

# Function to confirm deletion
confirm_delete() {
  REPO_NAME=$1
  read -p "Do you want to delete the repository '$REPO_NAME'? (y/n): " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    delete_repo "$REPO_NAME"
    # echo "Dry run: Repository $REPO_NAME would be deleted."
  else
    echo "Skipped deleting repository: $REPO_NAME"
  fi
}


# Function to fetch repositories created in the last week
get_recent_repos() {
  # GitHub API URL to list repositories, including private ones
  URL="https://api.github.com/user/repos?per_page=100&affiliation=owner"

  # Get the repository list
  repos=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    $URL)

  # Filter repositories created in the last week
  echo "$repos" | jq -r --arg DAYS_AGO_TIMESTAMP "$DAYS_AGO_TIMESTAMP" '.[] | select(.created_at > $DAYS_AGO_TIMESTAMP) | .name'
}

# Fetch repositories created in the last week
recent_repos=$(get_recent_repos)

if [ -z "$recent_repos" ]; then
  echo "No repositories found created since $HUMAN_READABLE_DATE."
  exit 0
fi

# Iterate over each repository and ask for confirmation before deleting
for REPO in $recent_repos; do
  confirm_delete "$REPO"
done
