# Util - Merge and Filter

This process merges inventories based on an individual security advisor and filters them by CERT-FR.

## Properties

The different properties are sorted into three different groups which are explained in the top level [README](../../README.md)
of this repository.

### Input / Output
| Parameter                       | Required | Description                                                                |
|---------------------------------|----------|----------------------------------------------------------------------------|
| input.reference.inventories.dir | yes      | The directory containing all inventories which will be merged and filtered |
| input.security.policy.file      | yes      | The security policy file needed to filter the inventory.                   |
| output.filtered.inventory.file  | yes      | The output inventory file                                                  |

### Parameters
| Parameter                            | Required | Description                                          |
|--------------------------------------|----------|------------------------------------------------------|
| param.vulnerability.advisory.filter  | yes      | The advisor by which to filter the input inventories |

### Environment
None