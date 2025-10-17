# Util - Merge and Filter

This process merges inventories based on an individual security advisor and filters them by CERT-FR.

## Properties

The different properties are sorted into three different groups. 

### Input / Output
| Parameter                       | Required | Description                                                                 |
|---------------------------------|----------|-----------------------------------------------------------------------------|
| input.reference.inventories.dir | yes      | The directory containing all inventories which will be merged and filtered. |
| output.filtered.inventory.file  | yes      | The output inventory file.                                                  |

### Parameters
| Parameter                           | Required | Description                                              |
|-------------------------------------|----------|----------------------------------------------------------|
| param.vulnerability.advisory.filter | yes      | The advisor by which to filter the input inventories.    |
| param.security.policy.file          | yes      | The security policy file needed to filter the inventory. |

### Environment
None