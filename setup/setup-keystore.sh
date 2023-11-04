# Exit on Error
set -e

GENERATED_KEYSTORE=/usr/share/elasticsearch/config/elasticsearch.keystore
OUTPUT_KEYSTORE=/secrets/keystore/elasticsearch.keystore

GENERATED_SERVICE_TOKENS=/usr/share/elasticsearch/config/service_tokens
OUTPUT_SERVICE_TOKENS=/secrets/service_tokens
OUTPUT_KIBANA_TOKEN=/secrets/.env.kibana.token
OUTPUT_FLEET_SERVER_TOKEN=/secrets/.env.fleet-server.token

# Password Generate
PW=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16 ;)
ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-$PW}"
export ELASTIC_PASSWORD

# Create Keystore
printf "========== Creating Elasticsearch Keystore ==========\n"
printf "=====================================================\n"
elasticsearch-keystore create >> /dev/null

# Setting Secrets and Bootstrap Password
sh /setup/keystore.sh
echo "Elastic Bootstrap Password is: $ELASTIC_PASSWORD"

###### Kibana
# Generating Kibana service token
echo "Generating Kibana service token..."

# Delete old token if exists
/usr/share/elasticsearch/bin/elasticsearch-service-tokens delete elastic/kibana default &> /dev/null || true

# Generate new token
KIBANA_TOKEN=$(/usr/share/elasticsearch/bin/elasticsearch-service-tokens create elastic/kibana default | cut -d '=' -f2 | tr -d ' ')
echo "KIBANA_SERVICE_ACCOUNT_TOKEN=$KIBANA_TOKEN" > $OUTPUT_KIBANA_TOKEN

###### Fleet Server
# Generating Fleet Server service token
echo "Generating Fleet Server service token..."

# Delete old token if exists
/usr/share/elasticsearch/bin/elasticsearch-service-tokens delete elastic/fleet-server default &> /dev/null || true

# Generate new token
FLEET_SERVER_TOKEN=$(/usr/share/elasticsearch/bin/elasticsearch-service-tokens create elastic/fleet-server default | cut -d '=' -f2 | tr -d ' ')
echo "FLEET_SERVER_SERVICE_ACCOUNT_TOKEN=$KIBANA_TOKEN" > $OUTPUT_FLEET_SERVER_TOKEN


# Replace current Keystore
if [ -f "$OUTPUT_KEYSTORE" ]; then
    echo "Remove old elasticsearch.keystore"
    rm $OUTPUT_KEYSTORE
fi

echo "Saving new elasticsearch.keystore"
mkdir -p "$(dirname $OUTPUT_KEYSTORE)"
mv $GENERATED_KEYSTORE $OUTPUT_KEYSTORE
chmod 0644 $OUTPUT_KEYSTORE

# Replace current Service Tokens File
if [ -f "$OUTPUT_SERVICE_TOKENS" ]; then
    echo "Remove old service_tokens file"
    rm $OUTPUT_SERVICE_TOKENS
fi

echo "Saving new service_tokens file"
mv $GENERATED_SERVICE_TOKENS $OUTPUT_SERVICE_TOKENS
chmod 0644 $OUTPUT_SERVICE_TOKENS

printf "======= Keystore setup completed successfully =======\n"
printf "=====================================================\n"
printf "Remember to restart the stack, or reload secure settings if changed settings are hot-reloadable.\n"
printf "About Reloading Settings: https://www.elastic.co/guide/en/elasticsearch/reference/current/secure-settings.html#reloadable-secure-settings\n"
printf "=====================================================\n"
printf "Your 'elastic' user password is: $ELASTIC_PASSWORD\n"
printf "Your Kibana service token is: $KIBANA_TOKEN\n"
printf "Your Fleet Server service token is: $FLEET_SERVER_TOKEN\n"
printf "=====================================================\n"
