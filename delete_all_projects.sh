#!/bin/bash

# This script deletes all projects in Genezio

# Test of env variable $GENEZIO_TOKEN is set
if [ -z ${var+x} ]; then
    echo GENEZIO_TOKEN is set
else
    echo GENEZIO_TOKEN is not set. We are setting it for you
    export GENEZIO_TOKEN=$(cat ~/.geneziorc)
fi

projects=$(genezio ls -l |  tr -d " \t," | grep "ID:" | cut -d ":" -f2)

for project in $projects
do
    genezio delete --force $project
done
