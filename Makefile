OAPI := go run github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.8.0
VACUUM := go run github.com/daveshanley/vacuum@v0.18.5
OASDIFF := go run github.com/oasdiff/oasdiff@latest
TSGEN := npx --yes openapi-typescript@7

.PHONY: gen gen-go gen-ts lint breaking gen-check test

gen: gen-go gen-ts

gen-go:
	$(OAPI) -config openapi/common/v1/codegen.yaml openapi/common/v1/common.yaml
	$(OAPI) -config openapi/origination/v1/codegen.yaml openapi/origination/v1/origination.yaml
	$(OAPI) -config asyncapi/origination/v1/codegen.yaml asyncapi/origination/v1/schemas.yaml
	$(OAPI) -config openapi/scoring/v1/codegen.yaml openapi/scoring/v1/scoring.yaml
	$(OAPI) -config asyncapi/scoring/v1/codegen.yaml asyncapi/scoring/v1/schemas.yaml
	$(OAPI) -config openapi/pricing/v1/codegen.yaml openapi/pricing/v1/pricing.yaml
	$(OAPI) -config asyncapi/pricing/v1/codegen.yaml asyncapi/pricing/v1/schemas.yaml
	$(OAPI) -config openapi/servicing/v1/codegen.yaml openapi/servicing/v1/servicing.yaml
	$(OAPI) -config asyncapi/servicing/v1/codegen.yaml asyncapi/servicing/v1/schemas.yaml

gen-ts:
	$(TSGEN) openapi/common/v1/common.yaml -o gen/ts/common/v1.ts
	$(TSGEN) openapi/origination/v1/origination.yaml -o gen/ts/origination/v1.ts
	$(TSGEN) openapi/scoring/v1/scoring.yaml -o gen/ts/scoring/v1.ts
	$(TSGEN) openapi/pricing/v1/pricing.yaml -o gen/ts/pricing/v1.ts
	$(TSGEN) openapi/servicing/v1/servicing.yaml -o gen/ts/servicing/v1.ts

lint:
	$(VACUUM) lint -d -n error openapi/common/v1/common.yaml openapi/origination/v1/origination.yaml openapi/scoring/v1/scoring.yaml openapi/pricing/v1/pricing.yaml

breaking:
	$(OASDIFF) breaking origin/main:openapi/origination/v1/origination.yaml openapi/origination/v1/origination.yaml --fail-on ERR

gen-check: gen
	git diff --exit-code -- gen

test:
	go test -race ./...
