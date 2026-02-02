# Vulnerability Assessments

This folder organizes different assessments for different subjects (assets) and assessment contexts.

When executing the advise enrichment processors the according assessment folder must be selected.

## Folder Structure

The folder structure in assessments is as follows:

* The first level is the `<tenant-id>` folder. It supports that assessments between different tenants are not shared.
* The second level is the asset level. The folder name is equivalent by the project-unique `<asset-id>`. If several 
  generations exist that only have few in common. The folder may include the major version or an equivalent extension
  `<asset-id\[-major-version\]>`.
* Within the asset folder several folders are contained:
  * A manually managed shared folder named `_generic-assessments_`; assessments in this folder apply to all assessment
    contexts.
  * Multiple context-specific assessment folders named after the `<assessment-context>`; these folder may be 
    automatically populated when using the Vulnerability Assessment Sashboard with a git-bound backend Vulnerability
    Assessment Service.

Since assessments are meant to be agnostic to an asset version, the asset version usually does not appear in the folder 
structure. Only in case a new generation is started the `<asset-id>` folder may include the major version of the asset,
as mentioned earlier.

The name of the assessment context may include several parts or aspects. This can either be an embedding into a 
product-tree, a mapping to a security zone or conduit, an exposure level or other deployment context. The assessment
context is determined by the project structure and simply passed through the system as discriminator or identifier for
the given assessment context.

## Vulnerability Assessment Service 

The Vulnerability Assessment Service can either be deployed centrally or on a local machine. In any case the associated
database is this git repository with the `assessments` directory.

## Additional Context Files

Context files can be supplied on various levels. You may include a '_context_' folder either in
* the `<tenant-id>` folders; applies to all assessments,
* the `<asset-id\[-major-version\]>` folders; applies to all assessments on the given asset, or
* the `<assessment-context-id>`; applies to a specific assessment context, only.

Deeper-nested context definitions overwrite less deeper-nested context definitions.

A basic set of definitions can be found in the `_context-pool_` folder.

Since context definition tend to be organization wide and less asset- or assessment-context-specific, it is recommended
to manage context definitions on `<tenant-id>` level and only deviate from this policy, when specifically required.

NOTE: The current context definitions overlap to a certain extent with the future Threat-Assessment approach. In this
case the definition will be revised and context definitions may be more dedicated to specific technical aspects than 
threat-related aspects.

# FIXMEs
The current implementation does not fully enable the outline above and input folders are individually configured. To
enable the above functions the following task have to be performed:

* implement missing features in plugins and processors with respect to multiple input folders for assessments and
  contexts; for the enrichment process the following inputs are required:
  * the assessments path (defaults to `assessments`)
  * the plain `<tenant-id>`,
  * the plain `<asset-id\[-major-version\]>`,
  * the plain `<assessment-context-id>`.
  all other paths can be derived from this.
  * validate context yamls and assessment files for not interfere or enable
    additional isolation of the folders
* remove assessment-001 folder and adjust existing pipelines
* adjust and test Vulnerability Assessment Service based on the new folder structure
  * it must be able to connect the service to the `assessments/<tenant-id>` folder in a
    first iteration. We may see in the future that the tenant-id needs to propagate through the
    inventories and potentially the dashboard.

