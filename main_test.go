package main

import (
	"net/http"
	"testing"
)

func TestHomeHandler(t *testing.T) {
	r := New(Token)

	r.GET("/")
	res, _ := r.Run(Router())

	if status := res.Code; status != http.StatusOK {
		t.Errorf("Unexpected Code: Expected %v but got %v", http.StatusOK, status)
	}

	if body := res.Body.String(); body != "{\"status\":\"Hi API\"}" {
		t.Errorf("Unexpected Response: Expected `%s` but got `%s`", "Hi API", body)
	}
}

func TestTestHandler(t *testing.T) {
	r := New(Token)

	r.GET("/api/test")
	res, _ := r.Run(Router())

	if status := res.Code; status != http.StatusOK {
		t.Errorf("Unexpected Code: Expected %v but got %v", http.StatusOK, status)
	}

	if body := res.Body.String(); body != "{\"status\":\"Test API\"}" {
		t.Errorf("Unexpected Response: Expected `%s` but got `%s`", "Test API", body)
	}
}
