package helpers

import (
	"strings"
	"unicode/utf8"
)

// EscapeString escapes special characters in a string for use in SurrealDB queries
func EscapeString(s string) string {
	// Ensure the string is valid UTF-8
	if !utf8.ValidString(s) {
		s = strings.ToValidUTF8(s, "")
	}
	
	// Replace ' with \' to escape single quotes in SQL strings
	s = strings.ReplaceAll(s, "'", "\\'")
	
	return s
}

// FormatCategoryIdsArray formats a slice of category IDs into a SurrealDB array string
func FormatCategoryIdsArray(categoryIds []string) string {
	if len(categoryIds) == 0 {
		return "[]"
	}
	
	escapedCategoryIds := make([]string, len(categoryIds))
	for i, id := range categoryIds {
		escapedCategoryIds[i] = EscapeString(id)
	}
	
	return "[" + strings.Join(escapedCategoryIds, ", ") + "]"
}

// SafeCategoryIds ensures we always have a valid categoryIds slice
func SafeCategoryIds(categoryIds []string) []string {
	if categoryIds == nil {
		return []string{}
	}
	return categoryIds
} 