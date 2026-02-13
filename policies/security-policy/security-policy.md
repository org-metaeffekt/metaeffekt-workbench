# Security Policy Configuration

The [security policy](security-policy.json) contains the security policy configurations for the entire workbench.
Currently by default, none of them are active meaning that when a configuration is used within a processor it is required to also provide the Ids of the active configurations.

Configurations may extend other configuration or be defined as active by default, more about this can be read [here](https://github.com/org-metaeffekt/metaeffekt-documentation/blob/main/metaeffekt-vulnerability-management/inventory-enrichment/central-security-policy-loader.md).

The following table lists each configuration with their Id, what other configuration they extend, if they are active by default, a short description and their processor/report usage:

### Configurations

| Id                                  | Extends            | IsActiveByDefault | Description                                                                            | Usage                                      |
|-------------------------------------|--------------------|-------------------|----------------------------------------------------------------------------------------|--------------------------------------------|
| assessment_enrichment_configuration | none               | no                | The configuration for vulnerability assessment and enrichment.                         | Inventory Enrichment, Assessment Dashboard |
| base_configuration                  | none               | no                | The base configuration for reports.                                                    |                                            |
| vulnerability_configuration         | base_configuration | no                | The configuration for each part of the vulnerability report.                           | Vulnerability Report                       |
| cert_configuration                  | base_configuration | no                | The configuration for the statistics of the cert report.                               | Cert Report                                |
| cert_extended_configuration         | cert_configuration | no                | The configuration enrichment, vulnerability reporting and summary for the cert report. | Cert Report                                |
