#!/bin/bash

bash ./001_cisco-catalyst-sd-wan-manager-pipeline_en.sh
bash ./001_keycloak-pipeline_en.sh
bash ./001_mongodb-pipeline_en.sh
bash ./001_openssl-pipeline_en.sh
bash ./001_react-pipeline_en.sh
bash ./001_sample-product-pipeline_de.sh
bash ./001_sample-product-pipeline_en.sh
bash ./001_windows11-pipeline_en.sh

echo "Successfully ran all pipelines!"