package contracts_test

import (
	"context"
	"net"
	"net/http"
	"testing"
	"time"
	"uuid"

	"github.com/gofiber/fiber/v3"

	v1 "gitlab.arba.kz/arba/contracts/gen/go/origination/v1"
)

type stub struct {
	v1.ServerInterface
	key string
}

func (s *stub) CreateApplication(c fiber.Ctx, p v1.CreateApplicationParams) error {
	s.key = p.IdempotencyKey
	return c.Status(http.StatusCreated).JSON(v1.Application{
		Id:        uuid.New(),
		Status:    v1.StatusDraft,
		Version:   1,
		Consents:  []v1.Consent{},
		Documents: []v1.Document{},
		CreatedAt: time.Unix(0, 0).UTC(),
		UpdatedAt: time.Unix(0, 0).UTC(),
	})
}

func TestClientServerRoundTrip(t *testing.T) {
	s := &stub{}
	app := fiber.New()
	v1.RegisterHandlers(app, s)

	ln, err := (&net.ListenConfig{}).Listen(t.Context(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	go func() { _ = app.Listener(ln, fiber.ListenConfig{DisableStartupMessage: true}) }()
	t.Cleanup(func() { _ = app.Shutdown() })

	cl, err := v1.NewClientWithResponses("http://" + ln.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(t.Context(), 5*time.Second)
	defer cancel()

	var resp *v1.CreateApplicationResponse
	for range 50 {
		resp, err = cl.CreateApplicationWithResponse(ctx, &v1.CreateApplicationParams{IdempotencyKey: "key-12345678"})
		if err == nil {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	if err != nil {
		t.Fatal(err)
	}
	if resp.StatusCode() != http.StatusCreated || resp.JSON201 == nil || resp.JSON201.Status != v1.StatusDraft {
		t.Fatalf("unexpected response: %d %s", resp.StatusCode(), resp.Body)
	}
	if s.key != "key-12345678" {
		t.Fatalf("idempotency key not passed: %q", s.key)
	}
}
