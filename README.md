# {metaeffekt} Workbench

The metaeffekt workbench repository contains a sample workbench illustrating the integration and use of the
[metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum). The repository is supposed to serve
as a reference and guide for custom workbench implementations. The workbench is part of a broader set of projects consisting
of the workbench itself, the [metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum) and the
metaeffekt-workspace. In conjunction these projects enable a user to utilize the entire suite of tools, plugins and content
provided by {metaeffekt}.

## Repository Structure

The metaeffekt workbench contains several directories that are concerned with essential functionality and data.
To learn more about the function and content of each directory please refer to the respective `README.md` files:

- [`correlations`](./correlations/README.md) - Correlation data used for downstream tasks like inventory processing.
- [`descriptors`](./descriptors/README.md) - Asset descriptors used as structural blueprints and execution plans for document generation.
- [`inventories`](./inventories/README.md) - Inventories used throughout the workbench as reference or as processing input.
- [`policies`](./policies/security-policy/security-policy.md) - Security policies used throughout the workbench.
- [`scripts`](./scripts/README.md) - Scripts used in product pipelines for processing and transforming inventories.
- [`templates`](./templates/README.md) - The template encapsulating the document generation process.
- [`tests`](./tests/README.md) - Several tests for entire product pipelines.

