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
    USERNAME="your-username"
fi

# Get the current date and calculate the date from one week ago
# WARNING: This works on macOS, for Linux use `date -d` instead of `date -v`
ONE_WEEK_AGO=$(date -v-14d +"%Y-%m-%dT%H:%M:%SZ")

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
  echo "$repos" | jq -r --arg ONE_WEEK_AGO "$ONE_WEEK_AGO" '.[] | select(.created_at > $ONE_WEEK_AGO) | .name'
}

# Fetch repositories created in the last week
recent_repos=$(get_recent_repos)

if [ -z "$recent_repos" ]; then
  echo "No repositories created in the last week."
  exit 0
fi

# Iterate over each repository and ask for confirmation before deleting
for REPO in $recent_repos; do
  confirm_delete "$REPO"
done
