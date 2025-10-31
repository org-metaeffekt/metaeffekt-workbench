# Descriptors

This folder contains asset descriptors for document generation and inventory transformation.

The document section of an asset descriptor defines the structure and content of a document. The transformation section 
is used to apply different transformations on inventories and other data.

The provided descriptors are generic, meaning that they can be used without modifications for standard document types.
Each of the generic asset descriptor refer to a specific document type.

All information within the generic descriptors is parameterized through the template, only exception to this is the security policy configurations activeIds.
In order to apply different changes to the activeIds for a document, adapt the specified configuration within the security policy file.

If the provided generic asset descriptors do not cover a specific use-case, then a custom descriptor may be created for addressing such a case.

