# Asset Descriptors

This directory contains **asset descriptors** used for:

- **document generation**
- **inventory transformation**

An asset descriptor defines which inventories are used, which preprocessing steps are executed, and how documents are assembled from reusable parts.

The generic descriptors in this folder are intended for **standard document types** and can usually be used without modification. If a standard descriptor does not fit a specific use case, then a custom descriptor may be created for addressing such a case.

## Structure of a descriptor

An asset descriptor can contain up to three main sections:

- **`inventories`** — declares input and computed inventories
- **`transformations`** — defines preprocessing steps that merge or enrich inventory data
- **`documents`** — defines the documents to generate, including their parameters and parts

A typical processing flow is:

1. Declare input inventories.
2. Transform or enrich those inventories.
3. Generate one or more documents from the resulting data.

## Parameterization

Generic descriptors use **Maven-style placeholders** such as `${...}` that are resolved at runtime. These values may come from:

- the processor or build environment
- the document template
- parameters defined inside the descriptor

This parameterization makes the generic descriptors reusable across assets and report runs. The main exception is security policy activation: if you need different `activeIds`, update the referenced security policy configuration accordingly.

## Inventories

The `inventories` section declares all inventories used by the descriptor. Each inventory name must be **unique**. Inventories usually define either:

- a **`folder`** for source input data, or
- a **`file`** for a generated inventory,
- plus a **`type`**, such as `INPUT` or `COMPUTED`.

### Example

```yaml
inventories:
  - "inventory":
      folder: "${input.inventory.dir}"
      type: INPUT
  - merged-inventory:
      file: "${param.computed.inventory.dir}/${asset.name}-vulnerability-report-inventory.xlsx"
      type: COMPUTED
  - "cert-advisory-inventory":
      file: "${param.computed.inventory.dir}/${asset.name}-statistics-report-inventory.xlsx"
      type: COMPUTED
```

## Transformations

The `transformations` section defines preprocessing steps that run **before** document generation. Transformations are used to process inventory data with [metaeffekt-kontinuum](https://github.com/org-metaeffekt/metaeffekt-kontinuum) processors or custom scripts. Typical tasks include merging multiple inventory files and enriching them with additional report data.

Each Maven transformation should define:

- **`inputInventories`** — inventories consumed by the transformation
- **`outputInventories`** — inventories produced by the transformation
- **`params`** — parameters passed into the processor
- **`maven`** — the Maven descriptor and command used to execute the step

Every inventory listed in `inputInventories` or `outputInventories` must also be declared in the top-level `inventories` section. Input inventories should be declared as `INPUT`; generated results should be declared as `COMPUTED`.

### Example

```yaml
"merge-advisors":
  inputInventories:
    - "inventory"
  outputInventories:
    - "merged-inventory"
  params:
    input.inventory.dir: "${inventory.folder}"
    output.inventory.file: "${merged-inventory.file}"
    param.security.policy.file: "${security.policy.file}"
    param.security.policy.active.ids: "cert_extended_configuration"
  maven:
    pom: "${kontinuum.processors.dir}/util/util_merge-advisors.xml"
    workingDir: "."
    command: "generate-sources"
```

## Documents

The `documents` section defines the final output documents. Each document must have a **unique ID** and typically defines:

- a **type**
- a **language** (`en` or `de`)
- optional **document-level parameters**
- a set of **parts** that make up the output document

### Example

```yaml
documents:
  "cert-report":
    type: VULNERABILITY_REPORT
    language: "${document.language}"
    params:
      securityPolicyFile: "${security.policy.file}"
```

## Parameters

Parameters can be defined on both **document scope** and **part scope**.

Part-level parameters inherit document-level parameters and can override them locally. These parameters are also written to a `.properties` file and may be consumed by downstream Maven tasks or used by the document template for dynamic content references.

## Parts

Parts are the building blocks of a document. Each part must define:

- a **unique ID**
- a **type**
- one or more **inventories**
- optional **part-level parameters**

Each inventory entry inside a part references a declared inventory using `inventoryRef` and may additionally define:

- `assetName`
- `assetVersion`

### Example

```yaml
parts:
  "summary-report":
    type: VULNERABILITY_SUMMARY_PART
    params:
      securityPolicyActiveIds: "cert_extended_configuration"
      filterAdvisorySummary: "true"
    inventories:
      - inventoryRef: "cert-advisory-inventory"
        assetName: "${asset.name}"
        assetVersion: "${asset.version}"
```
