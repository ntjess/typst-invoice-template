#import "template.typ": invoice-from-metadata


#let meta = yaml("metadata.yaml")
#meta.doc-info.insert("logo", image("logo.svg", height: 5em))
#invoice-from-metadata(meta, pre-table-body: [], apply-default-style: true)