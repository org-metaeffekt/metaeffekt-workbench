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

Additionally, this repository requires a local instance of the [metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum)
repository on branch 0.135.x.

## Prerequisites

To ensure all reference processes and pipelines in this repository can run, we need to create an external.rc file
in the root of this repository. A template for this file has been provided here: [external-template.rc](external-template.rc).

- EXTERNAL_KONTINUUM_DIR="/PATH/TO/KONTINUUM" 
  - Point this to the absolute path of a [metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum) instance on branch 0.135.x
- EXTERNAL_VULNERABILITY_MIRROR_DIR="/PATH/TO/MIRROR"
  - Point this to an instance of a vulnerability mirror. If you are not sure what this means, or you don't have a local instance of
  the mirror, point this to the metaeffekt-kontinuum/.mirror instead.
- EXTERNAL_VULNERABILITY_MIRROR_URL="https://mirror-url/mirror.tar.gz"
    - Point this to a valid URL where an instance of the mirror can be downloaded.
- EXTERNAL_VULNERABILITY_MIRROR_NAME="mirror.tar.gz"
    - The name of the mirror archive file

## Running the Reference Pipeline

To first get started it is recommended to execute one of the following reference pipelines. No adjustments to the actual
pipeline scripts should be necessary if the external.rc file has been set correctly.

- [`sample-product-pipeline_de.sh`](tests/scripts/pipelines/sample-product-pipeline_de.sh)
- [`sample-product-pipeline_en.sh`](tests/scripts/pipelines/sample-product-pipeline_en.sh)

## Running single Processors

**Note:** Scripts can be executed from any directory. All required resources for processor execution are included
in this repository. The only additional requirement is a local instance of our vulnerability mirror
(a public version will be available in the future).