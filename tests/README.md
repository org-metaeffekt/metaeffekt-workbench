# Tests

This directory contains integration tests for the metaeffekt Workbench. The tests demonstrate how [metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum) 
processors can be used within a workspace to build flexible and complex processing pipelines.

## Pipelines

The pipelines in this directory are typically centered around a product such as MongoDB or OpenSSL. A pipeline usually 
starts with an input inventory, then enriches and transforms the data, and finally generates report documentation for 
licensing and vulnerability analysis.

The [`sample-product-pipeline`](./scripts/pipelines/sample-product-pipeline_en.sh) provides a detailed example covering 
all report types as well as a dashboard. It can serve as a blueprint for creating new pipelines.

## Resources

The resources directory contains the workspaces and processing stages of each pipeline with their respective outputs.