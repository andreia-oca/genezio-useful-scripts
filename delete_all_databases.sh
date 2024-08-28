#!/bin/bash

GENEZIO_TOKEN=$(cat ~/.geneziorc)

dbIds=$(curl -H "Authorization: Bearer $GENEZIO_TOKEN" -H "Accept-Version: geneziocli/2.4.2" https://dev.api.genez.io/databases | jq '.databases[].id')

dbs_to_skip=()


for dbId in $dbIds; do
    clean_id=$(echo -n $dbId | tr -d '"')
    if [[ " ${dbs_to_skip[@]} " =~ " ${dbId} " ]]; then
        echo "Skipping database: $dbId"
        continue
    fi
    curl -X DELETE -H "Authorization: Bearer $GENEZIO_TOKEN" -H "Accept-Version: geneziocli/2.4.2" "https://dev.api.genez.io/databases/$clean_id"
    echo "Deleting database: $dbId"
done
