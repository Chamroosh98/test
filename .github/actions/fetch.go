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
	// استفاده از فلگ‌های سرسخت curl برای لود کردن ریدایرکت‌های فایل سورس‌فورج
	cmd := exec.Command("curl", "-sL", url, "-o", destPath)
	return cmd.Run()
}

func main() {
	if len(os.Args) < 3 {
		fmt.Println("❌ Usage: go run fetch.go <architecture> <release_version>")
		os.Exit(1)
	}
	targetArch := os.Args[1]
	releaseVersion := os.Args[2] // گرفتن ورژن (مثلاً v26.07.20) از ورودی

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
		fmt.Printf("📥 Fetching feeds for %s...\n", targetArch)

		for _, feed := range arch.Feeds {
			feedOutputDir := filepath.Join(baseDownloadDir, feed)
			os.MkdirAll(feedOutputDir, 0755)

			fullFeedURL := fmt.Sprintf("%s/%s", arch.BaseURL, feed)
			tempIndexPath := filepath.Join(feedOutputDir, "index.json")
			
			fmt.Printf("🌐 Fetching index: %s/index.json\n", fullFeedURL)
			if err := downloadWithCurl(fullFeedURL+"/index.json", tempIndexPath); err != nil {
				fmt.Printf("⚠️ Skipped feed %s\n", feed)
				continue
			}

			indexData, err := os.ReadFile(tempIndexPath)
			if err != nil {
				continue
			}

			var feedIdx FeedIndex
			if err := json.Unmarshal(indexData, &feedIdx); err != nil {
				fmt.Printf("⚠️ Formatting error on index %s: %v\n", feed, err)
				continue
			}

			for pkgName, pkgVersion := range feedIdx.Packages {
				apkFileName := fmt.Sprintf("%s_%s_%s.apk", pkgName, pkgVersion, feedIdx.Architecture)
				pkgPath := filepath.Join(feedOutputDir, apkFileName)
				
				pkgURL := fmt.Sprintf("%s/%s/download", fullFeedURL, apkFileName)
				
				fmt.Printf("  ⬇️ Downloading: %s\n", apkFileName)
				if err := downloadWithCurl(pkgURL, pkgPath); err != nil {
					fmt.Printf("  ❌ Download failed for: %s\n", apkFileName)
				}
			}
		}
	}

	if !found {
		fmt.Printf("❌ Architecture %s not found\n", targetArch)
		os.Exit(1)
	}

	zipName := fmt.Sprintf("DayPass_%s_%s_beta.zip", targetArch, releaseVersion)
	if err := zipDirectory(baseDownloadDir, zipName); err != nil {
		fmt.Printf("❌ Zipping failed : %v\n", err)
		os.Exit(1)
	}
	
	os.RemoveAll("matrix-download")
	fmt.Printf("✅ Package created successfully : %s\n", zipName)
}