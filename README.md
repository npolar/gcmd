# Ruby GCMD library
A set of classes for working with NASA's [Global Change Master Directory (GCMD)](http://gcmd.gsfc.nasa.gov/), in
particular the [Directory Interchange Format](http://gcmd.nasa.gov/User/difguide/), and [skos:Concept](http://www.w3.org/TR/skos-reference/#concepts)s from
GCMD's Keyword Management System.

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/npolar/gcmd)

## Features
* DIF XML parsing (to Ruby Hash)
* DIF XML writing (from Ruby Hash)
* Bullet- and futureproof XML handling by direct use of DIF's XML Schema
* HTTP client for GCMD's new KMS (Keyword Management System) service
* Keyword parser (from skos:Concept XML to Ruby Array)



## Credits

Code is developed by staff at the [Data Centre](http://data.npolar.no/) of the [Norwegian Polar Institute](http://npolar.no/).
Keywords and DIF schema's are created and maintained by [NASA's GCMD team](http://gcmd.nasa.gov/Resources/valids/)

### Links

* [About GCMD](http://gcmd.nasa.gov/Aboutus/index.html)
* [What is a DIF?](http://gcmd.nasa.gov/User/difguide/whatisadif.html)
* [DIF XML Schema](http://gcmd.nasa.gov/Aboutus/xml/dif/dif.xsd)
* [DIF XML Template](http://gcmd.nasa.gov/Aboutus/xml/dif/DIF_XML_Template.xml)
