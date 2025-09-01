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

Additionally this repository requires a local instance of the [metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum)
repository on branch 0.135.x.

## Running the Reference Pipeline

To get started with executing processors, edit the following pipeline scripts to point to your local
[metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum) repository:

- [`sample-product-pipeline_de.sh`](tests/scripts/pipelines/sample-product-pipeline_de.sh)
- [`sample-product-pipeline_en.sh`](tests/scripts/pipelines/sample-product-pipeline_en.sh)
- ```bash
  KONTINUUM_PROCESSORS_DIR="/PATH/TO/KONTINUUM-0.135.x"
  ```

### Running With a Local Vulnerability Mirror

Since the provided pipelines require a local vulnerability mirror instance, you must manually configure the mirror path:

1. Navigate to the [`tests/scripts/pipelines`](tests/scripts/pipelines) directory
2. Update the `ENV_VULNERABILITY_MIRROR_BASE_DIR` environment variable in both files:
    - [`sample-product-pipeline_de.sh`](tests/scripts/pipelines/sample-product-pipeline_de.sh)
    - [`sample-product-pipeline_en.sh`](tests/scripts/pipelines/sample-product-pipeline_en.sh)
3. Remove the following processor call section from both files:
    ```bash
    ###################################
    # Ensure mirror is up-to-date     #
    ###################################
    MIRROR_TARGET_DIR="$ENV_VULNERABILITY_MIRROR_BASE_DIR"
    # NOTE: on 0.135 we need to use the legacy mirror
    MIRROR_ARCHIVE_URL="http://ae-scanner/mirror/index/index-database_legacy.zip"
    MIRROR_ARCHIVE_NAME="index-database_legacy.zip"
    CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/util/util_update-mirror.xml" compile -P withoutProxy)
    CMD+=("-Doutput.vulnerability.mirror.dir=$MIRROR_TARGET_DIR")
    CMD+=("-Dparam.mirror.archive.url=$MIRROR_ARCHIVE_URL")
    CMD+=("-Dparam.mirror.archive.name=$MIRROR_ARCHIVE_NAME")
    echo "${CMD[@]}"
    "${CMD[@]}"
    ```
4. Run one of the pipelines

**Note:** Scripts can be executed from any directory. All required resources for processor execution are included
in this repository. The only additional requirement is a local instance of our vulnerability mirror
(a public version will be available in the future).