//go:build ignore
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

func main() {
	// Login
	loginBody := []byte(`{"email":"admin@parkir.com","password":"admin123"}`)
	resp, err := http.Post("http://localhost:8080/api/login", "application/json", bytes.NewBuffer(loginBody))
	if err != nil {
		fmt.Println("Login error:", err)
		return
	}
	defer resp.Body.Close()
	
	var loginRes struct {
		Token string `json:"token"`
	}
	json.NewDecoder(resp.Body).Decode(&loginRes)
	
	if loginRes.Token == "" {
		fmt.Println("Login failed")
		return
	}

	// Fetch Pending Laporan
	req, _ := http.NewRequest("GET", "http://localhost:8080/api/admin/laporan/pending", nil)
	req.Header.Set("Authorization", "Bearer "+loginRes.Token)
	
	resp2, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Fetch error:", err)
		return
	}
	defer resp2.Body.Close()
	
	bodyBytes, _ := io.ReadAll(resp2.Body)
	fmt.Printf("Status: %d\nBody: %s\n", resp2.StatusCode, string(bodyBytes))
}
