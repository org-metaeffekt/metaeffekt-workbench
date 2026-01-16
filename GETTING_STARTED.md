# Getting Started

Before proceeding, please review the top-level [README](README.md) to understand this repository's purpose and
intended use cases. It is also highly recommended to review the
[metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum) and its documentation for additional context.

## Prerequisites

The test infrastructure in this repository follows the same general structure outlined in the
[metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum). The main components required
to execute any processors are:

1. **Processor-specific scripts**: Correspond to individual processors and handle their execution,
   managing prerequisites beyond basic parameters and environment resources (such as the vulnerability mirror)
2. **Case scripts**: Define parameter sets for specific processors, providing necessary configuration
   parameters to processor-specific scripts while separating configuration from execution logic
3. **Pipeline scripts**: Execute multiple processor-specific scripts in predetermined sequences with their
   respective cases

Unlike the tests in [metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum), the pipelines
in this repository contain all necessary parameters and Maven calls for specific processors directly within the scripts
rather than in sub-scripts. This design aims to improve readability and simplifies customization.

Additionally, this repository requires a local instance of the [metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum).

To ensure all reference processes and pipelines in this repository can run, we need to create an external.rc file
in the root of this repository. A template for this file has been provided here: [external-template.rc](external-template.rc).

## Running the Reference Pipeline

To first get started it is recommended to execute one of the following reference pipelines. No adjustments to the actual
pipeline scripts should be necessary if the external.rc file has been set correctly.

- [001_sample-product-pipeline_de.sh](tests/scripts/pipelines/001_sample-product-pipeline_de.sh)
- [001_sample-product-pipeline_en.sh](tests/scripts/pipelines/001_sample-product-pipeline_en.sh)

## Running single Processors

**Note:** Scripts can be executed from any directory. All required resources for processor execution are included
in this repository. The only additional requirement is a local instance of our vulnerability mirror which should automatically
be downloaded when given the correct url in your external.rc file.

## Running with non-snapshot versions

The default versioning by all processes and scripts in this repository utilizes HEAD-SNAPSHOT versions of core and
artifact-analysis. To overwrite this and test the workbench scripts with release versions of core and artifact-analysis, change
the necessary parameter in your external.rc file and the following files:

- [workbench-parent.xml](processors/workbench-parent.xml)
- [pom.xml](templates/report-template/pom.xml)