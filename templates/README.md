# Templates

In this folder documentation templates are maintained. The templates contained in this directory represent a cut-down
selection of the templates found in our metaeffekt-workbench project as not all reference templates are needed here.
Depending on which report type was triggered, a fitting profile is selected which generates the relevant report sections into a single resulting pdf.


## Profiles

Listed below are the available profiles for document generation. **Each profile (e.g. "SDA") must be suffixed by a language (e.g. "SDA_en")**. 

| Profile | Document Type                 | Available Languages | Prerequisites                                          |                                                                        
|---------|-------------------------------|---------------------|--------------------------------------------------------|
| SDA     | Software Distribution Annex   | en, de              |                                                        | 
| LD      | License Documentation         | en, de              |                                                        | 
| ILD     | Initial License Documentation | en, de              |                                                        | 
| CAD     | Custom Annex Document         | en, de              |                                                        | 
| VR      | Vulnerability Report          | en, de              | security policy file                                   |
| VSR     | Vulnerability Summary Report  | en, de              | security policy file, exactly one entry in asset sheet |
| CR      | Cert Report                   | en, de              | security policy file                                   |

TODO
- describe core-parameters (TBC)
