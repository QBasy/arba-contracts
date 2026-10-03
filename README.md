# contracts

Источник правды для API и событий Arba (`gitlab.arba.kz/arba/contracts`). Engines импортируют отсюда сгенерированные модели, клиенты и серверные интерфейсы.

```
openapi/common/v1/        общие схемы: Money, Problem (RFC 9457), пагинация, Idempotency-Key
openapi/origination/v1/   REST API заявок (OpenAPI 3.1)
asyncapi/origination/v1/  события (AsyncAPI 3 + схемы payload)
gen/go/                   Go: модели, клиент, сервер под Fiber v3
gen/ts/                   TypeScript-типы для фронтенда
```

Генерированный код в `gen/` коммитится; руками не правится. После изменения спеки:

```
make gen
make lint
make breaking   # oasdiff против origin/main
make test
```

Правила: версия в пути (`/v1`), только обратно совместимые изменения внутри версии, `Idempotency-Key` обязателен на изменяющих POST, суммы — `Money` (тиыны строкой), ошибки — `application/problem+json`.

Сервер в engine:

```go
originationv1.RegisterHandlers(srv.App(), handler)
```
