### Notes for Developers 

Icon stock is from - http://www.famfamfam.com/lab/icons/silk/


### Installation

* Build the xar pakage according to the building section below, along with the dependencies mentioned below, and install all these xar-s in eXist.
* Modify "modules/config.template.xqm" according to your needs and save it as "modules/config.xqm".
* Modify "modules/configuration/services.xml" according to your needs. 
* Access tamboti at <http://localhost:8080/exist/apps/tamboti/>.


### Building with maven
N. B.  Maven 3.1.1+ is needed.
  
* For production instance of tamboti, use "clean package -Pgeneral-production-build".
* For test instance of tamboti, use "clean package -Pgeneral-test-build".
* For Cluster Asia and Europe... production instance of tamboti, use "clean package -Pcluster-production-build".  
* For Cluster Asia and Europe... test instance of tamboti, use "clean package -Pcluster-test-build".

### Dependencies
* eXist’s content extraction and image modules.
* eXist ImageMagick Plugin by ZwoBit https://github.com/zwobit/imagemagick.xq

### Tamboti REST APIs

#### Generate UUID-s
GET /apps/tamboti/api/uuid
Host: myserver

### Editors
#### HRA MODS editor
##### For existing resource:
GET /apps/tamboti/api/editors/hra-mods-editor/uuid-23b9dc11-ec19-4231-8323-6775688b2704 HTTP/1.1
Host: myserver
For new resource:
GET /apps/tamboti/api/editors/hra-mods-editor/uuid-23b9dc11-ec19-4231-8323-6775688b2704 HTTP/1.1
Host: myserver
X-target-collection: {target-collection}
X-document-type: {document-type}

curl -X POST -d "usr=usr&psw=psw" http://localhost:8088/client/restxq/deploy/123/real/true/bla

### Viewers
TBD.

### Users
#### Create an user
POST /users HTTP/1.1
Host: myserver
Content-Type: application/xml
<?xml version="1.0"?>
<user>
  <name>Robert</name>
</user>

#### Retrieve an user details
GET /users/Robert HTTP/1.1
Host: myserver
Accept: application/xml

#### Modify an user details
PUT /users/Robert HTTP/1.1
Host: myserver
Content-Type: application/xml
<?xml version="1.0"?>
<user>
  <name>Bob</name>
</user>

#### Delete an user
DELETE /users/Robert HTTP/1.1
Host: myserver
Content-Type: application/xml
<?xml version="1.0"?>
<user>
  <name>Bob</name>
</user>

### Collections
#### Create / rename a collection
TBD.

#### Delete a collection
TBD.

### Resources
#### Create / Update a resource
PUT /apps/tamboti/api/resources HTTP/1.1
Host: myserver
X-target-collection: {target-collection}
X-resource-id: {resource-id}

#### Delete a resource
DELETE /apps/tamboti/api/resources HTTP/1.1
Host: myserver
X-resource-path: {resource path}

DELETE /apps/tamboti/api/resources HTTP/1.1
Host: myserver
X-resource-id: {resource-id}

