#!/bin/bash

# This script deletes all projects in Genezio

projects=$(genezio list -l |  tr -d " \t," | grep "ID:" | cut -d ":" -f2)
projects_to_skip=("id_1" "id_2")

counter=0
skip_count=1

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
