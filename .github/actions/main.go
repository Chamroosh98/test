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

type InlineKeyboardButton struct {
	Text string `json:"text"`
	URL  string `json:"url"`
}

type InlineKeyboardMarkup struct {
	InlineKeyboard [][]InlineKeyboardButton `json:"inline_keyboard"`
}

type TelegramMessage struct {
	ChatID                string               `json:"chat_id"`
	Text                  string               `json:"text"`
	ParseMode             string               `json:"parse_mode"`
	ReplyMarkup           InlineKeyboardMarkup `json:"reply_markup"`
	DisableWebPagePreview bool                 `json:"disable_web_page_preview"`
}

func main() {
	botToken := os.Getenv("INPUT_TELEGRAM_BOT_TOKEN")
	chatID := os.Getenv("INPUT_TELEGRAM_CHAT_ID")
	version := os.Getenv("INPUT_VERSION")
	buildNum := os.Getenv("INPUT_BUILD_NUMBER")
	actor := os.Getenv("INPUT_ACTOR")
	repo := os.Getenv("GITHUB_REPOSITORY")

	fmt.Println("🚀 Pure Go Deployer Engine Active ...")

	archs := []string{
		"aarch64_cortex-a53", "aarch64_cortex-a72", "aarch64_cortex-a76",
		"aarch64_generic", "arm_cortex-a7_neon-vfpv4", "arm_cortex-a9_vfpv3-d16",
		"i386_pentium4", "mipsel_24kc", "x86_64",
	}

	for _, arch := range archs {
		destDir := fmt.Sprintf("merged-output/%s", arch)
		os.MkdirAll(destDir, 0755)

		matches, _ := filepath.Glob(fmt.Sprintf("merged-beta/DayPass_%s_*.zip", arch))
		if len(matches) > 0 {
			zipFile := matches[0]
			fmt.Printf("🤐 Unzipping via Go Archive : %s\n", zipFile)
			
			r, err := zip.OpenReader(zipFile)
			if err != nil {
				fmt.Printf("❌ Error opening zip : %v\n", err)
				continue
			}
			
			for _, f := range r.File {
				fpath := filepath.Join(destDir, f.Name)
				if f.FileInfo().IsDir() {
					os.MkdirAll(fpath, os.ModePerm)
					continue
				}
				os.MkdirAll(filepath.Dir(fpath), os.ModePerm)
				outFile, _ := os.OpenFile(fpath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
				rc, _ := f.Open()
				io.Copy(outFile, rc)
				outFile.Close()
				rc.Close()
			}
			r.Close()
		}
	}

	fmt.Println("🧠 Processing Manifest Data via encoding/json ...")
	manifestPath := "config/architectures.json"
	manifestData, err := os.ReadFile(manifestPath)
	if err != nil {
		fmt.Printf("❌ Base config not found : %v\n", err)
		os.Exit(1)
	}

	os.MkdirAll("merged-output", 0755)
	newManifestPath := "merged-output/final_manifest.json"
	os.WriteFile(newManifestPath, manifestData, 0644)

	os.MkdirAll("release-assets", 0755)
	for _, arch := range archs {
		matches, _ := filepath.Glob(fmt.Sprintf("merged-beta/DayPass_%s_*.zip", arch))
		if len(matches) > 0 {
			zipFile := matches[0]
			
			f, _ := os.Open(zipFile)
			h := sha256.New()
			io.Copy(h, f)
			fileSHA := fmt.Sprintf("%x", h.Sum(nil))
			f.Close()

			shaFileName := filepath.Base(zipFile) + ".sha256"
			os.WriteFile("release-assets/"+shaFileName, []byte(fileSHA+"  "+filepath.Base(zipFile)+"\n"), 0644)
			
			inputF, _ := os.Open(zipFile)
			outputF, _ := os.Create("release-assets/" + filepath.Base(zipFile))
			io.Copy(outputF, inputF)
			inputF.Close()
			outputF.Close()
		}
	}
	
	mInput, _ := os.Open(newManifestPath)
	mOutput, _ := os.Create("release-assets/manifest.json")
	io.Copy(mOutput, mInput)
	mInput.Close()
	mOutput.Close()

	fmt.Println("📬 Dispatched Telegram Message ...")
	var keyboard []InlineKeyboardButton
	for _, arch := range archs {
		btn := InlineKeyboardButton{
			Text: "🦫 " + arch,
			URL:  fmt.Sprintf("https://github.com/%s/releases/download/v%s-beta-%s/DayPass_%s_v%s-beta.zip", repo, version, buildNum, arch, version),
		}
		keyboard = append(keyboard, btn)
	}

	var inlineKeyboard [][]InlineKeyboardButton
	for _, btn := range keyboard {
		inlineKeyboard = append(inlineKeyboard, []InlineKeyboardButton{btn})
	}

	msgText := fmt.Sprintf(
		"🦫 *New Pure Go Build Ready!*\n\n🏷️ *Version :* `v%s-beta`\n🛠️ *Build :* `%s`\n👤 *By :* `%s`",
		version, buildNum, actor,
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
		fmt.Println("✅ Done!")
	}
}