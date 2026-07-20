package main

import (
	"archive/zip"
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}

func main() {
	workspace := os.Getenv("GITHUB_WORKSPACE")
	if workspace != "" {
		os.Chdir(workspace)
	}

	botToken := os.Getenv("INPUT_TELEGRAM_BOT_TOKEN")
	chatID := os.Getenv("INPUT_TELEGRAM_CHAT_ID")
	version := os.Getenv("INPUT_VERSION")
	buildNum := os.Getenv("INPUT_BUILD_NUMBER")
	actor := os.Getenv("INPUT_ACTOR")
	repo := os.Getenv("GITHUB_REPOSITORY")

	archConfigFile := os.Getenv("DAYPASS_ARCH_FILE")
	if archConfigFile == "" {
		archConfigFile = "config/architectures.json"
	}
	outputDirectory := os.Getenv("DAYPASS_OUTPUT_DIR")
	if outputDirectory == "" {
		outputDirectory = "merged-output"
	}

	fmt.Println("🦫 Go Engine Active & Modularized ...")

	archs := []string{
		"aarch64_cortex-a53", "aarch64_cortex-a72", "aarch64_cortex-a76",
		"aarch64_generic", "arm_cortex-a7_neon-vfpv4", "arm_cortex-a9_vfpv3-d16",
		"i386_pentium4", "mipsel_24kc", "x86_64",
	}

	isBeta := true
	githubWorkflow := os.Getenv("GITHUB_WORKFLOW")
	if strings.Contains(strings.ToLower(githubWorkflow), "production") || strings.Contains(strings.ToLower(githubWorkflow), "release") {
		isBeta = false
	}

	for _, arch := range archs {
		destDir := fmt.Sprintf("%s/%s", outputDirectory, arch)
		os.MkdirAll(destDir, 0755)

		matches, _ := filepath.Glob(fmt.Sprintf("merged-beta/DayPass_%s_*.zip", arch))
		if len(matches) > 0 {
			zipFile := matches[0]
			r, err := zip.OpenReader(zipFile)
			if err != nil {
				continue
			}

		for _, f := range r.File {
			fpath := filepath.Join(destDir, f.Name)
			if f.FileInfo().IsDir() {
				os.MkdirAll(fpath, os.ModePerm)
				continue
			}
			os.MkdirAll(filepath.Dir(fpath), os.ModePerm)

			err := func() error {
				outFile, err := os.OpenFile(fpath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
				if err != nil {
					return err
				}
				defer outFile.Close()
				rc, err := f.Open()
				if err != nil {
					return err
				}
				defer rc.Close()
				_, err = io.Copy(outFile, rc)
				return err
			}()
			if err != nil {
				fmt.Printf("⚠️ Error extracting file %s: %v\n", f.Name, err)
			}
		}
			
			r.Close()
		}
	}

	fmt.Println("🧠 Processing & Generating Real Manifest Data...")
	if err := GenerateManifest(archConfigFile, outputDirectory); err != nil {
		fmt.Printf("❌ Error generating manifest: %v\n", err)
		os.Exit(1)
	}

	os.MkdirAll("release-assets", 0755)
	for _, arch := range archs {
		matches, _ := filepath.Glob(fmt.Sprintf("merged-beta/DayPass_%s_*.zip", arch))
		if len(matches) > 0 {
			zipFile := matches[0]
			func() {
				f, _ := os.Open(zipFile)
				defer f.Close()
				h := sha256.New()
				io.Copy(h, f)
				fileSHA := fmt.Sprintf("%x", h.Sum(nil))
				shaFileName := filepath.Base(zipFile) + ".sha256"
				os.WriteFile("release-assets/"+shaFileName, []byte(fileSHA+"  "+filepath.Base(zipFile)+"\n"), 0644)
			}()
		}
	}

	copyFile(filepath.Join(outputDirectory, "manifest.json"), "release-assets/manifest.json")

	if err := generateInstallScript("release-assets/install.sh"); err != nil {
		fmt.Printf("❌ Failed to compile install.sh: %v\n", err)
	}

	var tagFormat string
	if isBeta {
		tagFormat = fmt.Sprintf("v%s-beta-%s", version, buildNum)
	} else {
		tagFormat = fmt.Sprintf("v%s-%s", version, buildNum)
	}

	var keyboard []InlineKeyboardButton
	for _, arch := range archs {
		matches, _ := filepath.Glob(fmt.Sprintf("merged-beta/DayPass_%s_*.zip", arch))
		if len(matches) > 0 {
			actualFileName := filepath.Base(matches[0])
			btn := InlineKeyboardButton{
				Text: "🧪 " + arch,
				URL:  fmt.Sprintf("https://github.com/%s/releases/download/%s/%s", repo, tagFormat, actualFileName),
			}
			keyboard = append(keyboard, btn)
		}
	}

	var inlineKeyboard [][]InlineKeyboardButton
	for _, btn := range keyboard {
		inlineKeyboard = append(inlineKeyboard, []InlineKeyboardButton{btn})
	}

	buildType := "Beta Development"
	if !isBeta {
		buildType = "Stable Production"
	}

	msgText := fmt.Sprintf(
		"🦫 *New DayPass Build Ready (%s)*\n\n🏷️ *Version :* `%s`\n🛠️ *Build :* `%s`\n👤 *By :* `%s`\n🌐 *Installer:* `wget -O- %s/dev/install.sh | sh`",
		buildType, tagFormat, buildNum, actor, "https://chamroosh98.github.io/DayPass",
	)

	payload := TelegramMessage{
		ChatID:                chatID,
		Text:                  msgText,
		ParseMode:             "Markdown",
		ReplyMarkup:           InlineKeyboardMarkup{InlineKeyboard: inlineKeyboard},
		DisableWebPagePreview: true,
	}

	jsonPayload, _ := json.Marshal(payload)
	apiURL := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", botToken)
	req, _ := http.NewRequest("POST", apiURL, bytes.NewBuffer(jsonPayload))
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err == nil && resp.StatusCode == http.StatusOK {
		fmt.Println("✅ Dynamic notification sent successfully!")
	}
}