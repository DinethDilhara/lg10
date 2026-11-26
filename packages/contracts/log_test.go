package contracts

import (
	"encoding/json"
	"os"
	"testing"
)

func TestLogBoundary(t *testing.T) {
	b, err := os.ReadFile("examples/log.json")
	if err != nil {
		t.Fatal(err)
	}
	if _, err = DecodeLog(b); err != nil {
		t.Fatal(err)
	}
	var m map[string]any
	json.Unmarshal(b, &m)
	for _, date := range []string{"invalid", "2026-02-30T00:00:00Z", "2026-01-01T00:00:00+00:00"} {
		m["event_time"] = date
		b, _ = json.Marshal(m)
		if _, err = DecodeLog(b); err == nil {
			t.Fatal(date)
		}
	}
}
