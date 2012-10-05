# Ruby GCMD library
A set of classes for working with NASA's [Global Change Master Directory (GCMD)](http://gcmd.gsfc.nasa.gov/), in
particular the [Directory Interchange Format](http://gcmd.nasa.gov/User/difguide/).

## Features
* DIF XML parsing (to Ruby Hash)
* DIF XML writing (from Ruby Hash)
* Bullet- and futureproof XML handling by direct use of DIF's XML Schema
* Integration with GCMD's new KMS (Keyword Management System) service

## Directory Interchange Format (DIF)

### Parsing DIF XML

The [Gcmd::HashBuilder](https://github.com/npolar/gcmd/blob/master/lib/gcmd/hash_builder.rb) class enables you to generate hashes from a XML containing a single or
multiple DIF metadata records.

``` ruby

  require "gcmd/hash_builder"
 
  builder = Gcmd::HashBuilder.new( dif_xml )
  result_array = builder.build_hash_documents
  
```

**NOTE!** _Even though the defaults are set to support DIF out of the box the converter is actually quite generic
and can be used to convert basically any xml document into Hashes. This will require some minor changes
in the code. Mainly resetting some presets to your needs._


### Writing DIF XML

The [Gcmd::DifBuilder](https://github.com/npolar/gcmd/blob/master/lib/gcmd/dif_builder.rb) class can be used to generate a DIF (XML) document from a DIF Hash. So in order
for this to work you need to make sure that the keys in your hash match the elements that occur in
DIF. The result is a String containing the XML.

``` ruby

  require "gcmd/dif_builder"
  
  builder = Gcmd::DifBuilder.new( dif_hash )
  dif_xml = builder.build_dif

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

### Validating DIF XML

The [Gcmd::Schema](https://github.com/npolar/gcmd/blob/master/lib/gcmd/schema.rb) class offers the
posibility to validate DIF through the `#validate_xml` method. This works for both single DIF documents
as for multiple documents in a container like OAI-PMH. The method returns an array of hashes containing
validation information for each DIF.

``` ruby

  require "gcmd/schema"
  
  schema = Gcmd::Schema.new
  report = schema.validate_xml( xml_data )
  report.to_json

```

**NOTE!** _In the example above the schema class is initialized with the default xml schema
***(DIF v9.8.3)***. In order to validate against a different version of DIF do the following
`schema = Gcmd::Schema.new( "schema.xsd" )`._


## HTTP services

### Keyword Management System
* Gcmd::Concepts

### HTTP client
* Gcmd::Http

## Requirements
* Ruby >= 1.9.3

## About
This library is developed by the Datacenter staff at the Norwegian Polar Institute(http://npolar.no/).

### Credits

Keywords and DIF schema's are created and maintained by [NASA's GCMD team](http://gcmd.nasa.gov/Resources/valids/)

### Links

* [About GCMD](http://gcmd.nasa.gov/Aboutus/index.html)
* [What is a DIF?](http://gcmd.nasa.gov/User/difguide/whatisadif.html)
* [DIF XML Schema](http://gcmd.nasa.gov/Aboutus/xml/dif/dif.xsd)
* [DIF XML Template](http://gcmd.nasa.gov/Aboutus/xml/dif/DIF_XML_Template.xml)
