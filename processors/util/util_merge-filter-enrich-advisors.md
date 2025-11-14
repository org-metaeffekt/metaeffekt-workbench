# Util - Merge, Filter & enrich advisors

This process merges inventories based on an individual security advisor and enriches the output inventory based on 
the specified advisors. It is mainly used for cert report document generation.

## Properties

The different properties are sorted into three different groups.

### Input / Output
| Parameter                    | Required | Description                                     |
|------------------------------|----------|-------------------------------------------------|
| input.inventory.file         | yes      | The file of the input inventory for enrichment. |
| output.enrichment.inventory  | yes      | The output inventory of the enrichment process. |

### Parameters
| Parameter                           | Required | Description                                                               |
|-------------------------------------|----------|---------------------------------------------------------------------------|
| param.vulnerability.advisory.filter | yes      | The advisor by which to filter the input inventories.                     |
| param.filtered.inventory.file       | yes      | The file of the intermediate inventory which is then used for enrichment. |
| param.security.policy.file          | yes      | The security policy file needed to filter the inventory.                  |
| param.security.policy.active.ids    | no       | The activeIds of the security policy configuration.                       |

### Environment
| Parameter                           | Required | Description                                                               |
|-------------------------------------|----------|---------------------------------------------------------------------------|
| env.vulnerability.mirror.dir        | yes      | The location of the vulnerability database used for inventory enrichment. |
