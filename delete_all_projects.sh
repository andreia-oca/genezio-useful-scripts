#!/bin/bash

# This script deletes all projects in Genezio for the authenticated user

projects=$(genezio list -l |  tr -d " \t," | grep "ID:" | cut -d ":" -f2)
projects_to_skip=("")

counter=0
skip_count=0

for project in $projects
do
    if [[ " ${projects_to_skip[@]} " =~ " ${project} " ]]; then
        echo "Skipping project: $project"
        continue
    fi
    if [ $counter -ge $skip_count ]; then
        echo "Deleting project: $project"
        genezio delete --force "$project"
    fi

    ((counter++))
done
