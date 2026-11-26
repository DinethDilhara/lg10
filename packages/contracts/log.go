package contracts

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"fmt"
	"sync"

	"github.com/santhosh-tekuri/jsonschema/v6"
)

//go:embed v1/log.schema.json
var logSchema []byte
var once sync.Once
var schema *jsonschema.Schema
var schemaErr error

type Log struct {
	SchemaVersion string         `json:"schema_version"`
	EventID       string         `json:"event_id"`
	SourceID      string         `json:"source_id"`
	EventTime     string         `json:"event_time"`
	IngestedAt    string         `json:"ingested_at"`
	Host          string         `json:"host"`
	Service       string         `json:"service"`
	Severity      string         `json:"severity"`
	Message       string         `json:"message"`
	Attributes    map[string]any `json:"attributes,omitempty"`
}

// DecodeLog validates the original object, so unknown fields cannot disappear
// silently through decoding into a Go struct. Transport metadata is stripped by
// the indexer, not here. Format assertions are enabled explicitly.
func DecodeLog(data []byte) (Log, error) {
	once.Do(func() {
		var doc any
		if schemaErr = json.Unmarshal(logSchema, &doc); schemaErr != nil {
			return
		}
		c := jsonschema.NewCompiler()
		c.AssertFormat()
		if schemaErr = c.AddResource("log.json", doc); schemaErr != nil {
			return
		}
		schema, schemaErr = c.Compile("log.json")
	})
	var event Log
	if schemaErr != nil {
		return event, schemaErr
	}
	var value any
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.UseNumber()
	if err := dec.Decode(&value); err != nil {
		return event, err
	}
	if err := schema.Validate(value); err != nil {
		return event, fmt.Errorf("log contract: %w", err)
	}
	if err := json.Unmarshal(data, &event); err != nil {
		return event, err
	}
	return event, nil
}
