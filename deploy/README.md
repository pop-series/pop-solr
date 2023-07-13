# deploy:

project for automating spinning-up a new solr cluster for ease of local development, esp. along with other pop-series projects.

## cluster setup:
1. invoke `./gradlew deploy:build`. This will aggregate any custom plugin libraries which are part of this project to `deploy/build/libs` which will need to be mounted to `pop-solr` container.
2. cd deploy/
3. start: `docker-compose up -d`
4. stop: `docker-compose down`

other alternatives:
starting solr natively (ref: https://solr.apache.org/guide/solr/latest/deployment-guide/installing-solr.html)
