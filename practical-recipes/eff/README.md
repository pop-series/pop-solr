# eff

example of using ExternalFileField in solr cloud cluster. These fields are useful when a fload field for a large percentage of docs are required to be changed every X hours.  
ref: https://solr.apache.org/guide/solr/latest/indexing-guide/external-files-processes.html for further information.  

To run the example:
1. start the solr cloud cluster (ref: deploy/README.md)
2. once the cluster is up, invoke `practical-recipes/eff/scripts/control.sh install`. This will internally do the following:
   1. upload the `practical-recipes/eff/conf` to zookeeper
   2. create a collection `eff_recipe`
   3. generate sample test docs and external file field (popularity) mappings
   4. generate sample queries
   5. upload docs and external file field mappings to `eff_recipe` collection
   6. reload the collection for changes to take into effect

You may also refer this blog: https://medium.com/@parts.of.programming/practical-recipes-apache-solrcloud-external-file-field-a2d4091e36ce for a complete tutorial.
