# Ruby GCMD library
A set of classes for working with NASA's [Global Change Master Directory (GCMD)](http://gcmd.gsfc.nasa.gov/), in
particular the [Directory Interchange Format](http://gcmd.nasa.gov/User/difguide/).

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/npolar/gcmd)

## Features
* DIF XML parsing (to Ruby Hash)
* DIF XML writing (from Ruby Hash)
* Bullet- and futureproof XML handling by direct use of DIF's XML Schema
* Integration with GCMD's new KMS (Keyword Management System) service

## HTTP services

### Keyword Management System
* Gcmd::Concepts

### HTTP client
* Gcmd::Http

## Requirements
* Ruby >= 1.9.3

## About
All https://github.com/npolar code is maintained by staff at the [Data Centre](http://data.npolar.no/) of the [Norwegian Polar Institute](http://npolar.no/).

### Credits

Keywords and DIF schema's are created and maintained by [NASA's GCMD team](http://gcmd.nasa.gov/Resources/valids/)

### Links

* [About GCMD](http://gcmd.nasa.gov/Aboutus/index.html)
* [What is a DIF?](http://gcmd.nasa.gov/User/difguide/whatisadif.html)
* [DIF XML Schema](http://gcmd.nasa.gov/Aboutus/xml/dif/dif.xsd)
* [DIF XML Template](http://gcmd.nasa.gov/Aboutus/xml/dif/DIF_XML_Template.xml)
