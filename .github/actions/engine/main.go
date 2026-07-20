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

	fmt.Println("🦫 Go Engine Active & Merging Matrix Artifacts ...")

	configData, err := os.ReadFile(archConfigFile)
	if err != nil {
		fmt.Printf("❌ Failed to read arch config : [%v]\n", err)
		os.Exit(1)
	}

	var archConfig ArchConfig
	if err := json.Unmarshal(configData, &archConfig); err != nil {
		fmt.Printf("❌ Failed to parse arch config : [%v]\n", err)
		os.Exit(1)
	}

	os.MkdirAll("release-assets", 0755)

	// Unzip all matrix outputs into their respective directories for manifest generation
	for _, arch := range archConfig.Architectures {
		destDir := fmt.Sprintf("%s/%s", outputDirectory, arch.Name)
		os.MkdirAll(destDir, 0755)

		matches, _ := filepath.Glob(fmt.Sprintf("merged-beta/DayPass_%s_*.zip", arch.Name))
		if len(matches) > 0 {
			zipFile := matches[0]
			fmt.Printf("📦 Extracting matrix artifact : [%s]\n", zipFile)
			
			r, err := zip.OpenReader(zipFile)
			if err != nil {
				fmt.Printf("❌ Error opening zip [%s] : [%v]\n", zipFile, err)
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
					fmt.Printf("❌ Error extracting file [%s] :[ %v]\n", f.Name, err)
				}
			}
			r.Close()
		}
	}

	fmt.Println("🧠 Processing & Generating Real Manifest Data ...")
	if err := GenerateManifest(archConfigFile, outputDirectory); err != nil {
		fmt.Printf("❌ Error generating manifest : [%v]\n", err)
		os.Exit(1)
	}

	// Generate SHA256 hashes for all zip packages
	zipMatches, _ := filepath.Glob("merged-beta/DayPass_*_*.zip")
	for _, zipFile := range zipMatches {
		func() {
			f, err := os.Open(zipFile)
			if err != nil {
				return
			}
			defer f.Close()
			h := sha256.New()
			io.Copy(h, f)
			fileSHA := fmt.Sprintf("%x", h.Sum(nil))
			shaFileName := filepath.Base(zipFile) + ".sha256"
			
			os.WriteFile("release-assets/"+shaFileName, []byte(fileSHA+"  "+filepath.Base(zipFile)+"\n"), 0644)
			
			copyFile(zipFile, "release-assets/"+filepath.Base(zipFile))
		}()
	}

	copyFile(filepath.Join(outputDirectory, "manifest.json"), "release-assets/manifest.json")

	if err := generateInstallScript("release-assets/install.sh"); err != nil {
		fmt.Printf("❌ Failed to compile install.sh : [%v]\n", err)
	}

	tagFormat := fmt.Sprintf("v%s-beta-%s", version, buildNum)

	var keyboard []InlineKeyboardButton
	for _, arch := range archConfig.Architectures {
		zipMatch, _ := filepath.Glob(fmt.Sprintf("merged-beta/DayPass_%s_*.zip", arch.Name))
		if len(zipMatch) > 0 {
			actualFileName := filepath.Base(zipMatch[0])
			btn := InlineKeyboardButton{
				Text: "🧪 " + arch.Name,
				URL:  fmt.Sprintf("https://github.com/%s/releases/download/%s/%s", repo, tagFormat, actualFileName),
			}
			keyboard = append(keyboard, btn)
		}
	}

	var inlineKeyboard [][]InlineKeyboardButton
	for _, btn := range keyboard {
		inlineKeyboard = append(inlineKeyboard, []InlineKeyboardButton{btn})
	}

	msgText := fmt.Sprintf(
		"📬 *New Beta DayPass Ready! *\n\n🏷️ *Version :* `%s`\n🛠️ *Build :* `%s`\n👤 *By :* `%s`\n\n🔬 *Installer :* `wget -O- %s/dev/install.sh | sh`",
		tagFormat, buildNum, actor, "https://chamroosh98.github.io/DayPass",
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