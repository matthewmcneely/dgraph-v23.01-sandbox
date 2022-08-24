DGRAPH_VERSION = v21.03.2

current_dir = $(shell pwd)

# Start the zero and alpha containers
up:
	DGRAPH_VERSION=$(DGRAPH_VERSION) docker-compose up

# Stop the containers
stop:
	DGRAPH_VERSION=$(DGRAPH_VERSION) docker-compose stop

# Load/update the GraphQL schema
schema:
	curl -v  --data-binary '@./schema.graphql' --header 'content-type: application/octet-stream' http://localhost:8080/admin/schema

# Drops all data (but not the schema)
drop-data:
	curl -X POST localhost:8080/alter -d '{"drop_op": "DATA"}'

# Drops data and schema
drop-all:
	curl -X POST localhost:8080/alter -d '{"drop_all": true}'

# Loads data from the data.json file
load-data:
	docker run -it -v $(current_dir):/export dgraph/dgraph:$(DGRAPH_VERSION) dgraph live -a host.docker.internal:9080 -z host.docker.internal:5080 -f /export/data.json

# Runs the query present in query.dql
query-dql:
	@curl --data-binary '@./query.dql' -H "Content-Type: application/dql" -X POST localhost:8080/query

query-gql:
ifeq (, $(shell which gql))
	@echo "No gql in $(PATH), download from https://github.com/matthewmcneely/gql/tree/feature/add-query-and-variables-from-file/builds"
else
	@gql file --query-file query.graphql --variables-file variables.json --endpoint http://localhost:8080/graphql
endif

query-gql-auth:
ifeq (, $(shell which jwt))
	@echo "No jwt in $(PATH), download from https://github.com/mike-engel/jwt-cli"
else
	@echo "Encoding claims in jwt.json"
	$(eval CLAIMS := $(shell cat jwt.json))
	$(eval TOKEN := $(shell jwt encode --secret vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk= '$(CLAIMS)'))
	@echo "Issuing query with JWT token in header"
	@gql file --query-file query.graphql --endpoint http://localhost:8080/graphql --header X-myapp=$(TOKEN)
endif

