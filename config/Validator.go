package config

import (
	"fmt"
	"github.com/xeipuuv/gojsonschema"
)

const RESOURCE_NAME_PATTERN string = `[a-zA-Z][a-zA-Z0-9_-]*`

type Validator struct {
	schemaLoader gojsonschema.JSONLoader
}

type ValidationResult interface {
	Valid() bool
	Errors() []gojsonschema.ResultError
}

func NewValidator() (*Validator) {
	validator := &Validator{}
	validator.schemaLoader = gojsonschema.NewStringLoader(configurationSchema)
	return validator
}

func (v *Validator) Validate(cfg *Configuration) (ValidationResult, error) {
	if cfg == nil {
		return nil, fmt.Errorf("The configuration object is nil")
	}
	if v.schemaLoader == nil {
		return nil, fmt.Errorf("Validator is not initialized properly")
	}
	documentLoader := gojsonschema.NewGoLoader(cfg)
	return gojsonschema.Validate(v.schemaLoader, documentLoader)
}

var configurationSchema string = `{
	"type": "object",
	"properties": {
		"version": {
			"type": "string",
			"pattern": "^[v]?(\\d+\\.)?(\\d+\\.)?(\\*|\\d+)$"
		},
		"main-resource": {
			"oneOf": [
				{
					"type": "null"
				},
				{
					"$ref": "#/definitions/CommandEntrypoint"
				}
			]
		},
		"resources": {
			"oneOf": [
				{
					"type": "null"
				},
				{
					"type": "object",
					"patternProperties": {
						"^` + RESOURCE_NAME_PATTERN + `$": {
							"$ref": "#/definitions/CommandEntrypoint"
						}
					},
					"additionalProperties": false
				}
			]
		},
		"settings": {
			"$ref": "#/definitions/Settings"
		},
		"settings-format": {
			"$ref": "#/definitions/SettingsFormat"
		}
	},
	"definitions": {
		"CommandEntrypoint": {
			"type": "object",
			"properties": {
				"default": {
					"$ref": "#/definitions/CommandDescriptor"
				},
				"methods": {
					"oneOf": [
						{
							"type": "null"
						},
						{
							"type": "object",
							"patternProperties": {
								"^(?i)(GET|POST|PUT|PATCH|DELETE)$": {
									"$ref": "#/definitions/CommandDescriptor"
								}
							},
							"additionalProperties": false
						}
					]
				}
			}
		},
		"CommandDescriptor": {
			"type": "object",
			"properties": {
				"command": {
					"type": "string"
				},
				"timeout": {
					"type": "integer",
					"minimum": 0
				}
			},
			"required": [ "command" ]
		},
		"Settings": {
			"oneOf": [
				{
					"type": "null"
				},
				{
					"type": "object"
				}
			]
		},
		"SettingsFormat": {
			"type": "string",
			"enum": [ "", "json", "flat" ]
		}
	}
}`