#!/bin/bash

# This script deletes all projects in Genezio

projects=$(genezio list -l |  tr -d " \t," | grep "ID:" | cut -d ":" -f2)
projects_to_skip=("36b78717-d7cf-48b0-9b51-68d88ef4273d" "8d179259-fda1-4a15-a473-61fd9547777f" "21696c7c-c099-4098-8648-f731fcb7daf5")

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
