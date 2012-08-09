# Ruby GCMD library
A set of classes for working with NASA's [Global Change Master Directory (GCMD)](http://gcmd.gsfc.nasa.gov/).

## Functionality

This software library tries to tackle 4 major issues while working with GCMD.

* Generating hashses from DIF (XML) metadata documents.
* Creation of DIF (XML) from DIF formatted data hashes.
* Validation, information collection and template generation based on DIF's XML schema.
* Working with GCMD's online KMS (Keyword Management System) service.


## Directory Interchange Format (DIF)


### Generating DIF hashes

The [Gcmd::HashBuilder]() class enables you to generate hashes from a XML containing a single or
multiple DIF metadata records. The return format is always an Array containing the doucment Hashes
even if only one DIF record is provided!

``` ruby

  require "gcmd/hash_builder"
 
  builder = Gcmd::HashBuilder.new( dif_xml )
  result_array = builder.build_hash_documents
  
```

**NOTE!** _Even though the defaults are set to support DIF out of the box the converter is actually quite generic
and can be used to convert basically any xml document into Hashes. This will require some minor changes
in the code. Mainly resetting some presets to your needs._


### Generating DIF (XML) from DIF Hashes

The [Gcmd::DifBuilder]() class can be used to generate a DIF (XML) document from a DIF Hash. So in order
for this to work you need to make sure that the keys in your hash match the elements that occur in
DIF. The result is a String containing the XML.

``` ruby

  require "gcmd/dif_builder"
  
  builder = Gcmd::DifBuilder.new
  dif_xml = builder.build_dif( dif_hash )

```

The code snippet above is dependant on an XML schema to work. The reason for this is a feature to make
the XML schema valid and as complete as possible. By calling ```ruby #build_dif( dif_hash) ``` the
provided hash will first be synced with a template hash to make sure that the order of elements is in
accordance with the schema. Any missing elements will be added as empty elements. By default the schema
for the current version of DIF ***(v9.8.3)*** is loaded.

If you don't want syncing and completion to happen you can alternativly do the following:

``` ruby

  require "gcmd/dif_builder"
  
  builder = Gcmd::DifBuilder.new
  dif_xml = builder.build_xml( dif_hash )

```

This will generate an XML without any ordering or completion happening.

**NOTE!**  _The code for the conversions is fairly generic and could be easily adapted to convert
other hash data into xml._


## HTTP services

### Keyword Management System
* Gcmd::Concepts

### HTTP client
* Gcmd::Http

## Requirements
* Ruby >= 1.9.3

## About

### Credits

Keywords and DIF schema's are created and maintained by [NASA's GCMD team](http://gcmd.nasa.gov/Resources/valids/)

### Links

* [About GCMD](http://gcmd.nasa.gov/Aboutus/index.html)
* [What is a DIF?](http://gcmd.nasa.gov/User/difguide/whatisadif.html)
* [DIF XML Schema](http://gcmd.nasa.gov/Aboutus/xml/dif/dif.xsd)
* [DIF XML Template](http://gcmd.nasa.gov/Aboutus/xml/dif/DIF_XML_Template.xml)
