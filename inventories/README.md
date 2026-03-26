# Inventories

This directory contains inventories that are used either:

- as input for downstream processing steps, or
- as reference data for report generation.

## Required directory structure

Each inventory must be stored in its own directory and include the following subdirectories:

- **`inventory/`** — contains the inventory files (`.xls`, `.xlsx`, or `.ser`)
- **`components/`** — contains inventory-specific components, each in its own subdirectory, along with any additional contents such as license texts
- **`licenses/`** — contains license files for the inventory, with each license in its own subdirectory

## Example

```text
/inventories
└── /example-inventory
    ├── /inventory
    │   └── example-inventory.xls
    ├── /components
    │   └── /Apache-Commons-Codec-1.15
    │       └── license.txt
    └── /licenses
        └── /Apache-License-2.0
            └── license.txt
```

## Please note

Do not change this directory structure. Downstream tasks depend on it and may fail if files or folders are reorganized.
