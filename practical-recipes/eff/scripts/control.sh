#!/bin/bash


# determine main script directory
PRG="$0"
while [ -h "$PRG" ] ; do
  ls=$(ls -ld "$PRG")
  link=$(expr "$ls" : '.*-> \(.*\)$')
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=$(dirname "$PRG")"/$link"
  fi
done
SAVED="$(pwd)"
cd "$(dirname "$PRG")" >/dev/null
export SCRIPT_DIR="$(pwd -P)"
cd "$SAVED" >/dev/null


. "${SCRIPT_DIR}/../../../deploy/common/scripts/utils.sh"


setup() {
  set_env_var_if_missing "TARGET_CONTAINER" "pop-solr"
  set_env_var_if_missing "TARGET_ZK" "localhost:9983"
  set_env_var_if_missing "TARGET_CONF_NAME" "eff_conf"
  set_env_var_if_missing "TARGET_COLLECTION_NAME" "eff_recipe"
  set_env_var_if_missing "TARGET_SOLR_PORT" "8983"
  set_env_var_if_missing "TARGET_SOLR" "localhost:${TARGET_SOLR_PORT}"
  set_env_var_if_missing "TARGET_DATA_DIR" "/var/solr/data/eff_recipe_shard1_replica_n1/data"
}

prepare_cluster() (
  set_env_var_if_missing "LOCAL_CONF_DIR" "${SCRIPT_DIR}/../conf"
  set_env_var_if_missing "TARGET_TMP_CONF_DIR" "/tmp/${TARGET_CONF_NAME}"

  upload_configs() {
    log "uploading configs"
    docker exec -uroot ${TARGET_CONTAINER} rm -rf ${TARGET_TMP_CONF_DIR}
    docker cp ${LOCAL_CONF_DIR} ${TARGET_CONTAINER}:${TARGET_TMP_CONF_DIR}
    docker exec -usolr ${TARGET_CONTAINER} /opt/solr-9.2.1/server/scripts/cloud-scripts/zkcli.sh -z ${TARGET_ZK} -cmd upconfig -confdir ${TARGET_TMP_CONF_DIR} -confname ${TARGET_CONF_NAME}
  }

  create_collection() {
    log "creating collection"
    docker exec -usolr ${TARGET_CONTAINER} solr create -c ${TARGET_COLLECTION_NAME} -n ${TARGET_CONF_NAME} -shards 1 -replicationFactor 1 -p ${TARGET_SOLR_PORT}
  }

  ARGS="${@}"
  if [[ -z "${ARGS}" ]]; then
    log "preparing cluster"
    upload_configs
    create_collection
  else
    ${@}
  fi
)

ingest() (
  set_env_var_if_missing "LOCAL_RECORDS_DIR" "${SCRIPT_DIR}/../generated"
  set_env_var_if_missing "RECORDS_FILE_NAME" "eff_recipe_records.csv"
  set_env_var_if_missing "RECORDS_FILE" "${LOCAL_RECORDS_DIR}/${RECORDS_FILE_NAME}"
  set_env_var_if_missing "POPULARITY_FILE_NAME" "external_popularity.csv"
  set_env_var_if_missing "POPULARITY_FILE" "${LOCAL_RECORDS_DIR}/${POPULARITY_FILE_NAME}"
  set_env_var_if_missing "QUERIES_FILE" "${LOCAL_RECORDS_DIR}/queries.csv"
  mkdir -p ${LOCAL_RECORDS_DIR}

  generate_data() {
    log "generating data"
    python3 ${SCRIPT_DIR}/data_generator.py --records_file="${RECORDS_FILE}" --num_records=100000 --popularity_file="${POPULARITY_FILE}"
  }

  generate_query() {
    log "generating query"
    python3 ${SCRIPT_DIR}/query_generator.py --queries_file="${QUERIES_FILE}" --num_queries=1000 --infiltrate_percent=5 --records_file="${RECORDS_FILE}"
  }

  upload_eff() {
    log "uploading eff"
    docker cp ${POPULARITY_FILE} ${TARGET_CONTAINER}:${TARGET_DATA_DIR}/${POPULARITY_FILE_NAME}
  }

  upload_docs() {
    log "uploading docs"
    set_env_var_if_missing "TARGET_RECORDS_FILE" "/tmp/${RECORDS_FILE_NAME}"
    docker cp ${RECORDS_FILE} ${TARGET_CONTAINER}:${TARGET_RECORDS_FILE}
    docker exec -usolr ${TARGET_CONTAINER} post -c ${TARGET_COLLECTION_NAME} ${TARGET_RECORDS_FILE}
  }

  reload_collection() {
    log "reloading collection"
    curl -i "${TARGET_SOLR}/solr/admin/collections?action=RELOAD&name=${TARGET_COLLECTION_NAME}&wt=json"
  }

  ARGS="${@}"
  if [[ -z "${ARGS}" ]]; then
    log "ingesting"
    generate_data
    generate_query
    upload_eff
    upload_docs
    reload_collection
  else
    ${@}
  fi
)

clean() (
  docs() {
    log "removing docs"
    curl -i "${TARGET_SOLR}/solr/${TARGET_COLLECTION_NAME}/update?commitWithin=1" -H "Content-type: text/xml" --data-binary "<delete><query>*:*</query></delete>"
  }

  collection() {
    log "removing collection"
    curl -i "${TARGET_SOLR}/solr/admin/collections?action=DELETE&name=${TARGET_COLLECTION_NAME}&wt=json"
  }

  ARGS="${@}"
  if [[ -z "${ARGS}" ]]; then
    log "cleaning"
    collection
  else
    ${@}
  fi
)

install() {
  log "setting up a fresh cluster"
  prepare_cluster
  ingest
}

setup

# usage ./control.sh <function-name> <sub-function-name> to execute the relevant function
# e.g.
${@}
