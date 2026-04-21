package antigravity

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestCleanJSONSchema_ConvertsConstToEnum(t *testing.T) {
	schema := map[string]any{
		"type": "object",
		"properties": map[string]any{
			"kind": map[string]any{
				"const": "shell_command",
			},
			"nested": map[string]any{
				"type": "object",
				"properties": map[string]any{
					"mode": map[string]any{
						"const": "strict",
					},
				},
			},
		},
	}

	cleaned := CleanJSONSchema(schema)
	require.NotNil(t, cleaned)

	props, ok := cleaned["properties"].(map[string]any)
	require.True(t, ok)

	kind, ok := props["kind"].(map[string]any)
	require.True(t, ok)
	require.Equal(t, "string", kind["type"])
	require.Equal(t, []any{"shell_command"}, kind["enum"])
	_, hasConst := kind["const"]
	require.False(t, hasConst)

	nested, ok := props["nested"].(map[string]any)
	require.True(t, ok)
	nestedProps, ok := nested["properties"].(map[string]any)
	require.True(t, ok)
	mode, ok := nestedProps["mode"].(map[string]any)
	require.True(t, ok)
	require.Equal(t, "string", mode["type"])
	require.Equal(t, []any{"strict"}, mode["enum"])
	_, hasNestedConst := mode["const"]
	require.False(t, hasNestedConst)
}

func TestBuildTools_StripsConstFromFunctionParameters(t *testing.T) {
	tools := []ClaudeTool{
		{
			Name:        "run_command",
			Description: "Run a local command",
			InputSchema: map[string]any{
				"type": "object",
				"properties": map[string]any{
					"kind": map[string]any{
						"const": "shell_command",
					},
					"command": map[string]any{
						"type": "string",
					},
				},
				"required": []any{"kind", "command"},
			},
		},
	}

	result := buildTools(tools)
	require.Len(t, result, 1)
	require.Len(t, result[0].FunctionDeclarations, 1)

	params := result[0].FunctionDeclarations[0].Parameters
	props, ok := params["properties"].(map[string]any)
	require.True(t, ok)

	kind, ok := props["kind"].(map[string]any)
	require.True(t, ok)
	require.Equal(t, "string", kind["type"])
	require.Equal(t, []any{"shell_command"}, kind["enum"])
	_, hasConst := kind["const"]
	require.False(t, hasConst)
}
