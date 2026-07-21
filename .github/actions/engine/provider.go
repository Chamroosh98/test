package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"time"
)

type SettingsConfig struct {
	Timeout int `json:"timeout"`
	Retry   int `json:"retry"`
}

func providerDownload(downloadURL, outputPath, proxy string) error {
	settingsFile := os.Getenv("DAYPASS_SETTINGS_FILE")
	if settingsFile == "" {
		settingsFile = "config/settings.json"
	}

	timeoutSec := 30
	retryCount := 3

	if data, err := os.ReadFile(settingsFile); err == nil {
		var config SettingsConfig
		if json.Unmarshal(data, &config) == nil {
			if config.Timeout > 0 {
				timeoutSec = config.Timeout
			}
			if config.Retry > 0 {
				retryCount = config.Retry
			}
		}
	}

	transport := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: false},
	}

	if proxy != "" {
		proxyURL, err := url.Parse(proxy)
		if err == nil {
			transport.Proxy = http.ProxyURL(proxyURL)
		}
	}

	client := &http.Client{
		Transport: transport,
		Timeout:   time.Duration(timeoutSec) * time.Second,
	}

	var resp *http.Response
    var err error

    for i := 0; i <= retryCount; i++ {
        resp, err = client.Get(downloadURL)
        if err == nil {
            if resp.StatusCode == http.StatusOK {
                break
            }
			
            resp.Body.Close()
            err = fmt.Errorf("bad status : %s", resp.Status)
        }
        if i < retryCount {
            fmt.Printf("⚠️ Retrying download (%d/%d) for : %s\n", i+1, retryCount, downloadURL)
            time.Sleep(2 * time.Second)
        }
    }

    if err != nil {
        return err
    }
    defer resp.Body.Close()


	os.MkdirAll(filepath.Dir(outputPath), 0755)
	out, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}

func providerDownloadIndex(feedURL, outputPath, proxy string) error {
	fullURL := fmt.Sprintf("%s/index.json", feedURL)
	return providerDownload(fullURL, outputPath, proxy)
}

func providerDownloadPackage(feedURL, packageName, outputPath, proxy string) error {
	fullURL := fmt.Sprintf("%s/%s", feedURL, packageName)
	return providerDownload(fullURL, outputPath, proxy)
}