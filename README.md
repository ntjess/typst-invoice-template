# Invoice Template for Typst

![](sample-use.gif)

Generates a minimalist invoice from provided company, customer and charges data. One nice upside of this template vs manually configuring an invoice is that totals are automatically calculated, reducing the chance of human error.

All required information can be changed in the sample [metadata.yaml](metadata.yaml) file, and the MWE [main.typ](main.typ) file shows its usage. If you prefer toml or json, these are fine too -- just be sure to change the reader function in your main file.

## Features
### Locale:
Simply change the default `locale` options in your metadata, or update the respective template states before rendering.

### Billing options:
- Any metadata key ending in "charges" (case insensitive) will be rendered as shown in the example.
- If multiple "charges" are present, a heading is added to each table to distinguish them.

### Custom styling
Pass `use-default-style: false` to the invoice function to prevent the default font, paper size, and link styling.

Replace `logo.svg` with your own logo to change the default, or comment it out in `template.typ` to remove it entirely.
  - When typst allows checking for file existence, the logo will be removed automatically if it is not present.

## Roadmap
Feedback from the community is welcome! No additional features are currently planned other than bugfixes.