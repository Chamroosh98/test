
package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	botToken := os.Getenv("INPUT_TELEGRAM_BOT_TOKEN")
	chatID := os.Getenv("INPUT_TELEGRAM_CHAT_ID")
	version := os.Getenv("INPUT_VERSION")
	runNumber := os.Getenv("INPUT_BUILD_NUMBER")

	fmt.Printf("🚀 Starting DayPass Deployer for Version: %s (Build: %s)\n", version, runNumber)

	cmd := exec.Command("sh", "-c", "echo 'Doing some merge logic here...'")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Println("❌ Error executing step:", err)
		os.Exit(1)
	}

	fmt.Printf("📢 Notification sent to chat ID %s using token length %d\n", chatID, len(botToken))
}