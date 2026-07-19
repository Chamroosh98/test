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
		if err := os.Chdir(workspace); err != nil {
			fmt.Printf("❌ Failed to change working directory to workspace : %v\n", err)
		} else {
			fmt.Printf("🏠 Working directory changed to : %s\n", workspace)
		}
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

	fmt.Println("🦫 Go Engine Active ...")

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

	fmt.Println("🧠 Processing & Generating Real Manifest Data via Go module ...")
	os.MkdirAll(outputDirectory, 0755)
	if err := GenerateManifest(archConfigFile, outputDirectory); err != nil {
		fmt.Printf("❌ Error generating manifest: %v\n", err)
		os.Exit(1)
	}

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
		}
	}
	
	copyFile(filepath.Join(outputDirectory, "manifest.json"), "release-assets/manifest.json")

	if _, err := os.Stat("merged-beta/install.sh"); err == nil {
		fmt.Println("📝 Copying install.sh to release-assets for GitHub Pages ...")
		copyFile("merged-beta/install.sh", "release-assets/install.sh")
	}

	fmt.Println("📬 Dispatched Telegram Message ...")
	
	var tagFormat, fileSuffix string
	if isBeta {
		tagFormat = fmt.Sprintf("v%s-beta-%s", version, buildNum)
		fileSuffix = "-beta.zip"
	} else {
		tagFormat = fmt.Sprintf("v%s-%s", version, buildNum)
		fileSuffix = ".zip"
	}

	var keyboard []InlineKeyboardButton
	for _, arch := range archs {
		btn := InlineKeyboardButton{
			Text: "🦫 " + arch,
			URL:  fmt.Sprintf("https://github.com/%s/releases/download/%s/DayPass_%s_v%s%s", repo, tagFormat, arch, version, fileSuffix),
		}
		keyboard = append(keyboard, btn)
	}

	var inlineKeyboard [][]InlineKeyboardButton
	for _, btn := range keyboard {
		inlineKeyboard = append(inlineKeyboard, []InlineKeyboardButton{btn})
	}

	buildType := "Stable Production"
	if isBeta {
		buildType = "Beta Development"
	}

	msgText := fmt.Sprintf(
		"🦫 *New DayPass Build Ready (%s)*\n\n🏷️ *Version :* `%s`\n🛠️ *Build :* `%s`\n👤 *By :* `%s`",
		buildType, tagFormat, buildNum, actor,
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
		fmt.Println("✅ Telegram notification sent successfully!")
	}
}