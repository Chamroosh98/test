package main

import (
	"archive/zip"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
)

type ArchConfig struct {
	Release       string `json:"release"`
	Architectures []struct {
		Name    string   `json:"name"`
		BaseURL string   `json:"base_url"`
		Feeds   []string `json:"feeds"`
	} `json:"architectures"`
}

type FeedIndex struct {
	Version      int               `json:"version"`
	Architecture string            `json:"architecture"`
	Packages     map[string]string `json:"packages"`
}

func zipDirectory(sourceDir, targetZip string) error {
	zipFile, err := os.Create(targetZip)
	if err != nil {
		return err
	}
	defer zipFile.Close()

	archive := zip.NewWriter(zipFile)
	defer archive.Close()

	return filepath.Walk(sourceDir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}
		relPath, err := filepath.Rel(sourceDir, path)
		if err != nil {
			return err
		}
		file, err := os.Open(path)
		if err != nil {
			return err
		}
		defer file.Close()

		writer, err := archive.Create(relPath)
		if err != nil {
			return err
		}
		_, err = io.Copy(writer, file)
		return err
	})
}

func downloadWithCurl(url, destPath string) error {
	cmd := exec.Command("curl", "-sL", url, "-o", destPath)
	return cmd.Run()
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("❌ Architecture name argument is required")
		os.Exit(1)
	}
	targetArch := os.Args[1]

	configData, err := os.ReadFile("config/architectures.json")
	if err != nil {
		fmt.Printf("❌ Failed to read arch config: %v\n", err)
		os.Exit(1)
	}

	var archConfig ArchConfig
	if err := json.Unmarshal(configData, &archConfig); err != nil {
		fmt.Printf("❌ Failed to parse json: %v\n", err)
		os.Exit(1)
	}

	baseDownloadDir := fmt.Sprintf("matrix-download/%s", targetArch)
	os.MkdirAll(baseDownloadDir, 0755)

	found := false
	for _, arch := range archConfig.Architectures {
		if arch.Name != targetArch {
			continue
		}
		found = true
		fmt.Printf("📥 Fetching feeds for architecture: %s\n", targetArch)

		for _, feed := range arch.Feeds {
			feedOutputDir := filepath.Join(baseDownloadDir, feed)
			os.MkdirAll(feedOutputDir, 0755)

			fullFeedURL := fmt.Sprintf("%s/%s", arch.BaseURL, feed)
			tempIndexPath := filepath.Join(feedOutputDir, "index.json")
			
			fmt.Printf("🌐 Fetching index: %s/index.json\n", fullFeedURL)
			if err := downloadWithCurl(fullFeedURL+"/index.json", tempIndexPath); err != nil {
				fmt.Printf("⚠️ Skipped feed %s due to download error\n", feed)
				continue
			}

			indexData, err := os.ReadFile(tempIndexPath)
			if err != nil {
				continue
			}

			if len(indexData) > 0 && indexData[0] == '<' {
				fmt.Printf("❌ Error: Received HTML for feed %s. Route blocked.\n", feed)
				continue
			}

			var feedIdx FeedIndex
			if err := json.Unmarshal(indexData, &feedIdx); err != nil {
				fmt.Printf("⚠️ Formatting error on feed index %s: %v\n", feed, err)
				continue
			}

			for pkgName, pkgVersion := range feedIdx.Packages {
				apkFileName := fmt.Sprintf("%s_%s_%s.apk", pkgName, pkgVersion, targetArch)
				pkgPath := filepath.Join(feedOutputDir, apkFileName)
				
				fmt.Printf("  ⬇️ Downloading [%s]: %s\n", feed, apkFileName)
				pkgURL := fmt.Sprintf("%s/%s", fullFeedURL, apkFileName)
				if err := downloadWithCurl(pkgURL, pkgPath); err != nil {
					fmt.Printf("  ❌ Download failed for: %s\n", apkFileName)
				}
			}

			// os.Remove(tempIndexPath)
		}
	}

	if !found {
		fmt.Printf("❌ Architecture %s not found in json config\n", targetArch)
		os.Exit(1)
	}

	zipName := fmt.Sprintf("DayPass_%s_%s_beta.zip", targetArch, archConfig.Release)
	if err := zipDirectory(baseDownloadDir, zipName); err != nil {
		fmt.Printf("❌ Zipping failed: %v\n", err)
		os.Exit(1)
	}
	
	os.RemoveAll("matrix-download")
	
	fmt.Printf("✅ Package created successfully: %s\n", zipName)
}