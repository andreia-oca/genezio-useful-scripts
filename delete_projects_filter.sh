#!/bin/bash

# This script deletes projects based on a `filter_string`.

# Get the list of project IDs and names
projects=$(genezio list -l | tr -d " \t," | grep "ID:" | cut -d ":" -f2)
projects_name=$(genezio list -l | tr -d " \t," | grep Projectname: | cut -d ":" -f3)

# Convert projects and projects_name to arrays
projects_array=($projects)
projects_name_array=($projects_name)

# TODO Specify the string to filter projects by
filter_string="getting-started"

# Iterate through the arrays
for i in "${!projects_array[@]}"; do
    project=${projects_array[$i]}
    project_name=${projects_name_array[$i]}

    # Check if the project name starts with the filter string
    if [[ $project_name == $filter_string* ]]; then
        echo "Deleting project: $project_name (ID: $project)"
        genezio delete --force "$project"
    fi
done
